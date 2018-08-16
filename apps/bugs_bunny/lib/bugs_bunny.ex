defmodule BugsBunny do

  alias BugsBunny.Worker.RabbitConnection, as: Conn
  alias BugsBunny.ChannelSupervisor

  def get_connection(pool_id, timeout \\ 5000) do
    :poolboy.transaction(pool_id, &Conn.get_connection/1, timeout)
  end

  def get_channel(pool_id, timeout \\ 5000) do
    :poolboy.transaction(:poolid, &Conn.get_channel/1, timeout)
  end
end
