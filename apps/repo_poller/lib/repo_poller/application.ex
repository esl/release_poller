defmodule RepoPoller.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias RepoPoller.PollerSupervisor

  def start(_type, _args) do
    # List all child processes to be supervised
    rabbitmq_config = Application.get_env(:repo_poller, :rabbitmq_config, [])
    rabbitmq_conn_pool = Application.get_env(:repo_poller, :rabbitmq_conn_pool, [])

    children = [
      {BugsBunny.PoolSupervisor,
       [rabbitmq_config: rabbitmq_config, rabbitmq_conn_pool: rabbitmq_conn_pool]},
      {PollerSupervisor, []},
      # Starts a worker by calling: RepoPoller.Worker.start_link(arg)
      # {RepoPoller.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: RepoPoller.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
