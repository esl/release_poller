defmodule RepoPoller.DB do
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
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

  @spec get_tags(Repo.t()) :: list(Tag.t())
  def get_tags(%{name: repo_name}) do
    case :ets.lookup(@table, repo_name) do
      [] -> []
      [{^repo_name, %{tags: tags}}] -> tags
    end
  end

  @spec clear() :: true
  def clear() do
    true = :ets.delete_all_objects(@table)
  end
end
