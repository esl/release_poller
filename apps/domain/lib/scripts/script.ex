defmodule Domain.Scripts.Script do

  alias __MODULE__

  @enforce_keys [:url]

  @type t :: %__MODULE__{
    url: String.t(),
    path: Path.t(),
    env: keyword(),
    actions: list(String.t())
  }

  defstruct url: nil, path: nil, env: [], actions: []

  @spec new(Enum.t()) :: Script.t() | no_return()
  def new(attrs) do
    struct!(__MODULE__, attrs)
  end
end
