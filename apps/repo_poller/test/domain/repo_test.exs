defmodule RepoPoller.Domain.RepoTest do
  use ExUnit.Case, async: true

  alias RepoPoller.Domain.Repo

  test "creates a new repo" do
    assert %Repo{name: "dialyxir", owner: "jeremyjh"} ==
             Repo.new("https://github.com/jeremyjh/dialyxir")
  end
end
