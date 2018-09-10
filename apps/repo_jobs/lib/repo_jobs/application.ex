defmodule RepoJobs.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias RepoJobs.ConsumerSupervisor

  def start(_type, _args) do
    # List all child processes to be supervised
    rabbitmq_config = Application.get_env(:repo_jobs, :rabbitmq_config, [])
    rabbitmq_conn_pool = Application.get_env(:repo_jobs, :rabbitmq_conn_pool, [])

    children = [
      {BugsBunny.PoolSupervisor,
       [rabbitmq_config: rabbitmq_config, rabbitmq_conn_pool: rabbitmq_conn_pool]},
      {ConsumerSupervisor, []}
    ]

    # if for some reason the Supervisor of the RabbitMQ connection pool is terminated we should
    # restart the Consumer workers because we can't consume messages from RabbitMQ without any
    # connection
    opts = [strategy: :rest_for_one, name: RepoJobs.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
