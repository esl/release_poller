defmodule Domain.Jobs.NewReleaseJob do
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
  alias __MODULE__

  @derive [Poison.Encoder]

  @type t :: %__MODULE__{
          repo: Repo.t(),
          new_tags: list(Tag.t())
        }
  defstruct repo: nil, new_tags: []

  @spec new(Repo.t(), nonempty_list(Tag.t())) :: NewReleaseJob.t()
  def new(repo, tags) do
    %NewReleaseJob{repo: repo, new_tags: tags}
  end
end
