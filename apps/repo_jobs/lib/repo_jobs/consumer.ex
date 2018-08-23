defmodule RepoJobs.Consumer do
  use GenServer

  require Logger

  defmodule State do
    @enforce_keys [:pool_id]

    @type t :: %__MODULE__{
            pool_id: atom(),
            caller: pid(),
            channel: AMQP.Channel.t(),
            monitor: reference(),
            consumer_tag: String.t()
          }
    defstruct pool_id: nil, caller: nil, channel: nil, monitor: nil, consumer_tag: nil
  end

  def start_link(pool_id) do
    GenServer.start_link(__MODULE__, pool_id)
  end

  ####################
  # Server Callbacks #
  ####################

  @impl true
  def init(pool_id) do
    send(self(), :connect)
    {:ok, %State{pool_id: pool_id}}
  end

  @impl true
  def handle_info(:connect, %{pool_id: pool_id} = state) do
    pool_id
    |> BugsBunny.get_connection_worker()
    |> BugsBunny.checkout_channel()
    |> handle_channel_checkout(state)
  end

  @impl true
  def handle_info(
        {:DOWN, monitor, :process, chan_pid, reason},
        %{monitor: monitor, channel: %{pid: chan_pid}} = state
      ) do
    Logger.error("[consumer] channel down reason: #{inspect(reason)}")
    schedule_connect()
    {:noreply, %State{state | monitor: nil, consumer_tag: nil, channel: nil}}
  end

  ################################
  # AMQP Basic.Consume Callbacks #
  ################################

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, state) do
    {:noreply, state}
  end

  # This is sent for each message consumed, where `payload` contains the message
  # content and `meta` contains all the metadata set when sending with
  # Basic.publish or additional info set by the broker;
  def handle_info({:basic_deliver, payload, meta}, state) do
    tags = Poison.decode!(payload)
    Logger.info("[consumer] consuming payload")
    {:noreply, state}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, state) do
    Logger.error("[consumer] consumer was cancelled by the broker (basic_cancel)")
    {:stop, :normal, %State{state | channel: nil}}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, state) do
    Logger.error("[consumer] consumer was cancelled by the broker (basic_cancel_ok)")
    {:stop, :normal, %State{state | channel: nil}}
  end

  defp handle_channel_checkout({:ok, %{pid: channel_pid} = channel}, %State{} = state) do
    case handle_consume(channel) do
      {:ok, consumer_tag} ->
        ref = Process.monitor(channel_pid)
        {:noreply, %State{state | channel: channel, monitor: ref, consumer_tag: consumer_tag}}

      {:error, reason} ->
        Logger.error("[consumer] error consumin channel reason: #{inspect(reason)}")
        schedule_connect()
        {:noreply, %State{state | channel: nil, consumer_tag: nil}}
    end
  end

  defp handle_channel_checkout({:error, reason}, state) do
    # TODO: use exponential backoff to reconnect
    # TODO: use circuit breaker to fail fast
    Logger.error("[consumer] error getting channel reason: #{inspect(reason)}")
    schedule_connect()
    {:noreply, state}
  end

  defp handle_consume(channel) do
    queue = get_rabbitmq_queue()
    config = get_rabbitmq_config()
    get_rabbitmq_client().consume(channel, queue, self(), config)
  end

  defp schedule_connect() do
    send(self(), :connect)
  end

  defp get_rabbitmq_config() do
    Application.get_env(:repo_jobs, :rabbitmq_config)
  end

  defp get_rabbitmq_queue() do
    Application.get_env(:repo_jobs, :rabbitmq_config)
    |> Keyword.fetch!(:queue)
  end

  defp get_rabbitmq_client() do
    Application.get_env(:repo_jobs, :rabbitmq_config)
    |> Keyword.get(:client, BugsBunny.RabbitMQ)
  end
end
