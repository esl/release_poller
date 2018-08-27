defmodule Domain.Repos.Repo do
  alias __MODULE__
  alias Domain.Tags.Tag
  alias Domain.Scripts.Script

  @derive {Poison.Encoder, except: [:tags]}

  @enforce_keys [:name, :owner]
  @type t :: %__MODULE__{
          name: String.t(),
          owner: String.t(),
          tags: list(Tag.t()),
          scripts: list(Script.t())
        }

  defstruct name: nil, owner: nil, tags: [], scripts: []

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

  @spec set_scripts(Repo.t(), list(Script.t())) :: Repo.t()
  def set_scripts(repo, scripts) do
    %Repo{repo | scripts: scripts}
  end
end
