use Mix.Config

# Example
# config :repo_poller, :repos, [
#   {"https://github.com/erlang/otp", RepoPoller.Repository.Github, 60,
#    [
#      [url: "https://github.com/DeadZen/goldrush", commands: ["all"]],
#      [url: "https://github.com/emqtt/emqttd", commands: ["app", "rel"]]
#      [url: "https://github.com/sescobb27/elixir-docker-guide", commands: ["docker-push"]]
#    ]}
# ]

# config :repo_poller, :rabbitmq_config,
#   channels: 10,
#   queue: "new_releases.queue",
#   exchange: ""

# config :repo_poller, :rabbitmq_conn_pool,
#   pool_id: :connection_pool,
#   name: {:local, :connection_pool},
#   worker_module: BugsBunny.Worker.RabbitConnection,
#   size: 2,
#   max_overflow: 0
