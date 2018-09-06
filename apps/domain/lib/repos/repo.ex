defmodule Domain.Repos.Repo do
  alias __MODULE__
  alias Domain.Tags.Tag
  alias Domain.Tasks.Task

  @derive {Poison.Encoder, except: [:tags]}

  @enforce_keys [:name, :owner]
  @type t :: %__MODULE__{
          name: String.t(),
          owner: String.t(),
          tags: list(Tag.t()),
          tasks: list(Task.t())
        }

  defstruct name: nil, owner: nil, tags: [], tasks: []

  @spec new(binary()) :: Repo.t()
  def new(url) do
    %{path: path} = URI.parse(url)

    [owner, repo_name] =
      path
      |> String.replace_leading("/", "")
      |> String.split("/")

    %Repo{owner: owner, name: repo_name}
  end

  @spec add_tags(Repo.t(), list(Tag.t())) :: Repo.t()
  def add_tags(%{tags: tags} = repo, new_tags) do
    %Repo{repo | tags: new_tags ++ tags}
  end

  @spec set_tasks(Repo.t(), list(Task.t())) :: Repo.t()
  def set_tasks(repo, tasks) do
    %Repo{repo | tasks: tasks}
  end

  def uniq_name(%{owner: owner, name: name}) do
    "#{owner}/#{name}"
  end
end
