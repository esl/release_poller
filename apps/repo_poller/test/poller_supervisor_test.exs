defmodule RepoPoller.PollerSupervisorTest do
  use ExUnit.Case, async: false
  import Mock

  alias RepoPoller.{PollerSupervisor, Poller, Config}
  alias Domain.Tasks.Runners.DockerBuild
  alias RepoPoller.Repository.GithubFake
  alias Domain.Repos.Repo
  alias Domain.Tasks.Task

  @tag capture_log: true
  test "setups a supervision tree with repo" do
    task = Task.new(runner: DockerBuild, build_file_content: "This is a test file\n")

    repo =
      "https://github.com/404/elixir"
      |> Repo.new(3_600_000, GithubFake)
      |> Repo.set_tasks([task])

    get_connection_pool_id_fn = fn -> :random_id end

    with_mocks [
      {Config, [], [get_connection_pool_id: get_connection_pool_id_fn]}
    ] do
      start_supervised!({PollerSupervisor, name: :PollerSupervisorTest})
      assert {:ok, child_pid} = PollerSupervisor.start_child(repo)

      assert %{
               repo: %{
                 url: "https://github.com/404/elixir",
                 owner: "404",
                 name: "elixir",
                 tasks: [task]
               }
             } = Poller.state(child_pid)

      assert %{build_file_content: "This is a test file\n", runner: DockerBuild} = task
    end
  end

  @tag capture_log: true
  test "setups a supervision tree with map" do
    repo = %{
      repository_url: "https://github.com/404/erlang",
      polling_interval: 3600,
      adapter: GithubFake
    }

    get_connection_pool_id_fn = fn -> :random_id end

    with_mocks [
      {Config, [], [get_connection_pool_id: get_connection_pool_id_fn]}
    ] do
      start_supervised!({PollerSupervisor, name: :PollerSupervisorTest})
      assert {:ok, child_pid} = PollerSupervisor.start_child(repo)

      assert %{
               repo: %{
                 url: "https://github.com/404/erlang",
                 owner: "404",
                 name: "erlang",
                 tasks: []
               }
             } = Poller.state(child_pid)
    end
  end
end
