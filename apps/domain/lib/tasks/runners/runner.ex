defmodule Domain.Tasks.Runners.Runner do
  @callback exec(task :: Task.t(), env :: keyword()):: :ok | {:error, any()} | no_return()
end
