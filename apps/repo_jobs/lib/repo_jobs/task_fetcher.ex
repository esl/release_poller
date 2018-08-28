defmodule RepoJobs.TaskFetcher do
  alias RepoJobs.TempStore

  def fetch(tasks, base_dir) do
    tasks
    |> Enum.map(fn %{url: url} = task ->
      # url: https://github.com/elixir-lang/elixir
      # dest_path: /tmp/erlang/otp/-21.0.2/elixir-lang/elixir
      dest_path = TempStore.generate_destination_path(base_dir, url)

      # remove repositories already cloned, this may happen if we want to re run some job
      if File.exists?(dest_path) do
        File.rm_rf!(dest_path)
      end

      clone(url, dest_path)
      %{task | path: dest_path}
    end)
  end

  # TODO: handle "already exists and is not an empty directory."
  defp clone(repo_url, dest_path) do
    case System.cmd("git", ["clone", repo_url, "--depth=1", dest_path], env: []) do
      {_, 0} ->
        :ok

      error ->
        throw("error cloning #{repo_url} into #{dest_path} reason: #{inspect(error)}")
    end
  end
end
