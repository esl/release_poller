defmodule RepoJobs.Integration.ConsumerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias BugsBunny.RabbitMQ
  alias BugsBunny.Worker.RabbitConnection
  alias RepoJobs.Consumer
  alias AMQP.{Connection, Channel, Queue}
  alias Domain.Jobs.NewReleaseJob
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag

  @queue "test.consumer.queue"

  setup do
    # setup test queue in RabbitMQ
    {:ok, conn} = Connection.open()
    {:ok, channel} = Channel.open(conn)
    {:ok, %{queue: queue}} = Queue.declare(channel, @queue)

    on_exit(fn ->
      {:ok, _} = Queue.delete(channel, queue)
      :ok = Connection.close(conn)
    end)

    {:ok, channel: channel}
  end

  setup do
    n = :rand.uniform(100)
    pool_id = String.to_atom("test_pool#{n}")

    rabbitmq_config = [
      channels: 1,
      queue: @queue,
      exchange: "",
      client: RabbitMQ
    ]

    rabbitmq_conn_pool = [
      :rabbitmq_conn_pool,
      pool_id: pool_id,
      name: {:local, pool_id},
      worker_module: RabbitConnection,
      size: 1,
      max_overflow: 0
    ]

    Application.put_env(:repo_jobs, :rabbitmq_config, rabbitmq_config)

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

  test "handles channel crashes", %{pool_id: pool_id} do
    log =
      capture_log(fn ->
        pid = start_supervised!({Consumer, pool_id})
        assert %{channel: channel} = Consumer.state(pid)
        :erlang.trace(pid, true, [:receive])
        %{pid: channel_pid} = channel
        :ok = Channel.close(channel)
        # channel is down
        assert_receive {:trace, ^pid, :receive, {:DOWN, _ref, :process, ^channel_pid, :normal}}
        # attempt to reconnect
        assert_receive {:trace, ^pid, :receive, :connect}
        # consuming messages again
        assert_receive {:trace, ^pid, :receive,
                        {:basic_consume_ok, %{consumer_tag: _consumer_tag}}}

        assert %{channel: channel2} = Consumer.state(pid)
        refute channel == channel2
      end)

    assert log =~ "[error] [consumer] channel down reason: :normal"
    assert log =~ "[error] [Rabbit] channel lost, attempting to reconnect reason: :normal"
  end

  test "consumes messaged published to the queue", %{channel: channel, pool_id: pool_id} do
    start_supervised!({Consumer, {self(), pool_id}})

    payload =
      "{\"repo\":{\"owner\":\"elixir-lang\",\"name\":\"elixir\"},\"new_tags\":[{\"zipball_url\":\"https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.2\",\"tarball_url\":\"https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.2\",\"node_id\":\"MDM6UmVmMTIzNDcxNDp2MS43LjI=\",\"name\":\"v1.7.2\",\"commit\":{\"url\":\"https://api.github.com/repos/elixir-lang/elixir/commits/2b338092b6da5cd5101072dfdd627cfbb49e4736\",\"sha\":\"2b338092b6da5cd5101072dfdd627cfbb49e4736\"}}]}"

    :ok = RabbitMQ.publish(channel, "", @queue, payload)
    assert_receive {:new_release_job, job}, 1000

    assert job == %NewReleaseJob{
             new_tags: [
               %Tag{
                 commit: %{
                   sha: "2b338092b6da5cd5101072dfdd627cfbb49e4736",
                   url:
                     "https://api.github.com/repos/elixir-lang/elixir/commits/2b338092b6da5cd5101072dfdd627cfbb49e4736"
                 },
                 name: "v1.7.2",
                 node_id: "MDM6UmVmMTIzNDcxNDp2MS43LjI=",
                 tarball_url: "https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.2",
                 zipball_url: "https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.2"
               }
             ],
             repo: %Repo{name: "elixir", owner: "elixir-lang", tags: []}
           }
  end
end
