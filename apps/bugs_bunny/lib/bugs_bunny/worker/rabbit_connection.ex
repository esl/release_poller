defmodule BugsBunny.Worker.RabbitConnection do
  use GenServer
  use AMQP

  require Logger

  alias __MODULE__
  alias BugsBunny.ChannelSupervisor
  alias BugsBunny.Worker.Channel, as: BunnyChannel

  @reconnect_interval 5_000
  @default_channels 1000

  defmodule State do
    @type config :: keyword() | String.t()

    @enforce_keys [:config]
    @type t :: %__MODULE__{
            connection: Connection.t(),
            channels: list(pid()),
            config: config()
          }

    defstruct connection: nil, channels: [], config: nil
  end

  # API
  @spec start_link(State.config()) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, [])
  end

  @spec get_connection(pid()) :: {:ok, Connection.t()} | {:error, :disconnected}
  def get_connection(pid) do
    GenServer.call(pid, :conn)
  end

  @spec get_channel(pid()) ::
          {:ok, Channel.t()}
          | {:error, :no_channel}
          | {:error, :disconnected}
          | {:error, :out_of_channels}
  def get_channel(pid) do
    GenServer.call(pid, :channel)
  end

  # CALLBACKS
  @impl true
  def init(config) do
    Process.flag(:trap_exit, true)
    schedule_connect(0)
    {:ok, %State{config: config}}
  end

  @impl true
  def handle_call(:conn, _from, %{connection: nil} = state) do
    {:reply, {:error, :disconnected}, state}
  end

  @impl true
  def handle_call(:conn, _from, %{connection: connection} = state) do
    {:reply, {:ok, connection}, state}
  end

  # TODO: improve better pooling of channels
  # TODO: add overflow support
  # TODO: maybe make the get_channel call async/sync with GenServer.reply/2
  @impl true
  def handle_call(:channel, _from, %{connection: nil} = state) do
    {:reply, {:error, :disconnected}, state}
  end

  @impl true
  def handle_call(:channel, _from, %{connection: nil, channels: []} = state) do
    {:reply, {:error, :out_of_channels}, state}
  end

  @impl true
  def handle_call(:channel, _from, %{channels: [worker | _]} = state) do
    result = BunnyChannel.get_channel(worker)
    {:reply, result, state}
  end

  @impl true
  def handle_info(:connect, %{config: config} = state) do
    Connection.open(config)
    |> handle_rabbit_connect(state)
  end

  # connection crashed
  @impl true
  def handle_info({:EXIT, pid, reason}, %{connection: pid} = state) do
    Logger.error("[Rabbit] connection lost, attempting to reconnect reason: #{reason}")
    # TODO: use exponential backoff to reconnect
    # TODO: use circuit breaker to fail fast
    schedule_connect()
    {:noreply, %State{state | connection: nil}}
  end

  # connection crashed so channels are going to crash too
  @impl true
  def handle_info({:EXIT, pid, reason}, %{connection: nil, channels: channels} = state) do
    Logger.error("[Rabbit] connection lost, removing channel reason: #{reason}")
    new_channels = List.delete(channels, pid)
    {:noreply, %State{state | channels: new_channels}}
  end

  # connection didn't crashed but a channel did
  @impl true
  def handle_info({:EXIT, pid, reason}, %{channels: channels, connection: conn} = state) do
    Logger.error("[Rabbit] channel lost, attempting to reconnect reason: #{reason}")
    # TODO: use exponential backoff to reconnect
    # TODO: use circuit breaker to fail fast
    new_channels = List.delete(channels, pid)
    worker = start_channel_worker(conn)
    {:noreply, %State{state | channels: [worker | new_channels], connection: nil}}
  end

  @impl true
  def terminate(_reason, %{connection: connection}) do
    try do
      Connection.close(connection)
    catch
      _, _ -> :ok
    end
  end

  def terminate(_reason, _state) do
    :ok
  end

  # INTERNALS
  # TODO: FIX spec, don't know why is failing the suggested success typing is the same with some enforcing keys
  # @spec handle_rabbit_connect(connection_result, State.t()) :: {:no_reply, State.t()}
  #       when connection_result: {:error, any()} | {:ok, Connection.t()}
  defp handle_rabbit_connect({:error, reason}, state) do
    Logger.error("[Rabbit] error reason: #{inspect(reason)}")
    # TODO: use exponential backoff to reconnect
    # TODO: use circuit breaker to fail fast
    schedule_connect()
    {:noreply, state}
  end

  defp handle_rabbit_connect({:ok, connection}, %State{config: config} = state) do
    Logger.info("[Rabbit] connected")
    num_channels = Keyword.get(config, :channels, @max_channels)
    workers = for _ <- 1..num_channels, do: start_channel_worker(connection)
    %Connection{pid: pid} = connection
    Process.link(pid)
    {:noreply, %State{state | connection: connection, channels: workers}}
  end

  defp schedule_connect(interval \\ @reconnect_interval) do
    Process.send_after(self(), :connect, interval)
  end

  # TODO: maybe start channels on demand as needed and store them in the state for re-use
  @spec start_channel_worker(Connection.t()) :: pid()
  defp start_channel_worker(connection) do
    channel_worker_pid =
      case ChannelSupervisor.start_channel(connection) do
        {:ok, channel_worker_pid} -> channel_worker_pid
        {:ok, channel_worker_pid, _info} -> channel_worker_pid
        {:error, {:already_started, channel_worker_pid}} -> channel_worker_pid
      end

    true = Process.link(channel_worker_pid)
    channel_worker_pid
  end
end
