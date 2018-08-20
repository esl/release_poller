defmodule BugsBunny.Integration.ApiTest do
  use ExUnit.Case, async: true

  alias BugsBunny.RabbitMQ
  alias BugsBunny.Worker.RabbitConnection

  setup do
    n = :rand.uniform(100)
    pool_id = String.to_atom("test_pool#{n}")

    rabbitmq_config = [
      channels: 1,
      queue: "", # fire and forget queue
      exchange: "",
      client: RabbitMQ
    ]

    rabbitmq_conn_pool = [
      :repo_poller,
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
end
