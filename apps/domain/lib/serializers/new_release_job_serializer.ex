defmodule Domain.Serializers.NewReleaseJobSerializer do
  @moduledoc """
  JSON Serializer and Deserializer for `NewReleaseJob`
  """
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
  alias Domain.Tasks.Task
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
    repo: %Repo{name: "erlang-katana", owner: "inaka", tags: []}
  }
  """
  @spec deserialize!(iodata()) :: NewReleaseJob.t() | no_return()
  def deserialize!(payload) do
    job =
      Poison.decode!(payload,
        as: %NewReleaseJob{
          repo: %Repo{
            url: nil,
            polling_interval: nil,
            name: nil,
            owner: nil,
            tasks: [%Task{}]
          },
          new_tag: %Tag{name: nil}
        },
        keys: :atoms!
      )

    map_tasks(job)
  end

  # Converts the deserialized job's tasks into something the system understands
  defp map_tasks(%{repo: repo} = job) do
    %{tasks: tasks} = repo

    tasks =
      tasks
      |> Enum.map(fn %{runner: runner, source: source, env: env_list} = task ->
        # runner and source cames as stringified atoms "Elixir.Domain.Tasks.Runners.Make"
        runner_module = Module.concat([runner])
        source_module = Module.concat([source])

        env =
          env_list
          |> Enum.map(fn [key, value] ->
            {key, value}
          end)

        %{task | runner: runner_module, source: source_module, env: env}
      end)

    %{job | repo: %{repo | tasks: tasks}}
  end
end
