defmodule DockerApiTest do
  use ExUnit.Case
  doctest DockerApi

  test "greets the world" do
    assert DockerApi.hello() == :world
  end
end
