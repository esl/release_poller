defmodule RepoPoller.PollerSupervisor do
  alias RepoPoller.Poller
  alias Domain.Repos.Repo
  alias RepoPoller.Config

  def start_child(%Repo{} = repo) do
    pool_id = Config.get_connection_pool_id()

    adapter = setup_adapter(repo.adapter)

    # Horde doesn't support :transient children yet: https://github.com/derekkraan/horde/issues/36
    # Horde.Supervisor.start_child(RepoPoller.DistributedSupervisor, %{
    #   id: "poller_#{repo.name}",
    #   start: {Poller, :start_link, [{repo, adapter, pool_id}]},
    #   restart: :transient
    # })
    Horde.Supervisor.start_child(RepoPoller.DistributedSupervisor, %{
      id: "poller_#{repo.name}",
      start: {Poller, :start_link, [{repo, adapter, pool_id}]}
    })
  end

  def start_child(%{
        repository_url: url,
        polling_interval: interval,
        adapter: adapter,
        github_token: token
      }) do
    pool_id = Config.get_connection_pool_id()
    repo = Repo.new(url, interval * 1000, adapter, token)

    adapter = setup_adapter(adapter)

    # Horde doesn't support :transient children yet: https://github.com/derekkraan/horde/issues/36
    # Horde.Supervisor.start_child(RepoPoller.DistributedSupervisor, %{
    #   id: "poller_#{repo.name}",
    #   start: {Poller, :start_link, [{repo, adapter, pool_id}]},
    #   restart: :transient
    # })
    Horde.Supervisor.start_child(RepoPoller.DistributedSupervisor, %{
      id: "poller_#{repo.name}",
      start: {Poller, :start_link, [{repo, adapter, pool_id}]}
    })
  end

  def stop_child(repository_url) do
    repo = Repo.new(repository_url)

    try do
      repo.name
      |> String.to_existing_atom()
      |> Process.whereis()
      |> case do
        nil ->
          {:error, "Couldn't find repository process."}

        pid when is_pid(pid) ->
          Horde.Supervisor.terminate_child(__MODULE__, pid)
      end
    rescue
      _ -> {:error, "Couldn't find repository process."}
    end
  end

  defp setup_adapter(adapter) when is_atom(adapter), do: adapter

  defp setup_adapter(adapter) when is_binary(adapter) do
    Module.concat(["RepoPoller.Repository", Macro.camelize(adapter)])
  end
end
