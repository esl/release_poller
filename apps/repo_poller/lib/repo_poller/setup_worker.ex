defmodule RepoPoller.SetupWorker do
  use GenServer

  alias RepoPoller.{PollerSupervisor, Config}

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def init(_) do
    send(self(), :after_init)
    {:ok, nil}
  end

  @impl true
  def handle_info(:after_init, state) do
    # TODO: keep trying if rpc call to get all repositories fails
    with {:ok, repositories} <- Config.get_database().get_all_repositories(),
         :ok <- start_repositories_workers(repositories) do
      {:noreply, state}
    else
      {:error, reason} ->
        {:stop, reason, state}
    end
  end

  defp start_repositories_workers([]), do: :ok

  defp start_repositories_workers([repo | rest]) do
    repo
    |> PollerSupervisor.start_child()
    |> case do
      {:ok, _pid} ->
        start_repositories_workers(rest)

      {:error, {:already_started, _pid}} ->
        start_repositories_workers(rest)

      {:error, _} = error ->
        error
    end
  end
end
