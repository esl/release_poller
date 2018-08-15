defmodule BugsBunny.Worker.RabbitConnection do
  use GenServer
  use AMQP

  require Logger

  alias __MODULE__
  @reconnect_interval 5_000

  defmodule State do
    @type config :: keyword() | String.t()

    @enforce_keys [:config]
    @type t :: %__MODULE__{
            conn_monitor: reference(),
            connection: Connection.t(),
            config: config()
          }

    defstruct conn_monitor: nil, connection: nil, config: nil
  end

  # API
  @spec start_link(State.config()) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, [])
  end

  @spec get_connection(pid()) :: any()
  def get_connection(pid) do
    GenServer.call(pid, :conn)
  end

  def init(config) do
    schedule_connect(0)
    {:ok, %State{config: config}}
  end

  # CALLBACKS
  def handle_call(:conn, _from, %{connection: nil} = state) do
    {:reply, {:error, :disconnected}, state}
  end

  def handle_call(:conn, _from, %{connection: connection} = state) do
    {:reply, {:ok, connection}, state}
  end

  def handle_info(:connect, %State{config: config} = state) do
    Connection.open(config)
    |> handle_rabbit_connect(state)
  end

  def handle_info({:DOWN, ref, _, _, _}, %{conn_monitor: ref} = state) do
    Logger.error("[Rabbit] connection lost, attempting to reconnect")
    # TODO: use exponential backoff to reconnect
    # TODO: use circuit breaker to fail fast
    schedule_connect()
    {:noreply, %State{state | conn_monitor: nil, connection: nil}}
  end

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

  defp handle_rabbit_connect({:ok, connection}, state) do
    Logger.info("[Rabbit] connected")
    %Connection{pid: pid} = connection
    conn_monitor = Process.monitor(pid)
    {:noreply, %State{state | conn_monitor: conn_monitor, connection: connection}}
  end

  defp schedule_connect(interval \\ @reconnect_interval) do
    Process.send_after(self(), :connect, interval)
  end
end
