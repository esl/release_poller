defmodule BugsBunny.PoolSupervisor do
  use Supervisor

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(config) do
    rabbitmq_config = Keyword.fetch!(config, :rabbitmq_config)
    rabbitmq_conn_pool = Keyword.fetch!(config, :rabbitmq_conn_pool)
    pool_id = Keyword.fetch!(rabbitmq_conn_pool, :pool_id)

    children = [:poolboy.child_spec(pool_id, rabbitmq_conn_pool, rabbitmq_config)]

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
