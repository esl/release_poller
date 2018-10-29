defmodule Domain.Tags.Tag do
  @moduledoc """
  Represents the new `tags` or `releases` of a Github repository
  """
  alias Domain.Helpers.Map, as: HelperMap
  alias __MODULE__

  @derive [Poison.Encoder]

  @enforce_keys [:name]
  @type url :: String.t()
  @type t :: %__MODULE__{
          name: Version.t(),
          node_id: String.t(),
          commit: %{
            required(:sha) => String.t(),
            required(:url) => url()
          },
          zipball_url: url(),
          tarball_url: url()
        }
  defstruct name: nil, node_id: nil, commit: nil, zipball_url: nil, tarball_url: nil

  @spec new(attrs) :: Tag.t() | no_return() when attrs: %{required(:name) => Version.t()}
  def new(attrs) do
    new_attrs = HelperMap.safe_map_keys_to_atom(attrs)
    struct!(__MODULE__, new_attrs)
  end

  @spec new(String.t(), String.t(), url(), url(), url(), String.t()) :: Tag.t()
  def new(name, commit_sha, commit_url, tarball_url, zipball_url, node_id) do
    %Tag{
      name: name,
      node_id: node_id,
      commit: %{
        sha: commit_sha,
        url: commit_url
      },
      zipball_url: zipball_url,
      tarball_url: tarball_url
    }
  end

  @doc """
  Returns the new `tags` of a repository, computing the difference from both lists
  """
  @spec new_tags(list(Tag.t()), list(Tag.t())) :: list(Tag.t())
  def new_tags(old_tags, new_tags) do
    Enum.reduce(new_tags, [], fn tag, acc ->
      if Enum.member?(old_tags, tag) do
        acc
      else
        [tag | acc]
      end
    end)
    |> Enum.reverse()
  end
end
