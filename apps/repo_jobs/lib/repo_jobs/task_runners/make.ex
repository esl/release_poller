defmodule RepoJobs.TaskRunners.Make do
  alias RepoJobs.TaskRunners.TaskRunner
  @behaviour TaskRunner

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
        error_path = Path.join([path, @filename])
        throw("Error executing #{error_path} reason: #{inspect(error)}")
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
          error_path = Path.join([path, @filename])
          throw("error executing #{error_path} reason: #{inspect(error)}")
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
