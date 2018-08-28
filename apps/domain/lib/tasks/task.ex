defmodule Domain.Tasks.Task do
  alias __MODULE__

  @type task_adapter :: :make

  @type t :: %__MODULE__{
          url: String.t(),
          path: Path.t(),
          env: keyword(),
          commands: list(String.t()),
          adapter: task_adapter()
        }

  defstruct url: nil, path: nil, env: [], commands: [], adapter: :make

  @spec new(Enum.t()) :: Task.t() | no_return()
  def new(attrs) do
    struct!(__MODULE__, attrs)
  end
end
