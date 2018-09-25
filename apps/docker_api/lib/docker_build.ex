defmodule DockerApi.DockerBuild do
  require Logger

  @env ~r/^\s*(\w+)[\s=]+(.*)$/

  alias DockerApi.Utils.Map, as: MapUtils

  def build(instructions, path) do
    steps = length(instructions)

    instructions
    |> Enum.reduce({%{}, 1}, fn {cmd, args}, {context, step} ->
      cmd = String.upcase(cmd)
      Logger.info("STEP #{step}/#{steps} : #{cmd} #{args}")

      case exec({cmd, args}, context, path) do
        new_image_id when is_binary(new_image_id) ->
          {Map.put(context, "Image", new_image_id), step + 1}

        new_ctx when is_map(new_ctx) ->
          {new_ctx, step + 1}
      end
    end)
  end

  defp exec({"ENV", args}, context, _path) do
    # add support for both `ENV MIX_ENV prod` and `ENV MIX_ENV=prod`
    env = Regex.run(@env, args, capture: :all_but_first)
    unless env, do: raise("invalid env")

    Map.merge(context, %{"Env" => [Enum.join(env, "=")]})
    |> DockerApi.create_layer()
  end

  defp exec({"RUN", command}, context, _path) do
    command =
      case parse_args(command) do
        {:shell_form, cmd} ->
          ["/bin/sh", "-c", command]

        {:exec_form, cmd} ->
          ["/bin/sh", "-c" | cmd]
      end

    Map.merge(context, %{"CMD" => command})
    |> DockerApi.create_layer(wait: true)
  end

  defp exec({"FROM", image}, context, _path) do
    [base_image | rest] = String.split(image)
    # support for `FROM elixir:latest as elixir` and `FROM elixir:latest`
    name =
      case rest do
        [] -> ""
        [as, container_name] when as in ["AS", "as"] -> container_name
      end

    DockerApi.pull(base_image)

    Map.merge(context, %{"Image" => base_image, "ContainerName" => name})
    |> DockerApi.create_layer()
  end

  defp exec({"COPY", args}, context, path) do
    [origin, dest] = String.split(args, " ")
    absolute_origin = [path, origin] |> Path.join() |> Path.expand()

    container_id =
      context
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

  defp exec({"WORKDIR", wd_path}, context, _path) do
    Map.merge(context, %{"WorkingDir" => wd_path})
    |> DockerApi.create_layer()
  end

  defp exec({"CMD", command}, context, _path) do
    command =
      case parse_args(command) do
        {:shell_form, cmd} -> String.split(cmd, " ")
        {:exec_form, cmd} -> cmd
      end

    Map.merge(context, %{"CMD" => command})
    |> DockerApi.create_layer()
  end

  defp exec({"ENTRYPOINT", command}, context, _path) do
    command =
      case parse_args(command) do
        {:shell_form, cmd} -> String.split(cmd, " ")
        {:exec_form, cmd} -> cmd
      end

    Map.merge(context, %{"ENTRYPOINT" => command})
    |> DockerApi.create_layer()
  end

  defp exec({"LABEL", args}, context, _path) do
  end

  defp exec({"EXPOSE", args}, context, _path) do
  end

  defp exec({"ARG", args}, context, _path) do
  end

  defp exec({"VOLUME", args}, context, _path) do
    String.split(args, ":")
    |> case do
      [_volume] ->
        throw("Only Bind Mounts are Supported")

      [_src, _dst] ->
        mounts = %{
          "HostConfig" => %{
            "Binds" => [args]
          }
        }

        new_image_id =
          Map.merge(context, mounts)
          |> DockerApi.create_layer()

        new_ctx =
          %{"Image" => new_image_id}
          |> Map.merge(mounts)

        MapUtils.contextual_merge(context, new_ctx)
    end
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
