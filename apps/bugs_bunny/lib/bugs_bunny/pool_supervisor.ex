defmodule BugsBunny.PoolSupervisor do
  use Supervisor

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(config) do
    children =
      case Keyword.get(config, :rabbitmq_conn_pool) do
        [] ->
          []

        rabbitmq_conn_pool ->
          rabbitmq_config = Keyword.get(config, :rabbitmq_config, [])
          pool_id = Keyword.fetch!(rabbitmq_conn_pool, :pool_id)

          children = [:poolboy.child_spec(pool_id, rabbitmq_conn_pool, rabbitmq_config)]
      end

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
