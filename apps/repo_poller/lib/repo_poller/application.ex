defmodule RepoPoller.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias RepoPoller.PollerSupervisor
  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {PollerSupervisor, []}
      # Starts a worker by calling: RepoPoller.Worker.start_link(arg)
      # {RepoPoller.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RepoPoller.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
