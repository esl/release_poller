defmodule BugsBunnyTest do
  use ExUnit.Case
  doctest BugsBunny

  test "greets the world" do
    assert BugsBunny.hello() == :world
  end
end
