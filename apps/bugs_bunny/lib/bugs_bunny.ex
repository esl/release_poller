defmodule BugsBunny do
  alias BugsBunny.Worker.RabbitConnection, as: Conn
  alias BugsBunny.ChannelSupervisor

  @spec get_channel(pid()) :: {:ok, AMQP.Connection.t()} | {:error, :disconnected}
  def get_connection(pool_id) do
    :poolboy.transaction(pool_id, &Conn.get_connection/1)
  end

  @spec get_channel(pid()) ::
          {:ok, AMQP.Channel.t()}
          | {:error, :no_channel}
          | {:error, :disconnected}
          | {:error, :out_of_channels}
  def get_channel(pool_id) do
    :poolboy.transaction(pool_id, &Conn.get_channel/1)
  end
end
