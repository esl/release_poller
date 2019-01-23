defmodule Domain.Helpers.TupleTest do
  use ExUnit.Case, async: false

  test "encodes tuple into list" do
    assert "[\"KEY\",\"VALUE\"]" == Poison.encode!({"KEY", "VALUE"})
  end
end
