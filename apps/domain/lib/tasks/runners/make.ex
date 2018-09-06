defmodule Domain.Tasks.Runners.Make do
  alias Domain.Tasks.Runners.Runner

  @behaviour Runner

  @filename "Makefile"

  @doc """
  Executes the given task via `make`, if the task has a non empty list of commands
  it will run each command secuentialy, and will stop if there is an error in
  one of them, returning an error tuple:

      make -f Makefile install
      make -f Makefile build
      make -f Makefile release
      make -f Makefile deploy
  """
  @impl true
  def exec(task, env) do
    try do
      make(task, env)
    catch
      error -> {:error, error}
    end
  end

  defp make(%{path: path, env: extra_env, commands: []}, env) do
    case do_make([], env: extra_env ++ env, cd: path) do
      {_, 0} ->
        :ok

      error ->
        {:error, error}
    end
  end

  defp make(%{path: path, env: extra_env, commands: commands}, env) do
    for command <- commands do
      # TODO: validate output
      # make -f path/to/Makefile build
      # make -f path/to/Makefile deploy
      # make -f path/to/Makefile release
      # ...

      case do_make([command], env: extra_env ++ env, cd: path) do
        {_, 0} ->
          :ok

        error ->
          # next commands may depend on failed command so we need to break on error
          throw(error)
      end
    end

    :ok
  end

  defp do_make(args, opts) do
    defaults = [stderr_to_stdout: true, into: IO.stream(:stdio, :line)]
    opts = Keyword.merge(defaults, opts)

    System.cmd("make", ["-f", @filename | args], opts)
  end
end
