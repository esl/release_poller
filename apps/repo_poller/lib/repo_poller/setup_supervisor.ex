defmodule RepoPoller.SetupSupervisor do
  use Supervisor

  alias RepoPoller.{PollerSupervisor, SetupWorker, SetupQueueWorker}

  def start_link(args \\ []) do
    name = Keyword.get(args, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, [], name: name)
  end

  def init(_) do
    children = [
      {SetupQueueWorker, []},
      {PollerSupervisor, []},
      {SetupWorker, []}
    ]

    opts = [strategy: :rest_for_one]
    Supervisor.init(children, opts)
  end
end
