defmodule Domain.Serializers.NewReleaseJobSerializer.Test do
  use ExUnit.Case, async: true

  alias Domain.Serializers.NewReleaseJobSerializer, as: JobSerializer
  alias Domain.Jobs.NewReleaseJob
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag

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

    {:ok, repo: repo, tags: [tag]}
  end

  test "serializes a new release job", %{repo: repo, tags: tags} do
    job = NewReleaseJob.new(repo, tags)

    assert JobSerializer.serialize!(job) ==
             "{\"repo\":{\"tasks\":[],\"owner\":\"elixir-lang\",\"name\":\"elixir\"},\"new_tags\":[{\"zipball_url\":\"https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.2\",\"tarball_url\":\"https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.2\",\"node_id\":\"MDM6UmVmMTIzNDcxNDp2MS43LjI=\",\"name\":\"v1.7.2\",\"commit\":{\"url\":\"https://api.github.com/repos/elixir-lang/elixir/commits/2b338092b6da5cd5101072dfdd627cfbb49e4736\",\"sha\":\"2b338092b6da5cd5101072dfdd627cfbb49e4736\"}}]}"
  end

  test "deserialize a new release job", %{repo: repo, tags: tags} do
    job = NewReleaseJob.new(repo, tags)

    decoded_job =
      JobSerializer.deserialize!(
        "{\"repo\":{\"owner\":\"elixir-lang\",\"name\":\"elixir\"},\"new_tags\":[{\"zipball_url\":\"https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.2\",\"tarball_url\":\"https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.2\",\"node_id\":\"MDM6UmVmMTIzNDcxNDp2MS43LjI=\",\"name\":\"v1.7.2\",\"commit\":{\"url\":\"https://api.github.com/repos/elixir-lang/elixir/commits/2b338092b6da5cd5101072dfdd627cfbb49e4736\",\"sha\":\"2b338092b6da5cd5101072dfdd627cfbb49e4736\"}}]}"
      )

    assert decoded_job == job
  end
end
