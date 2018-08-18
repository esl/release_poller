defmodule BugsBunny.Worker.RabbitConnection do
  use GenServer

  require Logger

  alias __MODULE__

  @reconnect_interval 5_000
  @default_channels 1000

  defmodule State do
    @type config :: keyword() | String.t()

    @enforce_keys [:config]
    @type t :: %__MODULE__{
            connection: AMQP.Connection.t(),
            channels: list(pid()),
            monitors: [],
            config: config()
          }

    defstruct connection: nil, channels: [], config: nil, monitors: []
  end

  # API
  @spec start_link(State.config()) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, [])
  end

  @spec get_connection(pid()) :: {:ok, AMQP.Connection.t()} | {:error, :disconnected}
  def get_connection(pid) do
    GenServer.call(pid, :conn)
  end

  @spec checkout_channel(pid()) ::
          {:ok, AMQP.Channel.t()}
          | {:error, :disconnected}
          | {:error, :out_of_channels}
  def checkout_channel(pid) do
    GenServer.call(pid, :checkout_channel)
  end

  @spec checkin_channel(pid(), AMQP.Channel.t()) :: :ok
  def checkin_channel(pid, channel) do
    GenServer.cast(pid, {:checkin_channel, channel})
  end

  # CALLBACKS
  @impl true
  def init(config) do
    Process.flag(:trap_exit, true)
    send(self(), :connect)
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
  def handle_call(:checkout_channel, _from, %{connection: nil} = state) do
    {:reply, {:error, :disconnected}, state}
  end

  @impl true
  def handle_call(:checkout_channel, _from, %{channels: []} = state) do
    {:reply, {:error, :out_of_channels}, state}
  end

  @impl true
  def handle_call(
        :checkout_channel,
        {from_pid, _ref} = from,
        %{channels: [channel | rest], monitors: monitors} = state
      ) do
    monitor_ref = Process.monitor(from_pid)

    {:reply, {:ok, channel},
     %State{state | channels: rest, monitors: [{monitor_ref, channel} | monitors]}}
  end

  @impl true
  def handle_cast({:checkin_channel, channel}, %{channels: channels, monitors: monitors} = state) do
    monitors
    |> Enum.find(fn {_ref, chan} ->
      channel == chan
    end)
    |> case do
      # checkin unmonitored channel :thinking_face:
      nil ->
        {:noreply, state}

      {ref, _} = returned ->
        true = Process.demonitor(ref)
        new_monitors = List.delete(monitors, returned)
        {:noreply, %State{state | channels: [channel | channels], monitors: new_monitors}}
    end
  end

  @impl true
  def handle_info(:connect, %{config: config, config: config} = state) do
    get_client(config).open_connection(config)
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
  def handle_info(
        {:EXIT, pid, reason},
        %{channels: channels, connection: conn, config: config} = state
      ) do
    Logger.error("[Rabbit] channel lost, attempting to reconnect reason: #{reason}")
    # TODO: use exponential backoff to reconnect
    # TODO: use circuit breaker to fail fast
    new_channels = List.delete(channels, pid)
    worker =
      get_client(config)
      |> start_channel(conn)
    {:noreply, %State{state | channels: [worker | new_channels], connection: nil}}
  end

  # if client holding a channel fails, then we need to take its channel back
  @impl true
  def handle_info(
        {:DOWN, down_ref, :process, _, _},
        %{channels: channels, monitors: monitors} = state
      ) do
    monitors
    |> Enum.find(fn {ref, _chan} ->
      down_ref == ref
    end)
    |> case do
      nil ->
        {:noreply, state}

      {_ref, channel} = returned ->
        new_monitors = List.delete(monitors, returned)
        {:noreply, %State{state | channels: [channel | channels], monitors: new_monitors}}
    end
  end

  @impl true
  def terminate(_reason, %{connection: connection, config: config}) do
    try do
      get_client(config).close_connection(connection)
    catch
      _, _ -> :ok
    end
  end

  def terminate(_reason, _state) do
    :ok
  end

  # INTERNALS
  # TODO: FIX spec, don't know why is failing the suggested success typing is the same with some enforcing keys
  # @spec handle_rabbit_connect(connection_result, State.t()) :: {:noreply, State.t()}
  #       when connection_result: {:error, any()} | {:ok, AMQP.Connection.t()}
  defp handle_rabbit_connect({:error, reason}, state) do
    Logger.error("[Rabbit] error reason: #{inspect(reason)}")
    # TODO: use exponential backoff to reconnect
    # TODO: use circuit breaker to fail fast
    schedule_connect()
    {:noreply, state}
  end

  defp handle_rabbit_connect({:ok, connection}, %State{config: config} = state) do
    Logger.info("[Rabbit] connected")
    %{pid: pid} = connection
    Process.link(pid)

    num_channels = Keyword.get(config, :channels, @default_channels)

    channels =
      for _ <- 1..num_channels do
        {:ok, channel} =
          get_client(config)
          |> start_channel(connection)
        channel
      end

    {:noreply, %State{state | connection: connection, channels: channels}}
  end

  defp schedule_connect(interval \\ @reconnect_interval) do
    Process.send_after(self(), :connect, interval)
  end

  # TODO: maybe start channels on demand as needed and store them in the state for re-use
  @spec start_channel(module(), AMQP.Connection.t()) :: {:ok, AMQP.Channel.t()} | {:error, any()}
  defp start_channel(client, connection) do
    case client.open_channel(connection) do
      {:ok, %{pid: pid}} = result ->
        Logger.info("[Rabbit] channel connected")
        true = Process.link(pid)
        result

      {:error, reason} = error ->
        Logger.error("[Rabbit] error starting channel reason: #{inspect(reason)}")
        error
    end
  end

  # RabbitMQ Client can be injected for testing purposes (maybe in the future we can inject a test
  # double so we don't depend on RabbitMQ to be configured in acceptance/unit tests)
  defp get_client(config) do
    Keyword.get(config, :client, BugsBunny.RabbitMQ)
  end
end
