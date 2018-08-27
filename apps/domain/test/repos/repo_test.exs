defmodule RepoPoller.Domain.RepoTest do
  use ExUnit.Case, async: true

  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
  alias Domain.Scripts.Script

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

  test "set scripts" do
    scripts = [ %Script{url: "url"} ]
    assert %Repo{scripts: ^scripts} =
      Repo.new("https://github.com/jeremyjh/dialyxir")
      |> Repo.set_scripts(scripts)
  end
end
