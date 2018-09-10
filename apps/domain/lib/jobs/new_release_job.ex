defmodule Domain.Jobs.NewReleaseJob do
  @moduledoc """
  RabbitMQ Job Struct for enqueuing a new release for a given repository
  """

  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
  alias __MODULE__

  @derive [Poison.Encoder]

  @type t :: %__MODULE__{
          repo: Repo.t(),
          new_tag: Tag.t()
        }
  defstruct repo: nil, new_tag: nil

  @doc """
  Creates a list of `jobs`, one per each new `tag`
  """
  @spec new(Repo.t(), nonempty_list(Tag.t())) :: list(NewReleaseJob.t())
  def new(repo, tags) when is_list(tags) do
    Enum.map(tags, &new(repo, &1))
  end

  @doc """
  Creates a `job`, with a `repo` and its corresponding new `tag`
  """
  @spec new(Repo.t(), Tag.t()) :: NewReleaseJob.t()
  def new(repo, tag) do
    %NewReleaseJob{repo: repo, new_tag: tag}
  end
end
