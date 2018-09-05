use Mix.Config

# Runtime configs

config :repo_jobs, :rabbitmq_config,
  channels: 10,
  queue: System.get_env("QUEUE_NAME"),
  exchange: ""

config :repo_jobs, :consumers, 10
