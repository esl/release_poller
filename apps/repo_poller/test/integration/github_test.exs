defmodule RepoPoller.Integration.GithubTest do
  use ExUnit.Case, async: true

  alias RepoPoller.Repository.Github
  alias RepoPoller.Domain.Repo


  @moduletag :integration

  test "fetch all tags from repo" do
    {:ok, tags} =
      Repo.new("https://github.com/elixir-lang/elixir")
      |> Github.get_tags()

    refute Enum.empty?(tags)

    assert Enum.find(tags, & &1.name == "v1.7.2")
    assert Enum.find(tags, & &1.name == "v1.0.0")
  end
end
