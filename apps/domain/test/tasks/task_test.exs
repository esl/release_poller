defmodule RepoPoller.Domain.TaskTest do
  use ExUnit.Case, async: true

  alias Domain.Tasks.Task

  test "creates a new task" do
    make_url = "https://raw.githubusercontent.com/elixir-lang/elixir/master/Makefile"
    assert %Task{url: make_url} == Task.new(url: make_url)
  end
end
