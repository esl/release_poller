defmodule BugsBunny do
  alias BugsBunny.Worker.RabbitConnection, as: Conn

  @type f :: (AMQP.Channel.t() | {:error, :disconected | :out_of_channels} -> any())

  @doc """
  Gets a connection from a connection worker so any client can exec commands
  manually
  """
  @spec get_connection(atom()) :: {:ok, AMQP.Connection.t()} | {:error, :disconnected}
  def get_connection(pool_id) do
    :poolboy.transaction(pool_id, &Conn.get_connection/1)
  end

  @doc """
  Executes function f in the context of a channel, takes a connection worker
  out of the pool, put that connection worker back into the pool so any
  other concurrent client can have access to it, checks out a channel out of
  the worker's channel pool, executes the function with the result of the
  checkout and finally puts the channel back into the worker's pool.
  """
  @spec with_channel(atom(), f()) :: :ok | {:error, :out_of_retries}
  def with_channel(pool_id, fun) do
    conn_worker = :poolboy.checkout(pool_id)
    :ok = :poolboy.checkin(pool_id, conn_worker)
    do_with_conn(conn_worker, fun)
  end

  @spec do_with_conn(pid(), f()) :: any()
  defp do_with_conn(conn_worker, fun) do
    case checkout_channel(conn_worker) do
      {:ok, channel} = ok_chan ->
        try do
          fun.(ok_chan)
        after
          :ok = checkin_channel(conn_worker, channel)
        end
      {:error, _} = error ->
        fun.(error)
    end
  end

  def get_connection_worker(pool_id) do
    conn_worker = :poolboy.checkout(pool_id)
    :ok = :poolboy.checkin(pool_id, conn_worker)
    conn_worker
  end

  def checkout_channel(conn_worker) do
    Conn.checkout_channel(conn_worker)
  end

  def checkin_channel(conn_worker, channel) do
    Conn.checkin_channel(conn_worker, channel)
  end
end
