defmodule Domain.Tasks.Sources.Github do
  alias Domain.Tasks.Sources.Source
  @behaviour Source

  alias Domain.Tasks.Helpers.TempStore

  @impl true
  def fetch(%{url: url} = task, base_dir) do
    # url: https://github.com/elixir-lang/elixir
    # dest_path: /tmp/erlang/otp/-21.0.2/elixir-lang/elixir
    dest_path = TempStore.generate_destination_path(base_dir, url)

    # remove repositories already cloned, this may happen if we want to re run some job
    # handles "already exists and is not an empty directory."
    if File.exists?(dest_path) do
      File.rm_rf!(dest_path)
    end

    case clone(url, dest_path) do
      :ok ->
        {:ok, %{task | path: dest_path}}

      {:error, _} = error ->
        error
    end
  end

  defp clone(repo_url, dest_path) do
    opts = [
      env: [],
      stderr_to_stdout: true,
      into: IO.stream(:stdio, :line)
    ]

    System.cmd("git", ["clone", repo_url, "--depth=1", dest_path], opts)
    |> case do
      {_, 0} ->
        :ok

      error ->
        {:error, error}
    end
  end
end
