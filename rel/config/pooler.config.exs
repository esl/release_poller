use Mix.Config

# Runtime configs

config :repo_poller, :rabbitmq_config,
  channels: 10,
  queue: System.get_env("QUEUE_NAME"),
  exchange: ""
