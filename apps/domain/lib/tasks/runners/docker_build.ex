defmodule Domain.Tasks.Runners.DockerBuild do
  @behaviour Domain.Tasks.Runners.Runner

  alias ExDockerBuild.{DockerfileParser, DockerBuild}

  @impl true
  def exec(task, env) do
    %{build_file_content: build_file_content, env: extra_env} = task

    DockerfileParser.parse_content!(build_file_content)
    |> inject_env(extra_env ++ env)
    |> DockerBuild.build("")
    |> case do
      {:ok, _image_id} ->
        # TODO: push image
        :ok

      {:error, _} = error ->
        error
    end
  end

  # inject custom ENV variables just after the image creation (from IMAGE:TAG)
  # because it must be the first instruction in a dockerfile
  defp inject_env([from_image | rest_instructions], env) do
    docker_env =
      Enum.map(env, fn {env_name, env_value} ->
        {"ENV", "#{env_name} #{env_value}"}
      end)

    [from_image | docker_env] ++ rest_instructions
  end
end
