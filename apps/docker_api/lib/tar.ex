defmodule DockerApi.Tar do
  def tar(input_path, output_path) do
    if File.dir?(input_path) do
      tar_dir(input_path, output_path)
    else
      tar_file(input_path, output_path)
    end
  end

  defp tar_dir(input_path, output_path) do
    files =
      input_path
      |> File.ls!()
      |> Enum.filter(&(!String.starts_with?(&1, ".git")))

    File.cd!(input_path, fn ->
      filename = Path.basename(input_path)
      destination_path = Path.join([output_path, "#{filename}.tar"])
      do_tar(files, destination_path)
    end)
  end

  defp tar_file(input_path, output_path) do
    Path.dirname(input_path)
    |> File.cd!(fn ->
      filename = Path.basename(input_path)
      destination_path = Path.join([output_path, "#{filename}.tar"])
      do_tar(filename, destination_path)
    end)
  end

  defp do_tar(files, destination_path) when is_list(files) do
    files = Enum.map(files, &to_charlist/1)
    :erl_tar.create(destination_path, files)
    destination_path
  end

  defp do_tar(file, destination_path) do
    do_tar([file], destination_path)
  end
end
