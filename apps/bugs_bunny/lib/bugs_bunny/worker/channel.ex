defmodule BugsBunny.Worker.Channel do
  require Logger

  use GenServer
  use AMQP

  @reconnect_interval 5_000

  defmodule State do
    @type t :: %__MODULE__{
            channel: Channel.t()
          }

    defstruct channel: nil
  end

  def start_link(conn) do
    GenServer.start_link(__MODULE__, conn, [])
  end

  def get_channel(pid) do
    GenServer.call(pid, :channel)
  end

  # CALLBACKS
  @impl true
  def init(conn) do
    case Channel.open(conn) do
      {:ok, %Channel{pid: pid} = channel} ->
        Logger.info("[Rabbit] channel connected")
        Process.link(pid)
        state = %State{channel: channel}
        {:ok, state}

      error ->
        error
    end
  end

  @impl true
  def handle_call(:channel, _from, %{channel: nil} = state) do
    {:reply, {:error, :disconnected}, state}
  end

  @impl true
  def handle_call(:channel, _from, %{channel: channel} = state) do
    {:reply, {:ok, channel}, state}
  end
end
