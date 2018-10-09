defmodule Domain.Tasks.Runners.DockerBuildTest do
  use ExUnit.Case

  alias Domain.Tasks.Runners.DockerBuild
  alias Domain.Tasks.Task

  @moduletag :integration

  @cwd System.cwd!()
  @file_path Path.join([@cwd, "myfile.txt"])

  setup do
    on_exit(fn ->
      File.rm_rf!(@file_path)
    end)
  end

  # Silence DockerBuild logs
  @tag capture_log: true
  test "build dockerbuild file content" do
    content = """
    FROM alpine:latest
    VOLUME #{@cwd}:/data
    RUN echo "hello-world!!!!" > /data/myfile.txt
    CMD ["cat", "/data/myfile.txt"]
    """

    task = %Task{build_file_content: content}

    assert :ok = DockerBuild.exec(task, [])
    assert File.exists?(@file_path)
    assert File.read!(@file_path) == "hello-world!!!!\n"
  end

  # Silence DockerBuild logs
  @tag capture_log: true
  test "build dockerbuild file content injecting extra env" do
    content = """
    FROM alpine:latest
    VOLUME #{@cwd}:/data
    RUN echo "hello-world!!!! ${USERNAME}" > /data/myfile.txt
    CMD ["cat", "/data/myfile.txt"]
    """

    task = %Task{build_file_content: content}

    assert :ok = DockerBuild.exec(task, [{"USERNAME", "kiro"}])
    assert File.exists?(@file_path)
    assert File.read!(@file_path) == "hello-world!!!! kiro\n"
  end
end
