defmodule Domain.Tasks.Runners.Runner do
  alias Domain.Tasks.Task
  @callback exec(task :: Task.t(), env :: keyword()) :: :ok | {:error, any()} | no_return()
end
