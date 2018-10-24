defmodule RepoPoller.Integration.GithubTest do
  use ExUnit.Case, async: true

  alias RepoPoller.Repository.Github
  alias Domain.Repos.Repo

  @moduletag :integration

  # flaky test: due to rate limiting from github, so we need to ensure we rather success
  # or we ware rate-limited
  test "fetch all tags from repo" do
    :rand.uniform(1_000_000)
    |> Repo.new("https://github.com/elixir-lang/elixir")
    |> Github.get_tags()
    |> case do
      {:ok, tags} ->
        refute Enum.empty?(tags)
        assert Enum.find(tags, &(&1.name == "v1.7.2"))
        assert Enum.find(tags, &(&1.name == "v1.0.0"))

      {:error, :rate_limit, retry_in_seconds} ->
        assert retry_in_seconds > 0
    end
  end
end
