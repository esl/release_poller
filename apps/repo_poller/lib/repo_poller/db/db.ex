defmodule RepoPoller.DB do
  alias RepoPoller.Domain.{Repo, Tag}

  @table :repo_tags

  @spec new() :: :ets.tab()
  def new do
    db_name = get_db_name()

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

  defp get_db_name() do
    Application.get_env(:repo_poller, :db_name, "repo_tags.tab")
  end
end
