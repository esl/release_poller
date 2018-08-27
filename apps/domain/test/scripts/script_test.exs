defmodule RepoPoller.Domain.ScriptTest do
  use ExUnit.Case, async: true

  alias Domain.Scripts.Script

  test "creates a new script" do
    make_url = "https://raw.githubusercontent.com/elixir-lang/elixir/master/Makefile"
    assert %Script{url: make_url} == Script.new(url: make_url)
  end
end
