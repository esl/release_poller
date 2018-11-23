defmodule Domain.Services.DatabaseTest do
  use ExUnit.Case, async: true
  import Mox

  alias Domain.Services.Database
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
  alias Domain.Tasks.Task

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  setup do
    Application.put_env(:domain, :rpc_impl, Domain.Service.Local)
  end

  describe "get_all_repositories/0" do
    test "gets 0 repositories" do
      Domain.Service.Local
      |> expect(:get_all_repositories, fn -> [] end)

      assert {:ok, []} = Database.get_all_repositories()
    end

    test "gets all repositories" do
      Domain.Service.Local
      |> expect(:get_all_repositories, fn ->
        [
          %{
            polling_interval: 3600,
            repository_url: "https://github.com/elixir-lang/elixir",
            adapter: "github",
            github_token: nil
          }
        ]
      end)

      assert {:ok, [repo]} = Database.get_all_repositories()

      assert %Repo{
               polling_interval: 3_600_000,
               url: "https://github.com/elixir-lang/elixir"
             } = repo
    end

    test "error getting repositories" do
      Domain.Service.Local
      |> expect(:get_all_repositories, fn -> {:badrpc, :nodedown} end)

      assert {:error, :nodedown} = Database.get_all_repositories()
    end
  end

  describe "get_all_tags/1" do
    test "gets 0 tags" do
      Domain.Service.Local
      |> expect(:get_all_tags, fn _ -> [] end)

      assert {:ok, []} = Database.get_all_tags("url")
    end

    test "gets all repo tags" do
      Domain.Service.Local
      |> expect(:get_all_tags, fn _ ->
        [
          %{
            name: "v0.1",
            commit_sha: "c5b97d5ae6c19d5c5df71a34c7fbeeda2479ccbc",
            commit_url:
              "https://api.github.com/repos/octocat/Hello-World/commits/c5b97d5ae6c19d5c5df71a34c7fbeeda2479ccbc",
            tarball_url: "https://github.com/octocat/Hello-World/tarball/v0.1",
            zipball_url: "https://github.com/octocat/Hello-World/zipball/v0.1",
            node_id: ""
          }
        ]
      end)

      assert {:ok, [tag]} = Database.get_all_tags("url")

      assert %Tag{
               name: "v0.1",
               commit: %{
                 sha: "c5b97d5ae6c19d5c5df71a34c7fbeeda2479ccbc",
                 url:
                   "https://api.github.com/repos/octocat/Hello-World/commits/c5b97d5ae6c19d5c5df71a34c7fbeeda2479ccbc"
               },
               tarball_url: "https://github.com/octocat/Hello-World/tarball/v0.1",
               zipball_url: "https://github.com/octocat/Hello-World/zipball/v0.1",
               node_id: ""
             } = tag
    end

    test "error getting repo tags" do
      Domain.Service.Local
      |> expect(:get_all_tags, fn _ -> {:badrpc, :nodedown} end)

      assert {:error, :nodedown} = Database.get_all_tags("url")
    end
  end

  describe "create_tag/2" do
    test "creates task successfully" do
      Domain.Service.Local
      |> expect(:create_tag, fn _, _ ->
        {:ok, %{}}
      end)

      assert {:ok, %{}} = Database.create_tag("url", %Tag{name: "v1.6.6"})
    end

    test "error creating tag - badrpc" do
      Domain.Service.Local
      |> expect(:create_tag, fn _, _ -> {:badrpc, :nodedown} end)

      assert {:error, :nodedown} = Database.create_tag("url", %Tag{name: "v1.6.6"})
    end

    test "error creating tag - error" do
      Domain.Service.Local
      |> expect(:create_tag, fn _, _ -> {:error, :invalid} end)

      assert {:error, :invalid} = Database.create_tag("url", %Tag{name: "v1.6.6"})
    end
  end

  describe "get_repo_tasks/1" do
    test "get 0 tasks" do
      Domain.Service.Local
      |> expect(:get_repo_tasks, fn _ -> [] end)

      assert {:ok, []} = Database.get_repo_tasks("url")
    end

    test "get all repo tasks" do
      Domain.Service.Local
      |> expect(:get_repo_tasks, fn _ ->
        [
          %{
            id: 1,
            runner: "docker_build",
            source: nil,
            env: %{"USERNAME" => "kiro", "PASSWORD" => "qwerty12345"},
            fetch_url: nil,
            commands: [],
            build_file_content: "This is a test.",
            ssh_key: "this is a key",
            docker_username: nil,
            docker_email: nil,
            docker_password: nil,
            docker_servername: "https://index.docker.io/v1/",
            docker_image_name: "test"
          },
          %{
            id: 1,
            runner: "make",
            source: "github",
            env: %{},
            fetch_url: "https://github.com/f@k3/f@k3",
            commands: ["install", "build", "release"],
            build_file_content: nil,
            ssh_key: nil,
            docker_username: nil,
            docker_email: nil,
            docker_password: nil,
            docker_servername: "https://index.docker.io/v1/",
            docker_image_name: "test2"
          }
        ]
      end)

      assert {:ok, [task1, task2]} = Database.get_repo_tasks("url")

      assert %Task{
               id: 1,
               runner: Domain.Tasks.Runners.DockerBuild,
               env: env,
               build_file_content: "This is a test.",
               ssh_key: "this is a key"
             } = task1

      assert Enum.member?(env, {"PASSWORD", "qwerty12345"})
      assert Enum.member?(env, {"USERNAME", "kiro"})

      assert %Task{
               id: 1,
               runner: Domain.Tasks.Runners.Make,
               source: Domain.Tasks.Sources.Github,
               url: "https://github.com/f@k3/f@k3",
               commands: ["install", "build", "release"]
             } = task2
    end

    test "error getting repo tasks" do
      Domain.Service.Local
      |> expect(:get_repo_tasks, fn _ -> {:badrpc, :nodedown} end)

      assert {:error, :nodedown} = Database.get_repo_tasks("url")
    end
  end
end
