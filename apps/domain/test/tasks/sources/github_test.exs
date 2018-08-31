defmodule Domain.Tasks.Sources.GithubTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Domain.Tasks.Task
  alias Domain.Tasks.Sources.Github

  @moduletag :integration
  @repo_url "https://github.com/elixir-lang/elixir"

  setup do
    n = :rand.uniform(100)
    # create random directory so it can run concurrently
    base_dir = Path.join([System.cwd!(), "test", "fixtures", "sources", to_string(n)])

    on_exit(fn ->
      File.rm_rf!(base_dir)
    end)

    {:ok, base_dir: base_dir}
  end

  test "clones a repo", %{base_dir: base_dir} do
    capture_io(fn ->
      task = %Task{url: @repo_url}
      assert {:ok, new_task} = Github.fetch(task, base_dir)
      %Task{path: path} = new_task
      assert path =~ Path.join([base_dir, "elixir-lang/elixir"])
      refute path |> File.ls!() |> Enum.empty?()
    end)
  end

  test "deletes previusly downloaded dir", %{base_dir: base_dir} do
    capture_io(fn ->
      exisiting_dir = Path.join([base_dir, "elixir-lang/elixir", "to_be_removed"])
      :ok = exisiting_dir |> File.mkdir_p!()
      task = %Task{url: @repo_url}
      assert {:ok, new_task} = Github.fetch(task, base_dir)
      %Task{path: path} = new_task
      refute File.dir?(exisiting_dir)
      refute path |> File.ls!() |> Enum.empty?()
    end)
  end

  test "returns error tupe if there was an error", %{base_dir: base_dir} do
    output =
      capture_io(fn ->
        task = %Task{url: "https://github.com/F@K3/elixir"}
        assert {:error, error} = Github.fetch(task, base_dir)
        # 128 means git clone failed
        assert {%IO.Stream{}, 128} = error
      end)

    assert output =~
             "fatal: unable to access 'https://github.com/F@K3/elixir/': The requested URL returned error: 400"
  end
end
