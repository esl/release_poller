defmodule Domain.Tasks.Runners.MakeTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Domain.Tasks.Task
  alias Domain.Tasks.Runners.Make

  @moduletag :integration

  @base_dir Path.join([System.cwd!(), "test", "fixtures", "runners"])

  setup do
    on_exit(fn ->
      in_fixture(fn -> File.rm_rf!("Makefile") end)
    end)

    :ok
  end

  test "runs default Makefile command" do
    in_fixture(fn ->
      File.write!("Makefile", """
      target:
      \t@echo "hello"
      """)

      task = %Task{path: @base_dir}

      output =
        capture_io(fn ->
          assert :ok = Make.exec(task, [])
        end)

      assert output =~ "hello"
    end)
  end

  test "runs custom Makefile command" do
    in_fixture(fn ->
      File.write!("Makefile", """
      target:
      \t@echo "target"
      build:
      \t@echo "build"
      """)

      task = %Task{path: @base_dir, commands: ["build"]}

      output =
        capture_io(fn ->
          assert :ok = Make.exec(task, [])
        end)

      assert output =~ "build"
    end)
  end

  test "run multiple Makefile commands" do
    in_fixture(fn ->
      File.write!("Makefile", """
      target:
      \t@echo "target"
      build:
      \t@echo "build"
      release:
      \t@echo "release done"
      """)

      task = %Task{path: @base_dir, commands: ["build", "release"]}

      output =
        capture_io(fn ->
          assert :ok = Make.exec(task, [])
        end)

      assert output =~ "build"
      assert output =~ "release done"
    end)
  end

  test "return error tupe if there was an error in default command" do
    in_fixture(fn ->
      File.write!("Makefile", """
      target:
      \t$(error something went wrong)
      """)

      task = %Task{path: @base_dir}

      output =
        capture_io(fn ->
          assert {:error, error} = Make.exec(task, [])
          assert {_, 2} = error
        end)

      assert output =~ "something went wrong"
    end)
  end

  test "return error tupe if there was an error in one of multiple commands" do
    in_fixture(fn ->
      File.write!("Makefile", """
      build:
      \t@echo "build project"
      release:
      \t$(error something went wrong)
      deploy:
      \t@echo "deploy to production"
      """)

      task = %Task{path: @base_dir, commands: ["build", "release", "deploy"]}

      output =
        capture_io(fn ->
          assert {:error, error} = Make.exec(task, [])
          assert {_, 2} = error
        end)

      assert output =~ "build project"
      assert output =~ "something went wrong"
      refute output =~ "deploy to production"
    end)
  end

  defp in_fixture(fun) do
    File.cd!(@base_dir, fun)
  end
end
