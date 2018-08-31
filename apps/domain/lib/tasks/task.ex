defmodule Domain.Tasks.Task do
  alias __MODULE__
  alias Domain.Tasks.Runners.Make
  alias Domain.Tasks.Sources.Github

  @type runner :: module()
  # TODO: add support for other sources e.g GitLab etc
  @type source :: module()

  @type t :: %__MODULE__{
          url: String.t(),
          path: Path.t(),
          env: keyword(),
          commands: list(String.t()),
          runner: runner(),
          source: source()
        }

  defstruct url: nil, path: nil, env: [], commands: [], runner: Make, source: Github

  @spec new(Enum.t()) :: Task.t() | no_return()
  def new(attrs) do
    struct!(__MODULE__, attrs)
  end
end
