defmodule RepoPoller.Domain.Repo do
  alias RepoPoller.Domain.Repo

  @enforce_keys [:name, :owner]
  @type t :: %__MODULE__{
          name: String.t(),
          owner: String.t()
        }

  defstruct name: nil, owner: nil

  @spec new(binary()) :: Repo.t()
  def new(url) do
    %{path: path} = URI.parse(url)

    [owner, repo_name] =
      String.replace_leading(path, "/", "")
      |> String.split("/")

    %Repo{owner: owner, name: repo_name}
  end
end
