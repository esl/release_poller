defmodule BugsBunny.ChannelSupervisor do
  use DynamicSupervisor

  alias BugsBunny.Worker.Channel

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_channel(conn) do
    DynamicSupervisor.start_child(__MODULE__, {Channel, conn})
  end

  @impl true
  def init(args) do
    DynamicSupervisor.init(strategy: :one_for_one, restart: :temporary)
  end
end
