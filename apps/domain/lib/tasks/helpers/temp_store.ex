defmodule Domain.Tasks.Helpers.TempStore do
  @spec create_tmp_dir(list(String.t())) :: {:ok, Path.t()} | {:error, File.posix()}
  def create_tmp_dir(parts) when is_list(parts) do
    # TODO: make configurable
    tmp_dir = System.tmp_dir!()
    dir_name = Path.join(parts)

    dir_path = Path.join([tmp_dir, "TEST", dir_name])

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
