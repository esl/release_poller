use Mix.Config

config :logger, level: :warn
config :repo_poller, github_client: RepoPoller.Repository.GithubFake
