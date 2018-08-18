defmodule BugsBunny do
  alias BugsBunny.Worker.RabbitConnection, as: Conn
  alias BugsBunny.ChannelSupervisor

  @type f :: (AMQP.Channel.t() | {:error, :disconected | :out_of_channels} -> any())

  @spec get_connection(atom()) :: {:ok, AMQP.Connection.t()} | {:error, :disconnected}
  def get_connection(pool_id) do
    :poolboy.transaction(pool_id, &Conn.get_connection/1)
  end

  @spec with_channel(atom(), f()) :: :ok | {:error, :out_of_retries}
  def with_channel(pool_id, fun) do
    conn_worker = :poolboy.checkout(pool_id)
    :ok = :poolboy.checkin(pool_id, conn_worker)
    do_with_conn(conn_worker, fun)
  end

  @spec do_with_conn(pid(), f()) :: any()
  defp do_with_conn(conn_worker, fun) do
    case Conn.checkout_channel(conn_worker) do
      {:ok, channel} = ok_chan ->
        try do
          fun.(ok_chan)
        after
          :ok = Conn.checkin_channel(conn_worker, channel)
        end
      {:error, _} = error->
        fun.(error)
    end
  end
end
