defmodule Domain.Tasks.TaskTest do
  use ExUnit.Case, async: true

  alias Domain.Tasks.Task
  alias Domain.Tasks.Runners.Make
  alias Domain.Tasks.Sources.Github

  test "creates a new task" do
    make_url = "https://github.com/elixir-lang/elixir"
    assert %Task{url: make_url, source: Github, runner: Make} == Task.new(url: make_url)
  end

  test "expands build_file" do
    content = "This Is A Test"
    build_file = Path.join([System.cwd!(), "test", "fixtures", "buildfile_test"])
    File.write!(build_file, content)

    on_exit(fn ->
      File.rm!(build_file)
    end)

    assert %{build_file_content: ^content} = Task.new(build_file: build_file)
  end
end
