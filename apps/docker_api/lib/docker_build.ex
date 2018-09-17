defmodule DockerApi.DockerBuild do
  require Logger

  @env ~r/^\s*(\w+)[\s=]+(.*)$/

  def build(instructions) do
    steps = length(instructions)

    instructions
    |> Enum.reduce({nil, 1}, fn {cmd, args} = instruction, {image_id, step} ->
      cmd = String.upcase(cmd)
      Logger.info("STEP #{step}/#{steps} : #{cmd} #{args}")
      new_image_id = exec(instruction, image_id)
      {new_image_id, step + 1}
    end)
  end

  defp exec({"ENV", args}, image_id) do
    # add support for both `ENV MIX_ENV prod` and `ENV MIX_ENV=prod`
    env = Regex.run(@env, args)
    unless env, do: raise("invalid env")
    DockerApi.create_layer(%{"Image" => image_id, "Env" => [Enum.join(env, "=")]})
  end

  defp exec({"RUN", command}, image_id) do
    DockerApi.create_layer(%{"Image" => image_id, "CMD" => String.split(command, " ")})
  end

  defp exec({"FROM", image}, _image_id) do
    [base_image | rest] = String.split(image)
    name =
      # support for `FROM elixir:latest as elixir` and `FROM elixir:latest`
      case rest do
        [] -> ""
        [as, container_name] when as in ["AS", "as"] -> container_name
      end

    DockerApi.pull(base_image)
    DockerApi.create_layer(%{"Image" => base_image, "ContainerName" => name}, false)
  end

  defp exec({"COPY", args}, image_id) do
  end

  defp exec({"WORKDIR", wd_path}, image_id) do
    DockerApi.create_layer(%{"Image" => image_id, "WorkingDir" => wd_path})
  end

  defp exec({"CMD", args}, image_id) do
  end

  defp exec({"ENTRYPOINT", args}, image_id) do
  end

  defp exec({"LABEL", args}, image_id) do
  end

  defp exec({"EXPOSE", args}, image_id) do
  end

  defp exec({"ARG", args}, image_id) do
  end
end
