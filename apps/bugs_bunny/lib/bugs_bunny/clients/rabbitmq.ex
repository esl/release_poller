defmodule BugsBunny.RabbitMQ do
  @behaviour BugsBunny.Clients.Adapter
  use AMQP

  @impl true
  def publish(channel, exchange, routing_key, payload, options \\ []) do
    Basic.publish(channel, exchange, routing_key, payload, options)
  end

  @impl true
  def consume(%Channel{} = channel, queue, consumer_pid \\ nil, options \\ []) do
    Basic.consume(channel, queue, consumer_pid, options)
  end

  @impl true
  def ack(%Channel{} = channel, tag, options \\ []) do
    Basic.ack(channel, tag, options)
  end

  @impl true
  def reject(%Channel{} = channel, tag, options \\ []) do
    Basic.reject(channel, tag, options)
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
