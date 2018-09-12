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
            {join(result, acc), true}

          {:end, _} = result ->
            {join(result, acc), false}
        end
      end)

    parsed_lines
    |> Enum.reverse()
  end

  defp parse_line(line, continuation?) do
    line = String.trim(line)

    cond do
      line == "" || Regex.match?(@comment, line) ->
        nil

      # continuation are not instructions
      continuation? ->
        if Regex.match?(@continuation, line) do
          # remove trailing continuation (\)
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

  # nil line (comment/empty line)
  defp join(nil, acc) do
    acc
  end

  # first line - accomulator empty
  defp join({:continue, _} = val, []) do
    [val]
  end

  # a continuation of a previous continuation - need to join lines
  defp join({:continue, val}, [{:continue, {prev_command, prev_value}} | rest]) do
    [{:continue, {prev_command, prev_value <> " " <> val}} | rest]
  end

  # a new continuation - other continuation already finished
  defp join({:continue, _} = val, acc) do
    [val | acc]
  end

  # first line - single instruction
  defp join({:end, val}, []) do
    [val]
  end

  # the end of a continuation
  defp join({:end, val}, [{:continue, {prev_command, prev_value}} | rest]) do
    [{prev_command, prev_value <> " " <> val} | rest]
  end

  # single instruction
  defp join({:end, val}, acc) do
    [val | acc]
  end
end
