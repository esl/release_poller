defmodule RepoJobs.JobRunner do
  require Logger

  alias Domain.Tasks.Helpers.TempStore

  defmodule NotImplementedError do
    defexception message: "NotImplementedError"
  end

  def run(job) do
    %{
      repo: %{owner: owner, name: repo_name, tasks: tasks},
      new_tag: %{name: tag_name}
    } = job

    job_name = "#{owner}/#{repo_name}##{tag_name}}"

    env = generate_env(job)
    # tmp_dir: /tmp/erlang/otp/21.0.2
    {:ok, tmp_dir} = TempStore.create_tmp_dir([owner, repo_name, tag_name])

    tasks
    |> Enum.map(fn task ->
      %{url: url, source: source, runner: runner} = task
      Logger.info("[job_runner] running task #{url} for #{job_name}")

      with {:ok, task} <- source.fetch(task, tmp_dir),
           :ok <- runner.exec(task, env) do
        {:ok, task}
      else
        {:error, error} ->
          Logger.error(
            "[job_runner] error running task #{url} for #{job_name} reason: #{inspect(error)}"
          )

          {:error, task}
      end
    end)
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
