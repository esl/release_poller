defmodule RepoJobs.JobRunner do
  require Logger

  alias RepoJobs.{FileDownloader, AssetStore}

  def run(job) do
    new_job = save_job_scripts(job)
    env = generate_env(new_job)

    for script <- new_job.repo.scripts do
      do_run(script, env)
    end
  end

  # TODO: handle failures
  defp save_job_scripts(job) do
    %{repo: %{owner: owner, name: name, scripts: scripts}} = job
    # /tmp/erlang/otp
    {:ok, tmp_dir} = AssetStore.create_tmp_dir([owner, name])

    new_scripts =
      scripts
      |> Enum.map(fn %{url: url} = script ->
        # TODO: expire cached files maybe using md5 check or something
        # tmp_dir: /tmp/erlang
        # url: /elixir-lang/elixir/master
        # filename: Makefile
        # file_path: /tmp/erlang/otp/elixir-lang/elixir/master/Makefile
        file_path = AssetStore.generate_file_path(tmp_dir, url)

        unless AssetStore.exists?(file_path) do
          {:ok, _} = AssetStore.create_dir_for_path(file_path)
          # TODO: add retries with exponential backoff for file downloads
          {:ok, file} = FileDownloader.download(url)
          # save content of downloaded file into file_path
          {:ok, _} = AssetStore.save(file, file_path)
        end

        %{script | path: file_path}
      end)

    put_in(job, [:repo, :scripts], new_scripts)
  end

  defp generate_env(%{repo: %{name: repo_name}, new_tags: tags}) do
    tags
    |> Enum.map(fn %{name: tag_name} ->
      {String.upcase(repo_name) <> "_TAG", tag_name}
    end)
  end

  # TODO: add support for multiple adapters e.g shell script (sh path/to/script), Dockerfile etc
  defp do_run(%{path: path, env: extra_env, actions: []}, env) do
    # TODO: validate output
    # run default action
    # make -f path/to/Makefile
    {_, 0} = System.cmd("make", ["-f", path], env: extra_env ++ env)
  end

  defp do_run(%{path: path, env: extra_env, actions: actions}, env) do
    for action <- actions do
      # TODO: validate output
      # make -f path/to/Makefile build
      # make -f path/to/Makefile deploy
      # make -f path/to/Makefile release
      # ...
      {_, 0} = System.cmd("make", ["-f", path, action], env: extra_env ++ env)
    end
  end
end
