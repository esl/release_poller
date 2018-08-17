use Mix.Config

config :repo_poller, :repos, [
  # {"https://github.com/elixir-lang/elixir", RepoPoller.Repository.Github, 60},
  # {"https://github.com/inaka/erlang-katana", RepoPoller.Repository.Github, 60},
  # {"https://github.com/inaka/erlang_guidelines", RepoPoller.Repository.Github, 60}
]

config :repo_poller, :rabbitmq_config,
  host: "192.168.1.10",
  port: 5672,
  channels: 10,
  queue: "new_releases.queue",
  exchange: ""

config :repo_poller, :rabbitmq_conn_pool,
  pool_id: :connection_pool,
  name: {:local, :connection_pool},
  worker_module: BugsBunny.Worker.RabbitConnection,
  size: 2,
  max_overflow: 0
