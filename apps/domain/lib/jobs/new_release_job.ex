defmodule Domain.Jobs.NewReleaseJob do
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
  alias __MODULE__

  @derive [Poison.Encoder]

  @type t :: %__MODULE__{
          repo: Repo.t(),
          new_tag: Tag.t()
        }
  defstruct repo: nil, new_tag: nil

  @spec new(Repo.t(), Tag.t() | nonempty_list(Tag.t())) :: NewReleaseJob.t()
  def new(repo, tags) when is_list(tags) do
    Enum.map(tags, &new(repo, &1))
  end

  @spec new(Repo.t(), Tag.t()) :: NewReleaseJob.t()
  def new(repo, tag) do
    %NewReleaseJob{repo: repo, new_tag: tag}
  end
end
