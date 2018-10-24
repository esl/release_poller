defmodule Domain.Repos.RepoTest do
  use ExUnit.Case, async: true

  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
  alias Domain.Tasks.Task

  test "creates a new repo" do
    assert %Repo{
             id: 1,
             name: "dialyxir",
             owner: "jeremyjh",
             url: "https://github.com/jeremyjh/dialyxir",
             polling_interval: 3_600_000
           } == Repo.new(1, "https://github.com/jeremyjh/dialyxir")
  end

  test "creates a new repo with interval" do
    assert %Repo{polling_interval: 60_000} =
             Repo.new(1, "https://github.com/jeremyjh/dialyxir", 60)
  end

  test "add tags" do
    tags = [%Tag{name: "v1.7.2"}]

    assert %Repo{tags: ^tags} =
             Repo.new(1, "https://github.com/jeremyjh/dialyxir")
             |> Repo.add_tags(tags)
  end

  test "new tags are prepended to repo tags" do
    tags = [%Tag{name: "v1"}]
    new_tags = [%Tag{name: "v2"}, %Tag{name: "v3"}, %Tag{name: "v4"}]

    %Repo{tags: all_tags} =
      Repo.new(1, "https://github.com/jeremyjh/dialyxir")
      |> Repo.add_tags(tags)
      |> Repo.add_tags(new_tags)

    assert all_tags == new_tags ++ tags
  end

  test "add tasks" do
    tasks = [%Task{url: "url"}]

    assert %Repo{tasks: ^tasks} =
             Repo.new(1, "https://github.com/jeremyjh/dialyxir")
             |> Repo.set_tasks(tasks)
  end

  test "uniqe names" do
    assert Repo.new(1, "https://github.com/jeremyjh/dialyxir")
           |> Repo.uniq_name() == "jeremyjh/dialyxir"
  end
end
