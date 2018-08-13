defmodule RepoPoller.Repository.Adapter do
  alias RepoPoller.Domain.{Repo, Tag}

  @callback get_tags(Repo.t()) ::
              {:ok, list(Tag.t())} | {:error, :rate_limit, pos_integer()} | {:error, any()}
end
