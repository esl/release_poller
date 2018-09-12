defmodule DockerApi.DockerfileParser do
  @comment ~r/^\s*#/
  @continuation ~r/^.*\\\s*$/
  @instruction ~r/^\s*(\w+)\s+(.*)$/

  def parse(path) do
    {parsed_lines, _} =
      File.read!(path)
      |> String.split("\n")
      |> Enum.reduce({[], false}, fn line, {acc, continuation?} ->
        case parse_line(line, continuation?) do
          nil ->
            {acc, continuation?}

          {:continue, _} = result ->
            {[result | acc], true}

          {:end, _} = result ->
            {[result | acc], false}
        end
      end)

    parsed_lines
    |> Enum.reverse()
    |> join_lines()
  end

  defp parse_line(line, continuation?) do
    line = String.trim(line)

    cond do
      line == "" || Regex.match?(@comment, line) ->
        nil

      continuation? ->
        if Regex.match?(@continuation, line) do
          {:continue, String.slice(line, 0..-2)}
        else
          {:end, line}
        end

      true ->
        # line: "RUN set -xe \\"
        [_instruction, command, value] = Regex.run(@instruction, line)
        # ["RUN set -xe \\", "RUN", "set -xe \\"]
        if Regex.match?(@continuation, line) do
          # remove trailing continuation (\)
          {:continue, {command, String.slice(value, 0..-2)}}
        else
          {:end, {command, value}}
        end
    end
  end

  # example
  # [
  #   {:continue, "hola"},
  #   {:continue, "como"},
  #   {:end, "estas"},
  #   {:continue, "bien"},
  #   {:end, "gracias"},
  #   {:end, "chao"}
  # ] |> Enum.reduce([], fn
  #   {:continue, _} = val, [] ->
  #     [val]
  #   {:continue, val}, [{:continue, prev} | rest] ->
  #     [{:continue, prev <> val} | rest]
  #   {:continue, _} = val, acc ->
  #     [val | acc]
  #   {:end, val}, [] ->
  #     [val]
  #   {:end, val}, [{:continue, prev} | rest] ->
  #     [prev <> val | rest]
  #   {:end, val}, acc ->
  #     [val | acc]
  # end)
  defp join_lines(lines) do
    lines
    |> Enum.reduce([], &do_join/2)
    |> Enum.reverse()
  end

  # nil line (comment/empty line)
  defp do_join(nil, acc) do
    acc
  end

  # first line - accomulator empty
  defp do_join({:continue, _} = val, []) do
    [val]
  end

  # a continuation of a previous continuation - need to join lines
  defp do_join({:continue, val}, [{:continue, {prev_command, prev_value}} | rest]) do
    [{:continue, {prev_command, prev_value <> " " <> val}} | rest]
  end

  # a new continuation - other continuation already finished
  defp do_join({:continue, _} = val, acc) do
    [val | acc]
  end

  # first line - single instruction
  defp do_join({:end, val}, []) do
    [val]
  end

  # the end of a continuation
  defp do_join({:end, val}, [{:continue, {prev_command, prev_value}} | rest]) do
    [{prev_command, prev_value <> " " <> val} | rest]
  end

  # single instruction
  defp do_join({:end, val}, acc) do
    [val | acc]
  end
end
