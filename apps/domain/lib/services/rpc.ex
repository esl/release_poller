defmodule Domain.Services.RPC do
  alias Domain.Config
  alias Domain.Repos.Repo

  @callback get_all_repositories() :: any() | {:badrpc, any()}
  @callback get_all_tags(String.t()) :: any() | {:badrpc, any()}
  @callback create_tag(Repo.url(), map()) :: any() | {:badrpc, any()}
  @callback get_repo_tasks(Repo.url()) :: any() | {:badrpc, any()}

  def get_all_repositories() do
    Config.get_admin_domain()
    |> :rpc.call(ReleaseAdmin.Repository.Service, :all, [])
  end

  def get_all_tags(url) do
    Config.get_admin_domain()
    |> :rpc.call(ReleaseAdmin.Tag.Service, :repo_tags, [url])
  end

  def create_tag(url, tag) do
    Config.get_admin_domain()
    |> :rpc.call(ReleaseAdmin.Tag.Service, :create_tag, [url, tag])
  end

  def get_repo_tasks(url) do
    Config.get_admin_domain()
    |> :rpc.call(ReleaseAdmin.Task.Service, :repo_tasks, [url])
  end
end
