defmodule Domain.Tasks.Runners.DockerBuildTest do
  use ExUnit.Case
  import Mimic

  alias Domain.Tasks.Runners.DockerBuild
  alias Domain.Tasks.Task

  @moduletag :integration

  @cwd System.cwd!()
  @file_path Path.join([@cwd, "myfile.txt"])

  setup :verify_on_exit!

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

    ExDockerBuild
    |> stub(:tag_image, fn _image_id, docker_image_repo, tag ->
      assert tag == "v1.0.0"
      assert docker_image_repo == "pepe/test"
      :ok
    end)
    |> stub(:push_image, fn docker_image_repo, tag, credentials ->
      assert credentials == %{docker_password: nil, docker_servername: nil, docker_username: "pepe"}
      assert tag == "v1.0.0"
      assert docker_image_repo == "pepe/test"
      :ok
    end)

    task = %Task{build_file_content: content, docker_image_name: "test", docker_username: "pepe"}

    assert :ok = DockerBuild.exec(task, [{"NO_TEST_EXTRA_ENV_TAG", "v1.0.0"}])
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

    ExDockerBuild
    |> stub(:tag_image, fn _image_id, docker_image_repo, tag ->
      assert tag == "v2.0.0"
      assert docker_image_repo == "pepe/test2"
      :ok
    end)
    |> stub(:push_image, fn docker_image_repo, tag, credentials ->
      assert credentials == %{docker_password: nil, docker_servername: nil, docker_username: "pepe"}
      assert tag == "v2.0.0"
      assert docker_image_repo == "pepe/test2"
      :ok
    end)

    task = %Task{build_file_content: content, docker_image_name: "test2", docker_username: "pepe"}

    assert :ok = DockerBuild.exec(task, [{"TEST_EXTRA_ENV_TAG", "v2.0.0"}, {"USERNAME", "kiro"}])
    assert File.exists?(@file_path)
    assert File.read!(@file_path) == "hello-world!!!! kiro\n"
  end

  # Silence DockerBuild logs
  @tag capture_log: true
  test "error pushing docker image" do
    content = """
    FROM alpine:latest
    VOLUME #{@cwd}:/data
    RUN echo "hello-world!!!! ${USERNAME}" > /data/myfile.txt
    CMD ["cat", "/data/myfile.txt"]
    """

    ExDockerBuild
    |> stub(:tag_image, fn _image_id, _docker_image_name, _tag ->
      :ok
    end)
    |> stub(:push_image, fn _docker_image_name, _tag, _credentials ->
      {:error, :kaboom}
    end)

    task = %Task{build_file_content: content, docker_image_name: "test2"}

    assert {:error, :kaboom} = DockerBuild.exec(task, [{"TEST_EXTRA_ENV_TAG", "v2.0.0"}])
    assert File.exists?(@file_path)
    assert File.read!(@file_path) == "hello-world!!!! \n"
  end
end
