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

  # TODOL: change this fake adapter to not depend on RabbitMQ
  # based on this: http://tech.adroll.com/blog/dev/2018/03/28/elixir-stubs-for-tests.html
  defmodule FakeRabbitMQ do
    @behaviour BugsBunny.Clients.Adapter
    use AMQP

    @impl true
    def publish(_channel, _exchange, _routing_key, _payload, _options \\ []) do
      :ok
    end

    @impl true
    def consume(_channel, _queue, _consumer_pid \\ nil, _options \\ []) do
      {:ok, ""}
    end

    @impl true
    def open_connection(_config) do
      # Connection.open(config)
      {:ok, %Connection{pid: self()}}
    end

    @impl true
    def open_channel(conn) do
      # Channel.open(conn)
      {:ok, %Channel{conn: conn, pid: self()}}
    end

    @impl true
    def close_connection(_conn) do
      #  Connection.close(conn)
      :ok
    end
  end

  setup do
    n = :rand.uniform(100)
    pool_id = String.to_atom("test_pool#{n}")
    caller = self()

    rabbitmq_config = [
      channels: 1,
      queue: "new_releases.queue",
      exchange: "",
      client: FakeRabbitMQ,
      caller: caller
    ]

    rabbitmq_conn_pool = [
      :repo_poller,
      :rabbitmq_conn_pool,
      pool_id: pool_id,
      name: {:local, pool_id},
      worker_module: BugsBunny.Worker.RabbitConnection,
      size: 1,
      max_overflow: 0
    ]

    Application.put_env(:repo_poller, :rabbitmq_config, rabbitmq_config)

    start_supervised!(%{
      id: BugsBunny.PoolSupervisorTest,
      start:
        {BugsBunny.PoolSupervisor, :start_link,
         [
           [rabbitmq_config: rabbitmq_config, rabbitmq_conn_pool: rabbitmq_conn_pool],
           BugsBunny.PoolSupervisorTest
         ]},
      type: :supervisor
    })

    {:ok, pool_id: pool_id}
  end

  test "gets tags and re-schedule poll", %{pool_id: pool_id} do
    repo = Repo.new("https://github.com/elixir-lang/elixir")
    pid = start_supervised!({Poller, {self(), repo, GithubFake, pool_id, 50}})
    Poller.poll(pid)
    assert_receive {:ok, tags}, 200
    assert_receive {:ok, ^tags}
  end

  test "gets repo tags and store them", %{pool_id: pool_id} do
    repo = Repo.new("https://github.com/elixir-lang/elixir")
    pid = start_supervised!({Poller, {self(), repo, GithubFake, pool_id, 5_000}})
    Poller.poll(pid)
    assert_receive {:ok, _tags}, 200
    tags = DB.get_tags(repo)
    refute Enum.empty?(tags)
    %{repo: %{tags: state_tags}} = Poller.state(pid)
    assert state_tags == tags
  end

  test "gets repo tags and update them", %{pool_id: pool_id} do
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

    :ok = DB.save(repo)
    pid = start_supervised!({Poller, {self(), repo, GithubFake, pool_id, 5_000}})
    Poller.poll(pid)
    assert_receive {:ok, _tags}, 200
    tags = DB.get_tags(repo)
    assert length(tags) == 21
    %{repo: %{tags: state_tags}} = Poller.state(pid)
    assert state_tags == tags
  end

  test "handles rate limit errors", %{pool_id: pool_id} do
    repo = Repo.new("https://github.com/rate-limit/fake")

    assert capture_log(fn ->
             pid = start_supervised!({Poller, {self(), repo, GithubFake, pool_id, 5_000}})
             Poller.poll(pid)
             assert_receive {:error, :rate_limit, retry}
             assert retry > 0
           end) =~ "rate limit reached for repo: fake retrying in 50 ms"
  end

  test "re-schedule poll after rate limit errors", %{pool_id: pool_id} do
    repo = Repo.new("https://github.com/rate-limit/fake")

    assert capture_log(fn ->
             pid = start_supervised!({Poller, {self(), repo, GithubFake, pool_id, 50}})
             Poller.poll(pid)
             assert_receive {:error, :rate_limit, retry}
             assert_receive {:error, :rate_limit, ^retry}
           end) =~ "rate limit reached for repo: fake retrying in 50 ms"
  end

  test "handles errors when polling fails due to a custom error", %{pool_id: pool_id} do
    repo = Repo.new("https://github.com/404/fake")

    assert capture_log(fn ->
             pid = start_supervised!({Poller, {self(), repo, GithubFake, pool_id, 5_000}})
             Poller.poll(pid)
             assert_receive {:error, :not_found}
           end) =~ "error polling info for repo: fake reason: :not_found"
  end

  # TODO: test publishing failure modes
end
