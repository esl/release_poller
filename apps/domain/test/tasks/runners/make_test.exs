defmodule Domain.Tasks.Runners.MakeTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Domain.Tasks.Task
  alias Domain.Tasks.Runners.Make

  @moduletag :integration

  setup do
    n = :rand.uniform(100)
    # create random directory so it can run concurrently
    base_dir = Path.join([System.cwd!(), "test", "fixtures", "runners", to_string(n)])
    File.mkdir_p!(base_dir)

    on_exit(fn ->
      File.rm_rf!(base_dir)
    end)

    {:ok, base_dir: base_dir}
  end

  test "runs default Makefile command", %{base_dir: base_dir} do
    Path.join([base_dir, "Makefile"])
    |> File.write!("""
    target:
    \t@echo "hello"
    """)

    task = %Task{path: base_dir}

    output =
      capture_io(fn ->
        assert :ok = Make.exec(task, [])
      end)

    assert output =~ "hello"
  end

  test "runs custom Makefile command", %{base_dir: base_dir} do
    Path.join([base_dir, "Makefile"])
    |> File.write!("""
    target:
    \t@echo "target"
    build:
    \t@echo "build"
    """)

    task = %Task{path: base_dir, commands: ["build"]}

    output =
      capture_io(fn ->
        assert :ok = Make.exec(task, [])
      end)

    assert output =~ "build"
  end

  test "run multiple Makefile commands", %{base_dir: base_dir} do
    Path.join([base_dir, "Makefile"])
    |> File.write!("""
    target:
    \t@echo "target"
    build:
    \t@echo "build"
    release:
    \t@echo "release done"
    """)

    task = %Task{path: base_dir, commands: ["build", "release"]}

    output =
      capture_io(fn ->
        assert :ok = Make.exec(task, [])
      end)

    assert output =~ "build"
    assert output =~ "release done"
  end

  test "return error tupe if there was an error in default command", %{base_dir: base_dir} do
    Path.join([base_dir, "Makefile"])
    |> File.write!("""
    target:
    \t$(error something went wrong)
    """)

    task = %Task{path: base_dir}

    output =
      capture_io(fn ->
        assert {:error, error} = Make.exec(task, [])
        assert {_, 2} = error
      end)

    assert output =~ "something went wrong"
  end

  test "return error tupe if there was an error in one of multiple commands", %{
    base_dir: base_dir
  } do
    Path.join([base_dir, "Makefile"])
    |> File.write!("""
    build:
    \t@echo "build project"
    release:
    \t$(error something went wrong)
    deploy:
    \t@echo "deploy to production"
    """)

    task = %Task{path: base_dir, commands: ["build", "release", "deploy"]}

    output =
      capture_io(fn ->
        assert {:error, error} = Make.exec(task, [])
        assert {_, 2} = error
      end)

    assert output =~ "build project"
    assert output =~ "something went wrong"
    refute output =~ "deploy to production"
  end
end
