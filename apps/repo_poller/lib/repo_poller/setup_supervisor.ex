defmodule RepoPoller.SetupSupervisor do
  use Supervisor

  alias RepoPoller.{PollerSupervisor, SetupWorker, SetupQueueWorker, Config}

  def start_link(args \\ []) do
    name = Keyword.get(args, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, [], name: name)
  end

  def init(_) do
    children = [
      {PollerSupervisor, []},
      {SetupWorker, []}
    ]

    children =
      case Config.get_rabbitmq_config() do
        [] -> children
        _ -> [{SetupQueueWorker, []} | children]
      end

    opts = [strategy: :rest_for_one]
    Supervisor.init(children, opts)
  end
end
