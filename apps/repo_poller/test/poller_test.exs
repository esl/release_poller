defmodule RepoPoller.PollerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias RepoPoller.Poller
  alias RepoPoller.Repository.GithubFake
  alias RepoPoller.Domain.{Repo, Tag}
  alias RepoPoller.DB

  setup do
    DB.clear()

    on_exit(fn ->
      DB.clear()
    end)
  end

  test "gets tags and re-schedule poll" do
    repo = Repo.new("https://github.com/elixir-lang/elixir")
    pid = start_supervised!({Poller, {repo, GithubFake, 0}})

    :erlang.trace(pid, true, [:receive])
    assert_receive {:trace, ^pid, :receive, :poll}
  end

  test "gets repo tags and store them" do
    repo = Repo.new("https://github.com/elixir-lang/elixir")
    pid = start_supervised!({Poller, {repo, GithubFake, 5_000}})
    # wait for the inital event to be processed
    :timer.sleep(50)
    tags = DB.get_tags(repo)
    refute Enum.empty?(tags)
    %{repo: %{tags: state_tags}} = :sys.get_state(pid)
    assert state_tags == tags
  end

  test "gets repo tags and update them" do
    repo =
      Repo.new("https://github.com/elixir-lang/elixir")
      |> Repo.set_tags([
        %Tag{name: "v1.6.6"},
        %Tag{name: "v1.6.5"},
        %Tag{name: "v1.6.4"},
        %Tag{name: "v1.6.3"},
        %Tag{name: "v1.6.2"},
        %Tag{name: "v1.6.1"},
        %Tag{name: "v1.6.0"},
        %Tag{name: "v1.6.0-rc.1"},
        %Tag{name: "v1.6.0-rc.0"}
      ])

    DB.save(repo)
    pid = start_supervised!({Poller, {repo, GithubFake, 5_000}})
    # wait for the inital event to be processed
    :timer.sleep(50)
    tags = DB.get_tags(repo)
    assert length(tags) == 21
    %{repo: %{tags: state_tags}} = :sys.get_state(pid)
    assert state_tags == tags
  end

  test "handles rate limite errors" do
    repo = Repo.new("https://github.com/rate-limit/fake")

    assert capture_log(fn ->
             pid = start_supervised!({Poller, {repo, GithubFake, :infinity}})
             # wait for the inital event to be processed
             :timer.sleep(50)
             :erlang.trace(pid, true, [:receive])
             # re-schedule poll from the rate-limit retry response
             assert_receive {:trace, ^pid, :receive, :poll}, 500
           end) =~ "rate limit reached for repo: fake retrying in 50 ms"
  end

  test "handles errors when polling fails due to a custom error" do
    repo = Repo.new("https://github.com/404/fake")

    assert capture_log(fn ->
             pid = start_supervised!({Poller, {repo, GithubFake, 50}})
             # wait for the inital event to be processed
             :timer.sleep(50)
             :erlang.trace(pid, true, [:receive])
             # re-schedule poll from the repo interval
             assert_receive {:trace, ^pid, :receive, :poll}, 500
           end) =~ "error polling info for repo: fake reason: :not_found"
  end
end
