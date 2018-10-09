defmodule RepoJobs.JobRunner do
  require Logger

  alias Domain.Tasks.Helpers.TempStore
  alias Domain.Jobs.NewReleaseJob
  alias Domain.Tasks.Task

  @tmp_dir System.tmp_dir!()

  @doc """
  Fetch and Executes all tasks assigned to a new tag/release of a dependency,
  returning all tasks that succeeded as `{:ok, task}` and all that failed as
  `{:error, task}`
  """
  @spec run(NewReleaseJob.t()) :: list(result)
        when result: {:ok, Task.t()} | {:error, Task.t()}
  def run(%{repo: %{tasks: []}}), do: []

  def run(job) do
    %{repo: %{tasks: tasks}} = job
    env = generate_env(job)
    Enum.map(tasks, &run_task(&1, job, env))
  end

  defp run_task(%Task{runner: runner, build_file: build_file} = task, job, env)
       when not is_nil(build_file) do
    %{
      repo: %{owner: owner, name: repo_name},
      new_tag: %{name: tag_name}
    } = job

    job_name = "#{owner}/#{repo_name}##{tag_name}"
    Logger.info("running task #{build_file} for #{job_name}")

    with :ok <- runner.exec(task, env) do
      {:ok, task}
    else
      {:error, error} ->
        Logger.error("error running task #{build_file} for #{job_name} reason: #{inspect(error)}")
        {:error, task}
    end
  end

  defp run_task(%Task{runner: runner, url: url, source: source} = task, job, env) do
    %{
      repo: %{owner: owner, name: repo_name},
      new_tag: %{name: tag_name}
    } = job

    job_name = "#{owner}/#{repo_name}##{tag_name}"
    # tmp_dir: /tmp/erlang/otp/21.0.2
    {:ok, tmp_dir} = TempStore.create_tmp_dir([owner, repo_name, tag_name], temp_dir())
    Logger.info("running task #{url} for #{job_name}")

    with {:ok, task} <- source.fetch(task, tmp_dir),
         :ok <- runner.exec(task, env) do
      {:ok, task}
    else
      {:error, error} ->
        Logger.error("error running task #{url} for #{job_name} reason: #{inspect(error)}")

        {:error, task}
    end
  end

  # Returns a list of tuples to be passed as environment variables to each task
  defp generate_env(%{repo: %{name: repo_name}, new_tag: tag}) do
    repo_name = String.upcase(repo_name)

    %{
      name: tag_name,
      zipball_url: zipball_url,
      tarball_url: tarball_url,
      commit: %{sha: commit_tag}
    } = tag

    [
      {repo_name <> "_TAG", tag_name},
      {repo_name <> "_ZIP", zipball_url},
      {repo_name <> "_TAR", tarball_url},
      {repo_name <> "_COMMIT", commit_tag}
    ]
  end

  defp temp_dir() do
    Application.get_env(:repo_jobs, :tmp_dir, @tmp_dir)
  end
end
