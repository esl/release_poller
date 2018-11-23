defmodule Domain.Tasks.Runners.DockerBuild do
  @behaviour Domain.Tasks.Runners.Runner

  alias ExDockerBuild.{DockerfileParser, DockerBuild}
  alias Domain.Tasks.Task

  @impl true
  def exec(task, env) do
    %{
      build_file_content: build_file_content,
      env: extra_env,
      docker_image_name: docker_image_name
    } = task

    credentials = Task.get_docker_credentials(task)

    # TODO: eval template for "templating" a string
    # https://stackoverflow.com/questions/44340438/how-to-create-a-string-template-some-string-some-stub-var
    {_, tag} =
      Enum.find(env, fn {key, _value} ->
        String.ends_with?(key, "_TAG")
      end)

    result =
      DockerfileParser.parse_content!(build_file_content)
      |> inject_env(extra_env ++ env)
      |> DockerBuild.build("")

    with {:ok, image_id} <- result,
         :ok <- ExDockerBuild.tag_image(image_id, docker_image_name, tag, credentials),
         :ok <- ExDockerBuild.push_image(docker_image_name, tag, credentials) do
      :ok
    else
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
