defmodule RepoPoller.Repository.Adapter do
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag

  @callback get_tags(Repo.t()) ::
              {:ok, list(Tag.t())} | {:error, :rate_limit, pos_integer()} | {:error, any()}
end
