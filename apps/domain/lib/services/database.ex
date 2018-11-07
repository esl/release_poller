defmodule Domain.Services.Database do
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
  alias Domain.Tasks.Task
  alias Domain.Config

  @type repository :: %{
          polling_interval: non_neg_integer(),
          repository_url: String.t(),
          adapter: String.t()
        }
  @type tag :: %{name: String.t(), commit_sha: String.t(), commit_url: String.t()}
  @type task :: %{runner: String.t()}

  @callback get_all_repositories() :: {:ok, list(Repo.t())} | {:error, any()}
  @callback get_all_tags(String.t()) :: {:ok, list(Tag.t())} | {:error, any()}
  @callback create_tag(Repo.url(), Tag.t()) :: {:ok, tag()} | {:error, any()}
  @callback get_repo_tasks(Repo.url()) :: {:ok, list(Task.t())} | {:error, any()}

  def get_all_repositories() do
    case Config.get_rpc_impl().get_all_repositories() do
      {:badrpc, reason} ->
        {:error, reason}

      repositories ->
        {:ok, to_repo(repositories)}
    end
  end

  def get_all_tags(url) do
    case Config.get_rpc_impl().get_all_tags(url) do
      {:badrpc, reason} ->
        {:error, reason}

      tags ->
        {:ok, to_tag(tags)}
    end
  end

  def create_tag(url, %Tag{} = tag) do
    map_tag = Map.from_struct(tag)

    case Config.get_rpc_impl().create_tag(url, map_tag) do
      {:badrpc, reason} ->
        {:error, reason}

      {:ok, _} = result ->
        result

      {:error, _} = error ->
        error
    end
  end

  def get_repo_tasks(url) do
    case Config.get_rpc_impl().get_repo_tasks(url) do
      {:badrpc, reason} ->
        {:error, reason}

      tasks ->
        {:ok, to_task(tasks)}
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

  @spec to_task(list(task)) :: list(Task.t())
  defp to_task(tasks) do
    Enum.map(tasks, fn task ->
      %{
        id: id,
        runner: runner,
        source: source,
        env: env_map,
        fetch_url: url,
        commands: commands,
        build_file_content: build_file_content,
        ssh_key: ssh_key,
        docker_username: docker_username,
        docker_email: docker_email,
        docker_password: docker_password,
        docker_servername: docker_servername
      } = task

      # runner and source came as strings "make", "docker_build", "github" and we need to convert
      # them into modules

      # Converts "docker_build" into "DockerBuild"
      runner = Macro.camelize(runner)
      # Converts "docker_build" into Domain.Tasks.Runners.DockerBuild
      runner_module = Module.concat([Domain.Tasks.Runners, runner])

      source_module =
        if source do
          source = Macro.camelize(source)
          # Converts "github" into Domain.Tasks.Sources.Github
          Module.concat([Domain.Tasks.Sources, source])
        end

      env = Map.to_list(env_map)

      %{
        id: id,
        runner: runner_module,
        source: source_module,
        env: env,
        url: url,
        commands: commands,
        build_file_content: build_file_content,
        ssh_key: ssh_key,
        docker_username: docker_username,
        docker_email: docker_email,
        docker_password: docker_password,
        docker_servername: docker_servername
      }
      |> Task.new()
    end)
  end
end
