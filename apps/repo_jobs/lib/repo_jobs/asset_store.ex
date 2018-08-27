defmodule RepoJobs.AssetStore do
  def save(file_content, file_location) do
    with {:ok, file} <- File.open(file_location, [:write]),
         :ok <- IO.binwrite(file, file_content),
         :ok <- File.close(file) do
      {:ok, file_location}
    else
      error -> error
    end
  end

  def create_tmp_dir(parts) when is_list(parts) do
    create_tmp_dir(Path.join(parts))
  end

  def create_tmp_dir(dir_name) do
    # TODO: make configurable
    tmp_dir = System.tmp_dir!()

    new_tmp_dir = Path.join([tmp_dir, "TEST", dir_name])

    do_create_dir(new_tmp_dir)
  end

  def create_dir_for_path(path) do
    Path.dirname(path)
    |> do_create_dir()
  end

  def generate_file_path(dir, url) do
    %{path: path} = URI.parse(url)
    new_path = String.replace_leading(path, "/", "")
    Path.join([dir, new_path])
  end

  def exists?(path), do: File.exists?(path)

  def do_create_dir(dir_path) do
    case File.mkdir_p(dir_path) do
      :ok -> {:ok, dir_path}
      {:error, :eexist} -> {:ok, dir_path}
      {:error, _} = error -> error
    end
  end
end
