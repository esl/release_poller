defmodule RepoPoller.Domain.Tag do
  alias RepoPoller.Helpers.Map, as: HelperMap
  alias RepoPoller.Domain.Tag

  @enforce_keys [:name]
  @type t :: %__MODULE__{
          name: Version.t(),
          node_id: String.t(),
          commit: %{
            required(:sha) => String.t(),
            required(:url) => String.t()
          },
          zipball_url: String.t(),
          tarball_url: String.t()
        }
  defstruct name: nil, node_id: nil, commit: nil, zipball_url: nil, tarball_url: nil

  @spec new(attrs) :: Tag.t() when attrs: %{required(:name) => Version.t()}
  def new(attrs \\ %{}) do
    new_attrs = HelperMap.safe_map_keys_to_atom(attrs)
    struct!(__MODULE__, new_attrs)
  end

  @spec new_tags?(list(Tag.t()), list(Tag.t())) :: boolean()
  def new_tags?(old_tags, new_tags) do
    new_tags -- old_tags
    |> Enum.empty?()
    |> Kernel.not()
  end
end
