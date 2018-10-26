defmodule RepoPoller.PollerSupervisor do
  use DynamicSupervisor

  alias RepoPoller.Poller
  alias Domain.Repos.Repo
  alias Domain.Tasks.Task
  alias RepoPoller.{DB, Config}

  def start_link(args \\ []) do
    name = Keyword.get(args, :name, __MODULE__)
    DynamicSupervisor.start_link(__MODULE__, [], name: name)
  end

  def init(_) do
    # let the DB be managed by the supervisor so it won't be restarted unless the supervisor is restarted too
    DB.new()
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(%Repo{} = repo, adapter) do
    pool_id = Config.get_connection_pool_id()

    DynamicSupervisor.start_child(__MODULE__, %{
      id: "poller_#{repo.name}",
      start: {Poller, :start_link, [{repo, adapter, pool_id}]},
      restart: :transient
    })
  end

  def start_child(%{repository_url: url, polling_interval: interval, adapter: adapter}) do
    pool_id = Config.get_connection_pool_id()
    repo = Repo.new(url, interval * 1000)

    DynamicSupervisor.start_child(__MODULE__, %{
      id: "poller_#{repo.name}",
      start: {Poller, :start_link, [{repo, adapter, pool_id}]},
      restart: :transient
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
          DynamicSupervisor.terminate_child(__MODULE__, pid)
      end
    rescue
      _ -> {:error, "Couldn't find repository process."}
    end
  end

  @spec setup_repo(String.t(), Repo.interval(), keyword()) :: Repo.t()
  defp setup_repo(url, interval, tasks_attrs) do
    tasks = Enum.map(tasks_attrs, &setup_task/1)

    Repo.new(url, interval)
    |> Repo.set_tasks(tasks)
  end

  @spec setup_task(keyword()) :: Task.t()
  defp setup_task(task_attr) do
    {_, new_attrs} =
      Keyword.get_and_update(task_attr, :build_file, fn
        nil ->
          :pop

        build_file_path ->
          expanded_path = Path.join([Config.priv_dir(), build_file_path])
          {build_file_path, expanded_path}
      end)

    Task.new(new_attrs)
  end
end
