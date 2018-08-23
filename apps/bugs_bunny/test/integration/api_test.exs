defmodule BugsBunny.Integration.ApiTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  alias BugsBunny.RabbitMQ
  alias BugsBunny.Worker.RabbitConnection

  @moduletag :integration

  setup do
    n = :rand.uniform(100)
    pool_id = String.to_atom("test_pool#{n}")

    rabbitmq_config = [
      channels: 1,
      # fire and forget queue
      queue: "",
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

  test "executes command with a channel", %{pool_id: pool_id} do
    BugsBunny.with_channel(pool_id, fn {:ok, channel} ->
      assert :ok = RabbitMQ.publish(channel, "", "", "hello")
    end)
  end

  test "returns out of channels when there aren't more channels", %{pool_id: pool_id} do
    BugsBunny.with_channel(pool_id, fn {:ok, _channel} ->
      BugsBunny.with_channel(pool_id, fn {:error, error} ->
        assert error == :out_of_channels
      end)
    end)
  end

  test "returns channel to pool after client actions", %{pool_id: pool_id} do
    conn_worker = :poolboy.checkout(pool_id)
    :ok = :poolboy.checkin(pool_id, conn_worker)

    BugsBunny.with_channel(pool_id, fn {:ok, _channel} ->
      assert %{channels: []} = RabbitConnection.state(conn_worker)
    end)

    assert %{channels: [channel]} = RabbitConnection.state(conn_worker)
  end

  test "gets connection to open channel manually", %{pool_id: pool_id} do
    assert {:ok, conn} = BugsBunny.get_connection(pool_id)
    assert {:ok, channel} = RabbitMQ.open_channel(conn)
    assert :ok = AMQP.Channel.close(channel)
  end

  test "returns channel to the pool only once when there is a crash in a client using with_channel",
       %{pool_id: pool_id} do
    # TODO: capture [error] Process #PID<X.X.X> raised an exception
    capture_log(fn ->
      conn_worker = :poolboy.checkout(pool_id)
      :ok = :poolboy.checkin(pool_id, conn_worker)
      :erlang.trace(conn_worker, true, [:receive])

      {:ok, client_pid} =
        Task.start(fn ->
          BugsBunny.with_channel(pool_id, fn {:ok, _channel} ->
            raise "die"
          end)
        end)

      ref = Process.monitor(client_pid)
      # wait for client to die
      assert_receive {:DOWN, ^ref, :process, ^client_pid, {%{message: "die"}, _stacktrace}}, 1000
      # wait for channel to be put it back into the pool
      assert_receive {:trace, ^conn_worker, :receive,
                      {:"$gen_cast", {:checkin_channel, _channel}}},
                     1000

      # wait for the connection worker to receive a :DOWN message from the client
      # FLAKY assertion: sometimes the message was already received so this function fails
      # assert_receive {:trace, ^conn_worker, :receive,
      #                 {:DOWN, _ref, :process, ^client_pid, {%{message: "die"}, _stacktrace}}}, 1000

      assert %{channels: channels} = RabbitConnection.state(conn_worker)
      assert length(channels) == 1
    end)
  end

  test "returns channel to the pool only once when the channel closes using with_channel",
       %{pool_id: pool_id} do
    conn_worker = :poolboy.checkout(pool_id)
    :ok = :poolboy.checkin(pool_id, conn_worker)
    :erlang.trace(conn_worker, true, [:receive])

    logs =
      capture_log(fn ->
        client_pid =
          spawn(fn ->
            BugsBunny.with_channel(pool_id, fn {:ok, channel} ->
              :ok = AMQP.Channel.close(channel)
            end)
          end)

        ref = Process.monitor(client_pid)
        assert_receive {:DOWN, ^ref, :process, ^client_pid, :normal}, 500

        assert_receive {:trace, ^conn_worker, :receive,
                        {:"$gen_cast", {:checkin_channel, _channel}}}

        assert_receive {:trace, ^conn_worker, :receive, {:EXIT, _channel_pid, :normal}}
        assert %{channels: channels} = RabbitConnection.state(conn_worker)
        assert length(channels) == 1
      end)

    assert logs =~ "[Rabbit] channel lost, attempting to reconnect reason: :normal"
  end
end
