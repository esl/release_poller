defmodule Domain.Serializers.NewReleaseJobSerializer do
  @moduledoc """
  JSON Serializer and Deserializer for `NewReleaseJob`
  """
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
  alias Domain.Jobs.NewReleaseJob

  @spec serialize!(NewReleaseJob.t()) :: iodata() | no_return()
  def serialize!(%NewReleaseJob{} = job) do
    Poison.encode!(job)
  end

  @doc """
  decodes a JSON string/iodata into a typed nested struct (NewReleaseJob with
  its new Tags and corresponding Repo)
  %NewReleaseJob{
    new_tag: %Tag{
      commit: %{
        sha: "...",
        url: "..."
      },
      name: "...",
      node_id: "...",
      tarball_url: "...",
      zipball_url: "..."
    },
    repo: %Repo{name: "erlang-katana", owner: "inaka"}
  }
  """
  @spec deserialize!(iodata()) :: NewReleaseJob.t() | no_return()
  def deserialize!(payload) do
    Poison.decode!(payload,
      as: %NewReleaseJob{
        repo: %Repo{
          url: nil,
          polling_interval: nil,
          name: nil,
          owner: nil
        },
        new_tag: %Tag{name: nil}
      },
      keys: :atoms!
    )
  end
end
