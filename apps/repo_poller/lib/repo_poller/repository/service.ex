defmodule RepoPoller.Repository.Service do
  alias RepoPoller.Domain.{Repo, Tag}

  @spec get_tags(atom(), Repo.t()) ::
          {:ok, list(Tag.t())} | {:error, :rate_limit, pos_integer()} | {:error, map()}
  def get_tags(adapter, repo) do
    adapter.get_tags(repo)
  end
end
