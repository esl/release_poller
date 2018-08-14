defmodule RepoPoller.PollerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias RepoPoller.Poller
  alias RepoPoller.Repository.GithubFake
  alias RepoPoller.Domain.Repo

  test "gets tags and re-schedule poll" do
    repo = Repo.new("https://github.com/elixir-lang/elixir")
    pid = start_supervised!({Poller, {repo, GithubFake, 0}})

    :erlang.trace(pid, true, [:receive])
    assert_receive {:trace, ^pid, :receive, :poll}
  end

  test "handles rate limite errors" do
    repo = Repo.new("https://github.com/rate-limit/fake")

    assert capture_log(fn ->
      pid = start_supervised!({Poller, {repo, GithubFake, :infinity}})
      # wait for the inital event to be processed
      :timer.sleep(50)
      :erlang.trace(pid, true, [:receive])
      # re-schedule poll from the rate-limit retry response
      assert_receive {:trace, ^pid, :receive, :poll}
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
      assert_receive {:trace, ^pid, :receive, :poll}
    end) =~ "error polling info for repo: fake reason: :not_found"
  end
end
