defmodule RepoPoller.PollerSupervisor do
  use Supervisor

  alias RepoPoller.Poller
  alias Domain.Repos.Repo
  alias Domain.Tasks.Task
  alias RepoPoller.{DB, Config}

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
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
            tasks = tasks |> Enum.map(&Task.new(&1))

            repo =
              Repo.new(url)
              |> Repo.set_tasks(tasks)

            Supervisor.child_spec({Poller, {repo, adapter, pool_id, interval * 1000}},
              id: "poller_#{repo.name}"
            )
          end
      end

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
