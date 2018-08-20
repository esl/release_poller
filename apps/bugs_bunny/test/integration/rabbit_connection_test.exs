defmodule BugsBunny.Integration.RabbitConnectionTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias BugsBunny.RabbitMQ
  alias BugsBunny.Worker.RabbitConnection, as: ConnWorker

  setup do
    rabbitmq_config = [
      channels: 5,
      queue: "test.queue",
      exchange: "",
      client: RabbitMQ
    ]

    {:ok, config: rabbitmq_config}
  end

  test "reconnects to rabbitmq when a connection crashes", %{config: config} do
    pid = start_supervised!({ConnWorker, [{:reconnect_interval, 10} | config]})
    :erlang.trace(pid, true, [:receive])

    logs =
      capture_log(fn ->
        assert {:ok, %{pid: conn_pid}} = ConnWorker.get_connection(pid)
        true = Process.exit(conn_pid, :kill)
        assert_receive {:trace, ^pid, :receive, {:EXIT, ^conn_pid, :killed}}
        assert_receive {:trace, ^pid, :receive, {:EXIT, _channel_pid, :shutdown}}
        assert_receive {:trace, ^pid, :receive, :connect}
        assert {:ok, _conn} = ConnWorker.get_connection(pid)
      end)

    assert logs =~ "[Rabbit] connection lost, attempting to reconnect reason: :killed"
    assert logs =~ "[Rabbit] connection lost, removing channel reason: :shutdown"
  end

  test "creates a new channel to when a channel crashes", %{config: config} do
    pid = start_supervised!({ConnWorker, [{:reconnect_interval, 10} | config]})
    :erlang.trace(pid, true, [:receive])

    logs =
      capture_log(fn ->
        assert {:ok, channel} = ConnWorker.checkout_channel(pid)
        %{pid: channel_pid} = channel

        client_pid =
          spawn(fn ->
            :ok = AMQP.Channel.close(channel)
          end)

        ref = Process.monitor(client_pid)
        assert_receive {:DOWN, ^ref, :process, ^client_pid, :normal}
        assert_receive {:trace, ^pid, :receive, {:EXIT, ^channel_pid, :normal}}
        %{channels: channels, monitors: monitors} = ConnWorker.state(pid)
        assert length(channels) == 5
        assert length(monitors) == 0
      end)

    assert logs =~ "[Rabbit] channel lost, attempting to reconnect reason: :normal"
  end
end
