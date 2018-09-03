defmodule Domain.Tasks.Helpers.TempStore do
  @tmp_dir System.tmp_dir!()

  @spec create_tmp_dir(list(String.t()), Path.t()) ::
          {:ok, Path.t()} | {:error, File.posix()} | no_return()
  def create_tmp_dir(parts, tmp_dir \\ @tmp_dir) when is_list(parts) do
    dir_path = Path.join([tmp_dir | parts])

    dir_path
    |> File.mkdir_p()
    |> case do
      :ok -> {:ok, dir_path}
      {:error, :eexist} -> {:ok, dir_path}
      {:error, _} = error -> error
    end
  end

  @spec generate_destination_path(Path.t(), String.t()) :: Path.t()
  def generate_destination_path(dir, url) do
    %{path: path} = URI.parse(url)
    new_path = String.replace_leading(path, "/", "")
    Path.join([dir, new_path])
  end
end
