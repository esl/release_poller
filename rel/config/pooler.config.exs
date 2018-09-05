use Mix.Config

# Runtime configs

config :repo_poller, :rabbitmq_config,
  channels: 10,
  queue: System.get_env("QUEUE_NAME"),
  exchange: ""

config :repo_poller, :repos, [
  {"https://github.com/elixir-lang/elixir", RepoPoller.Repository.Github, 60,
   [
     [
       url: "https://github.com/sescobb27/elixir-docker-guide",
       commands: ["docker-push"],
       env: [
         {"DOCKER_USERNAME", System.get_env("DOCKER_USERNAME")},
         {"DOCKER_PASSWORD", System.get_env("DOCKER_PASSWORD")}
       ]
     ]
   ]}
]
