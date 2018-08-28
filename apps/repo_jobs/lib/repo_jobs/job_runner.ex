defmodule RepoJobs.JobRunner do
  require Logger

  alias RepoJobs.{TempStore, TaskFetcher}
  alias RepoJobs.TaskRunners.Make

  defmodule NotImplementedError do
    defexception message: "NotImplementedError"
  end

  def run(job) do
    %{
      repo: %{owner: owner, name: repo_name, tasks: tasks},
      new_tag: %{name: tag_name}
    } = job

    env = generate_env(job)
    # tmp_dir: /tmp/erlang/otp/21.0.2
    {:ok, tmp_dir} = TempStore.create_tmp_dir([owner, repo_name, tag_name])
    TaskFetcher.fetch(tasks, tmp_dir)
    |> Enum.map(&exec(&1, env))
  end

  defp exec(%{adapter: :make} = task, env) do
    Make.exec(task, env)
  end

  defp exec(%{adapter: adapter}, _env) do
    raise NotImplementedError, message: "adapter #{inspect(adapter)} is not implemented yet"
  end

  defp generate_env(%{repo: %{name: repo_name}, new_tag: tag}) do
    repo_name = String.upcase(repo_name)
    %{name: tag_name, zipball_url: zipball_url, tarball_url: tarball_url} = tag

    [
      {repo_name <> "_TAG", tag_name},
      {repo_name <> "_ZIP", zipball_url},
      {repo_name <> "_TAR", tarball_url}
    ]
  end
end
