defmodule RepoPoller.PollerSupervisor do
  use Supervisor

  alias RepoPoller.Poller
  alias Domain.Repos.Repo
  alias Domain.Tasks.Task
  alias RepoPoller.{DB, Config}

  def start_link(args \\ []) do
    name = Keyword.get(args, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, [], name: name)
  end

  def init(_) do
    # let the DB be managed by the supervisor so it won't be restarted unless the supervisor is restarted too
    DB.new()

    children =
      Config.get_repos()
      |> case do
        # don't start any child and don't ask for pool configs (for testing only)
        [] ->
          []

        repos ->
          pool_id = Config.get_connection_pool_id()

          for {url, adapter, interval, tasks} <- repos do
            repo = setup_repo(url, tasks)

            Supervisor.child_spec({Poller, {repo, adapter, pool_id, interval * 1000}},
              id: "poller_#{repo.name}"
            )
          end
      end

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end

  @spec setup_repo(String.t(), keyword()) :: Repo.t()
  defp setup_repo(url, tasks_attrs) do
    tasks = Enum.map(tasks_attrs, &setup_task/1)

    Repo.new(url)
    |> Repo.set_tasks(tasks)
  end

  @spec setup_task(keyword()) :: Task.t()
  defp setup_task(task_attr) do
    {_, new_attrs} =
      Keyword.get_and_update(task_attr, :build_file, fn
        nil ->
          :pop

        build_file_path ->
          expanded_path = Path.join([Config.priv_dir(), build_file_path])
          {build_file_path, expanded_path}
      end)

    Task.new(new_attrs)
  end
end
