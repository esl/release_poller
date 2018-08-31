defmodule Domain.Tasks.Sources.Source do
  @callback fetch(Task.t(), Path.t()) :: {:ok, Task.t()} | {:error, any()}
end
