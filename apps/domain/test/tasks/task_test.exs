defmodule Domain.Tasks.TaskTest do
  use ExUnit.Case, async: false

  alias Domain.Tasks.Task
  alias Domain.Tasks.Runners.Make
  alias Domain.Tasks.Sources.Github

  test "creates a new task" do
    make_url = "https://github.com/elixir-lang/elixir"
    assert %Task{url: make_url, source: Github, runner: Make} == Task.new(url: make_url)
  end
end
