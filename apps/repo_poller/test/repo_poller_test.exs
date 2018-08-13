defmodule RepoPollerTest do
  use ExUnit.Case
  doctest RepoPoller

  test "greets the world" do
    assert RepoPoller.hello() == :world
  end
end
