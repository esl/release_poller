defmodule RepoJobs.Tasks.Runners.Make do
  alias RepoJobs.Tasks.Runners.Runner

  @behaviour Runner

  @filename "Makefile"

  @impl true
  def exec(task, env) do
    make(task, env)
  end

  defp make(%{path: path, env: extra_env, commands: []}, env) do
    case do_make(@filename, env: extra_env ++ env, cd: path) do
      {_, 0} ->
        :ok

      error ->
        {:error, error}
    end
  end

  defp make(%{path: path, env: extra_env, commands: commands}, env) do
    # run default command if no commands
    commands = if Enum.empty?(commands), do: [nil]

    for command <- commands do
      # TODO: validate output
      # make -f path/to/Makefile build
      # make -f path/to/Makefile deploy
      # make -f path/to/Makefile release
      # ...

      case do_make(@filename, command, env: extra_env ++ env, cd: path) do
        {_, 0} ->
          :ok

        error ->
          # next commands may depend on failed command so we need to break on error
          throw error
      end
    end
  end

  defp do_make(name, opts) do
    System.cmd("make", ["-f", name], opts)
  end

  defp do_make(name, command, opts) do
    System.cmd("make", ["-f", name, command], opts)
  end
end
