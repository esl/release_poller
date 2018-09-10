defmodule BugsBunny.PoolSupervisor do
  use Supervisor

  @type config :: [rabbitmq_config: keyword(), rabbitmq_conn_pool: keyword()]

  @spec start_link(config()) :: Supervisor.on_start()
  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @spec start_link(config(), atom()) :: Supervisor.on_start()
  def start_link(config, name) do
    Supervisor.start_link(__MODULE__, config, name: name)
  end

  @impl true
  def init(config) do
    children =
      case Keyword.get(config, :rabbitmq_conn_pool) do
        [] ->
          []

        rabbitmq_conn_pool ->
          rabbitmq_config = Keyword.get(config, :rabbitmq_config, [])
          pool_id = Keyword.fetch!(rabbitmq_conn_pool, :pool_id)

          [:poolboy.child_spec(pool_id, rabbitmq_conn_pool, rabbitmq_config)]
      end

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end
end
