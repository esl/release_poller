defmodule RepoPoller.PollerSupervisor do
  use Supervisor

  alias RepoPoller.Poller
  alias RepoPoller.Domain.Repo

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    repos = Application.get_env(:repo_poller, :repos, [])

    children =
      for {url, adapter, interval} <- repos do
        repo = Repo.new(url)
        Supervisor.child_spec({Poller, {repo, adapter, interval * 1000}}, id: "poller_#{repo.name}")
      end

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
