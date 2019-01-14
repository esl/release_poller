defmodule RepoPoller.SetupQueueWorker do
  use GenServer, restart: :temporary

  alias RepoPoller.Config

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def init(_) do
    pool_id = Config.get_connection_pool_id()
    client = Config.get_rabbitmq_client()
    queue = Config.get_rabbitmq_queue()
    exchange = Config.get_rabbitmq_exchange()

    :ok =
      BugsBunny.create_queue_with_bind(client, pool_id, queue, exchange, :direct,
        queue_options: [durable: true],
        exchange_options: [durable: true]
      )

    {:ok, :ignore}
  end
end
