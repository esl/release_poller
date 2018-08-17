defmodule BugsBunny do
  alias BugsBunny.Worker.RabbitConnection, as: Conn
  alias BugsBunny.ChannelSupervisor

  @spec get_connection(pid()) :: {:ok, AMQP.Connection.t()} | {:error, :disconnected}
  def get_connection(pool_id) do
    :poolboy.transaction(pool_id, &Conn.get_connection/1)
  end

  @spec with_channel(pid(), (AMQP.Channel.t() -> any())) :: :ok | {:error, :out_of_retries}
  def with_channel(pool_id, fun, retries \\ 3) do
    :poolboy.transaction(pool_id, fn conn_worker ->
      do_with_conn(conn_worker, fun, retries)
    end)
  end

  @spec do_with_conn(pid(), (AMQP.Channel.t() -> any()), non_neg_integer) :: :ok | {:error, :out_of_retries}
  defp do_with_conn(conn_worker, fun, 0) do
    {:error, :out_of_retries}
  end

  defp do_with_conn(conn_worker, fun, retries) do
    case Conn.checkout_channel(conn_worker) do
      {:ok, channel} ->
        try do
          fun.(channel)
        after
          :ok = Conn.checkin_channel(conn_worker, channel)
        end
      # TODO: add support for exponential backoff
      {:error, :disconnected} ->
        :timer.sleep(5_000)
        do_with_conn(conn_worker, fun, retries - 1)
      {:error, :out_of_channels} ->
        # TODO: maybe add overflow support
        :timer.sleep(5_000)
        do_with_conn(conn_worker, fun, retries - 1)
    end
  end
end
