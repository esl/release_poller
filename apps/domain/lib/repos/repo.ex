defmodule Domain.Repos.Repo do
  @moduledoc """
  Represents a dependency we rely on. for now it represents a Github repository
  """

  alias __MODULE__
  alias Domain.Tags.Tag
  alias Domain.Tasks.Task

  @derive {Poison.Encoder, except: [:tags, :adapter, :tasks]}

  # 1 Hour in ms
  @one_hour 3_600_000

  @enforce_keys [:url, :polling_interval]
  @type interval :: non_neg_integer()
  @type id :: non_neg_integer()
  @type url :: String.t()
  @type t :: %__MODULE__{
          name: String.t(),
          owner: String.t(),
          url: String.t(),
          adapter: String.t(),
          # In milliseconds
          polling_interval: interval(),
          tags: list(Tag.t()),
          tasks: list(Task.t())
        }

  defstruct name: nil,
            owner: nil,
            url: nil,
            adapter: "github",
            polling_interval: nil,
            tags: [],
            tasks: []

  @spec new(String.t(), interval(), String.t()) :: Repo.t()
  def new(url, interval \\ @one_hour, adapter \\ "github") do
    %{path: path} = URI.parse(url)

    [owner, repo_name] =
      path
      |> String.replace_leading("/", "")
      |> String.split("/")

    %Repo{url: url, owner: owner, name: repo_name, polling_interval: interval, adapter: adapter}
  end

  @doc """
  Prepends a list of new `tags` to the `repo`'s list of `tags`
  """
  @spec add_tags(Repo.t(), list(Tag.t())) :: Repo.t()
  def add_tags(%{tags: tags} = repo, new_tags) do
    %Repo{repo | tags: new_tags ++ tags}
  end

  @doc """
  Sets the list of `tasks` to be executed when a new `tag` of the corresponding
  repo is released
  """
  @spec set_tasks(Repo.t(), list(Task.t())) :: Repo.t()
  def set_tasks(repo, tasks) do
    %Repo{repo | tasks: tasks}
  end

  @doc """
  Generates the unique name of the `repo` which is computed with the `repo`'s
  owner + / + `repo`'s name e.g "elixir-lang/elixir"
  """
  @spec uniq_name(Repo.t()) :: String.t()
  def uniq_name(%{owner: owner, name: name}) do
    "#{owner}/#{name}"
  end
end
