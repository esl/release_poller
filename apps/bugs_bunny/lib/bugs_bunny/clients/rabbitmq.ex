defmodule BugsBunny.RabbitMQ do
  @behaviour BugsBunny.Clients.Adapter
  use AMQP

  def publish(channel, exchange, routing_key, payload, options \\ []) do
    Basic.publish(channel, exchange, routing_key, payload, options)
  end

  @impl true
  def open_connection(config) do
    Connection.open(config)
  end

  @impl true
  def open_channel(conn) do
    Channel.open(conn)
  end

  @impl true
  def close_connection(conn) do
    Connection.close(conn)
  end
end
