defmodule RepoPoller.Api.Github do
  alias Tentacat.Client
  alias Tentacat.Repositories.Tags
  alias RepoPoller.Domain.Repo

  def new(access_token) do
    Client.new(%{access_token: access_token})
  end

  @spec tags(Tentacat.Client.t(), Repo.t()) :: Tentacat.response()
  def tags(client, %{owner: owner, name: name}) do
    Tags.list(client, owner, name, pagination: :none)
  end
end
