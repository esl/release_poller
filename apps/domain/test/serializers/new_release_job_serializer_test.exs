defmodule Domain.Serializers.NewReleaseJobSerializer.Test do
  use ExUnit.Case, async: true

  alias Domain.Serializers.NewReleaseJobSerializer, as: JobSerializer
  alias Domain.Jobs.NewReleaseJob
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
  alias Domain.Tasks.Task
  alias Domain.Tasks.Sources.Github
  alias Domain.Tasks.Runners.Make

  setup do
    repo = Repo.new("https://github.com/elixir-lang/elixir")

    tag = %Tag{
      commit: %{
        sha: "2b338092b6da5cd5101072dfdd627cfbb49e4736",
        url:
          "https://api.github.com/repos/elixir-lang/elixir/commits/2b338092b6da5cd5101072dfdd627cfbb49e4736"
      },
      name: "v1.7.2",
      node_id: "MDM6UmVmMTIzNDcxNDp2MS43LjI=",
      tarball_url: "https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.2",
      zipball_url: "https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.2"
    }

    {:ok, repo: repo, tag: tag}
  end

  test "serializes a new release job", %{repo: repo, tag: tag} do
    job = NewReleaseJob.new(repo, tag)

    assert JobSerializer.serialize!(job) ==
             "{\"repo\":{\"tasks\":[],\"owner\":\"elixir-lang\",\"name\":\"elixir\"},\"new_tag\":{\"zipball_url\":\"https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.2\",\"tarball_url\":\"https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.2\",\"node_id\":\"MDM6UmVmMTIzNDcxNDp2MS43LjI=\",\"name\":\"v1.7.2\",\"commit\":{\"url\":\"https://api.github.com/repos/elixir-lang/elixir/commits/2b338092b6da5cd5101072dfdd627cfbb49e4736\",\"sha\":\"2b338092b6da5cd5101072dfdd627cfbb49e4736\"}}}"
  end

  test "serializes a new release job with tasks", %{repo: repo, tag: tag} do
    task = %Task{url: "https://github.com/f@k31/fake"}

    job =
      repo
      |> Repo.set_tasks([task])
      |> NewReleaseJob.new(tag)

    assert JobSerializer.serialize!(job) ==
             "{\"repo\":{\"tasks\":[{\"url\":\"https://github.com/f@k31/fake\",\"source\":\"Elixir.Domain.Tasks.Sources.Github\",\"runner\":\"Elixir.Domain.Tasks.Runners.Make\",\"path\":null,\"env\":[],\"commands\":[]}],\"owner\":\"elixir-lang\",\"name\":\"elixir\"},\"new_tag\":{\"zipball_url\":\"https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.2\",\"tarball_url\":\"https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.2\",\"node_id\":\"MDM6UmVmMTIzNDcxNDp2MS43LjI=\",\"name\":\"v1.7.2\",\"commit\":{\"url\":\"https://api.github.com/repos/elixir-lang/elixir/commits/2b338092b6da5cd5101072dfdd627cfbb49e4736\",\"sha\":\"2b338092b6da5cd5101072dfdd627cfbb49e4736\"}}}"
  end

  test "deserialize a new release job", %{repo: repo, tag: tag} do
    job = NewReleaseJob.new(repo, tag)

    decoded_job =
      JobSerializer.deserialize!(
        "{\"repo\":{\"owner\":\"elixir-lang\",\"name\":\"elixir\"},\"new_tag\": {\"zipball_url\":\"https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.2\",\"tarball_url\":\"https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.2\",\"node_id\":\"MDM6UmVmMTIzNDcxNDp2MS43LjI=\",\"name\":\"v1.7.2\",\"commit\":{\"url\":\"https://api.github.com/repos/elixir-lang/elixir/commits/2b338092b6da5cd5101072dfdd627cfbb49e4736\",\"sha\":\"2b338092b6da5cd5101072dfdd627cfbb49e4736\"}}}"
      )

    assert decoded_job == job
  end

  test "deserialize task env properly", %{repo: repo, tag: tag} do
    task = %Task{
      url: "https://github.com/f@k31/fake",
      env: [{"KEY1", "VALUE1"}, {"KEY2", "VALUE2"}]
    }

    job =
      repo
      |> Repo.set_tasks([task])
      |> NewReleaseJob.new(tag)

    new_job =
      JobSerializer.serialize!(job)
      |> JobSerializer.deserialize!()

    assert new_job == job
    %{repo: %{tasks: [new_task]}} = new_job
    assert new_task.env == task.env
  end

  # converts stringified modules into modules again
  test "deserialize properly a task module adapters", %{repo: repo, tag: tag} do
    task = %Task{url: "https://github.com/f@k31/fake"}

    job =
      repo
      |> Repo.set_tasks([task])
      |> NewReleaseJob.new(tag)

    new_job =
      JobSerializer.serialize!(job)
      |> JobSerializer.deserialize!()

    assert new_job == job
    %{repo: %{tasks: [new_task]}} = new_job
    assert new_task.runner == Make
    assert new_task.source == Github
  end
end
