defmodule Domain.Services.Database do
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
  alias Domain.Config

  @type repository :: %{polling_interval: non_neg_integer(), repository_url: String.t()}
  @type tag :: %{name: String.t(), commit_sha: String.t(), commit_url: String.t()}

  @callback get_all_repositories() :: {:ok, list(Repo.t())} | {:error, any()}
  @callback get_all_tags(String.t()) :: {:ok, list(Tag.t())} | {:error, any()}
  @callback create_tag(Repository.url(), Tag.t()) :: {:ok, tag()} | {:error, any()}

  def get_all_repositories() do
    Config.get_admin_domain()
    |> :rpc.call(ReleaseAdmin.Repository.Service, :all, [])
    |> case do
      {:badrpc, reason} ->
        {:error, reason}

      repositories ->
        {:ok, to_repo(repositories)}
    end
  end

  def get_all_tags(url) do
    Config.get_admin_domain()
    |> :rpc.call(ReleaseAdmin.Tag.Service, :repo_tags, [url])
    |> case do
      {:badrpc, reason} ->
        {:error, reason}

      tags ->
        {:ok, to_tag(tags)}
    end
  end

  def create_tag(url, %Tag{} = tag) do
    map_tag = Map.from_struct(tag)

    Config.get_admin_domain()
    |> :rpc.call(ReleaseAdmin.Tag.Service, :create_tag, [url, map_tag])
    |> case do
      {:badrpc, reason} ->
        {:error, reason}

      {:ok, _} = result ->
        result

      {:error, _} = error ->
        error
    end
  end

  @spec to_repo(list(repository)) :: list(Repo.t())
  defp to_repo(repositories) do
    Enum.map(repositories, fn repo ->
      %{
        polling_interval: polling_interval,
        repository_url: repository_url,
        adapter: adapter
      } = repo

      Repo.new(repository_url, polling_interval * 1000, adapter)
    end)
  end

  @spec to_tag(list(tag)) :: list(Tag.t())
  defp to_tag(tags) do
    Enum.map(tags, fn tag ->
      %{
        commit_sha: commit_sha,
        commit_url: commit_url,
        name: name,
        tarball_url: tarball_url,
        zipball_url: zipball_url,
        node_id: node_id
      } = tag

      Tag.new(name, commit_sha, commit_url, tarball_url, zipball_url, node_id)
    end)
  end
end
