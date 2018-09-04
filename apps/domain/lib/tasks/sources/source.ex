defmodule Domain.Tasks.Sources.Source do
  alias Domain.Tasks.Task
  @callback fetch(Task.t(), Path.t()) :: {:ok, Task.t()} | {:error, any()}
end
