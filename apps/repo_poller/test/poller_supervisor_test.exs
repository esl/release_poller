defmodule RepoPoller.PollerSupervisorTest do
  use ExUnit.Case
  import Mock

  alias RepoPoller.{PollerSupervisor, Poller, DB, Config}
  alias Domain.Tasks.Runners.DockerBuild
  alias RepoPoller.Repository.GithubFake

  test "setups a supervision tree" do
    get_repos_fn = fn ->
      [
        {"https://github.com/new-tag/elixir", GithubFake, 3600,
         [
           [
             runner: DockerBuild,
             build_file: "build_files/dockerbuild_test"
           ]
         ]}
      ]
    end

    priv_dir_fn = fn ->
      Path.join([System.cwd!(), "test", "fixtures"])
    end

    get_connection_pool_id_fn = fn -> :random_id end

    new_fn = fn -> :ok end

    with_mocks [
      {Config, [],
       [
         get_repos: get_repos_fn,
         priv_dir: priv_dir_fn,
         get_connection_pool_id: get_connection_pool_id_fn
       ]},
      {DB, [], [new: new_fn]}
    ] do
      pid = start_supervised!({PollerSupervisor, name: :PollerSupervisorTest})
      assert [{"poller_elixir", child_pid, :worker, _modules}] = Supervisor.which_children(pid)
      assert %{repo: %{owner: "new-tag", name: "elixir", tasks: [task]}} = Poller.state(child_pid)
      assert %{build_file_content: "This is a test file\n", runner: DockerBuild} = task
    end
  end
end
