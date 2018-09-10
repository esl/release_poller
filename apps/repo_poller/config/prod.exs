use Mix.Config

config :logger, level: :info

config :repo_poller, :rabbitmq_conn_pool,
  pool_id: :connection_pool,
  name: {:local, :connection_pool},
  worker_module: BugsBunny.Worker.RabbitConnection,
  size: 5,
  max_overflow: 0
