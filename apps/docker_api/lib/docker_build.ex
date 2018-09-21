defmodule DockerApi.DockerBuild do
  require Logger

  @env ~r/^\s*(\w+)[\s=]+(.*)$/

  def build(instructions, path) do
    steps = length(instructions)

    instructions
    |> Enum.reduce({nil, 1}, fn {cmd, args}, {image_id, step} ->
      cmd = String.upcase(cmd)
      Logger.info("STEP #{step}/#{steps} : #{cmd} #{args}")
      new_image_id = exec({cmd, args}, image_id, path)
      {new_image_id, step + 1}
    end)
  end

  defp exec({"ENV", args}, image_id, _path) do
    # add support for both `ENV MIX_ENV prod` and `ENV MIX_ENV=prod`
    env = Regex.run(@env, args, capture: :all_but_first)
    unless env, do: raise("invalid env")
    DockerApi.create_layer(%{"Image" => image_id, "Env" => [Enum.join(env, "=")]})
  end

  defp exec({"RUN", command}, image_id, _path) do
    command =
      case parse_args(command) do
        {:shell_form, cmd} -> String.split(cmd, " ")
        {:exec_form, cmd} -> cmd
      end

    DockerApi.create_layer(%{"Image" => image_id, "CMD" => command}, wait: true)
  end

  defp exec({"FROM", image}, _image_id, _path) do
    [base_image | rest] = String.split(image)
    # support for `FROM elixir:latest as elixir` and `FROM elixir:latest`
    name =
      case rest do
        [] -> ""
        [as, container_name] when as in ["AS", "as"] -> container_name
      end

    DockerApi.pull(base_image)
    DockerApi.create_layer(%{"Image" => base_image, "ContainerName" => name})
  end

  defp exec({"COPY", args}, image_id, path) do
    [origin, dest] = String.split(args, " ")
    absolute_origin = [path, origin] |> Path.join() |> Path.expand()

    container_id =
      %{"Image" => image_id}
      |> DockerApi.create_container()
      |> DockerApi.start_container()

    new_image_id =
      DockerApi.upload_file(container_id, absolute_origin, dest)
      |> DockerApi.commit(%{})

    container_id
    |> DockerApi.stop_container()
    |> DockerApi.remove_container()

    new_image_id
  end

  defp exec({"WORKDIR", wd_path}, image_id, _path) do
    DockerApi.create_layer(%{"Image" => image_id, "WorkingDir" => wd_path})
  end

  defp exec({"CMD", command}, image_id, _path) do
    command =
      case parse_args(command) do
        {:shell_form, cmd} -> String.split(cmd, " ")
        {:exec_form, cmd} -> cmd
      end

    DockerApi.create_layer(%{"Image" => image_id, "CMD" => command})
  end

  defp exec({"ENTRYPOINT", command}, image_id, _path) do
    command =
      case parse_args(command) do
        {:shell_form, cmd} -> String.split(cmd, " ")
        {:exec_form, cmd} -> cmd
      end

    DockerApi.create_layer(%{"Image" => image_id, "ENTRYPOINT" => command})
  end

  defp exec({"LABEL", args}, image_id, _path) do
  end

  defp exec({"EXPOSE", args}, image_id, _path) do
  end

  defp exec({"ARG", args}, image_id, _path) do
  end

  # parse instruction arguments as shell form `CMD command param1 param2` and
  # as exec form `CMD ["executable","param1","param2"]` or JSON Array form
  defp parse_args(args) do
    case Poison.decode(args) do
      {:error, _error} -> {:shell_form, args}
      {:ok, value} -> {:exec_form, value}
    end
  end
end
