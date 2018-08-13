defmodule RepoPoller.Domain.Repo do
  @type t :: %__MODULE__{
          name: String.t(),
          owner: String.t()
        }

  defstruct name: nil, owner: nil
end
