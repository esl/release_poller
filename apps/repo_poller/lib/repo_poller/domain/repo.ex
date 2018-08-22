defmodule RepoPoller.Domain.Repo do
  alias RepoPoller.Domain.{Repo, Tag}

  @enforce_keys [:name, :owner]
  @type t :: %__MODULE__{
          name: String.t(),
          owner: String.t(),
          tags: list(Tag.t())
        }

  defstruct name: nil, owner: nil, tags: []

  @spec new(binary()) :: Repo.t()
  def new(url) do
    %{path: path} = URI.parse(url)

    [owner, repo_name] =
      path
      |> String.replace_leading("/", "")
      |> String.split("/")

    %Repo{owner: owner, name: repo_name}
  end

  @spec set_tags(Repo.t(), list(Tag.t())) :: Repo.t()
  def set_tags(repo, tags) do
    %Repo{repo | tags: tags}
  end
end
