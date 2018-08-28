defmodule RepoPoller.Domain.RepoTest do
  use ExUnit.Case, async: true

  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
  alias Domain.Tasks.Task

  test "creates a new repo" do
    assert %Repo{name: "dialyxir", owner: "jeremyjh"} ==
             Repo.new("https://github.com/jeremyjh/dialyxir")
  end

  test "set tags" do
    tags = [ %Tag{name: "v1.7.2"} ]
    assert %Repo{tags: ^tags} =
      Repo.new("https://github.com/jeremyjh/dialyxir")
      |> Repo.set_tags(tags)
  end

  test "set tasks" do
    tasks = [ %Task{url: "url"} ]
    assert %Repo{tasks: ^tasks} =
      Repo.new("https://github.com/jeremyjh/dialyxir")
      |> Repo.set_tasks(tasks)
  end
end
