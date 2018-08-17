defmodule RepoPoller.PollerSupervisor do
  use Supervisor

  alias RepoPoller.Poller
  alias RepoPoller.Domain.Repo
  alias RepoPoller.DB

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    repos = Application.get_env(:repo_poller, :repos, [])
    pool_id =
      Application.get_env(:repo_poller, :rabbitmq_conn_pool, [])
      |> Keyword.fetch!(:pool_id)

    # let the DB be managed by the supervisor so it won't be restarted unless the supervisor is restarted too
    DB.new()

    children =
      for {url, adapter, interval} <- repos do
        repo = Repo.new(url)
        Supervisor.child_spec({Poller, {repo, adapter, pool_id, interval * 1000}}, id: "poller_#{repo.name}")
      end

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
