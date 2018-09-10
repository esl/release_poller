defmodule RepoPoller.DB do
  alias Domain.Repos.Repo
  alias RepoPoller.Config

  @table :repo_tags

  @spec new() :: :ets.tab()
  def new do
    db_name = Config.get_db_name()

    PersistentEts.new(@table, db_name, [
      :named_table,
      :public,
      read_concurrency: true,
      write_concurrency: true
    ])
  end

  @spec save(Repo.t()) :: :ok
  def save(%{name: repo_name} = repo) do
    :ets.insert(@table, {repo_name, repo})
    # persist all saves to file
    PersistentEts.flush(@table)
  end

  @spec get_repo(Repo.t()) :: Repo.t() | nil
  def get_repo(%{name: repo_name}) do
    case :ets.lookup(@table, repo_name) do
      [] -> nil
      [{^repo_name, repo}] -> repo
    end
  end

  @spec clear() :: true
  def clear() do
    true = :ets.delete_all_objects(@table)
  end
end
