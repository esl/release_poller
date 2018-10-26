defmodule Domain.Services.Database do
  alias Domain.Repos.Repo
  alias Domain.Config

  @type repository :: %{polling_interval: non_neg_integer(), repository_url: String.t()}

  @callback get_all_repositories() :: {:ok, list(Repo.t())} | {:error, any()}

  def get_all_repositories do
    Config.get_admin_domain()
    |> :rpc.call(ReleaseAdmin.Repository.Service, :all, [])
    |> case do
      {:badrpc, reason} ->
        {:error, reason}

      repositories ->
        {:ok, to_repo(repositories)}
    end
  end

  @spec to_repo(list(repository)) :: list(Repo.t())
  defp to_repo(repositories) do
    Enum.map(repositories, fn repo ->
      %{polling_interval: polling_interval, repository_url: repository_url, adapter: adapter} = repo
      Repo.new(repository_url, polling_interval * 1000, adapter)
    end)
  end
end
