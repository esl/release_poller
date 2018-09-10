defmodule RepoPoller.Poller do
  use GenServer
  require Logger

  alias RepoPoller.DB
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
  alias Domain.Jobs.NewReleaseJob
  alias Domain.Serializers.NewReleaseJobSerializer
  alias RepoPoller.Repository.Service

  defmodule State do
    @enforce_keys [:repo, :pool_id]

    @type adapter :: module()
    @type interval :: non_neg_integer()

    @type t :: %__MODULE__{
            repo: Repo.t(),
            adapter: adapter(),
            interval: interval(),
            pool_id: atom(),
            caller: pid()
          }
    defstruct(repo: nil, adapter: nil, interval: nil, pool_id: nil, caller: nil)
  end

  ##############
  # Client API #
  ##############

  def start_link({%{name: repo_name}, _adapter, _pool_id, _interval} = args) do
    GenServer.start_link(__MODULE__, args, name: String.to_atom(repo_name))
  end

  def start_link({_caller, %{name: repo_name}, _adapter, _pool_id, _interval} = args) do
    GenServer.start_link(__MODULE__, args, name: String.to_atom(repo_name))
  end

  @doc false
  def poll(name) do
    send(name, :poll)
  end

  @doc false
  def state(name) do
    GenServer.call(name, :state)
  end

  ####################
  # Server Callbacks #
  ####################

  @spec init({Repo.t(), State.adapter(), atom(), State.interval()}) :: {:ok, State.t()}
  @impl true
  def init({repo, adapter, pool_id, interval}) do
    state = %State{repo: repo, adapter: adapter, pool_id: pool_id, interval: interval}
    schedule_poll(0)
    {:ok, state}
  end

  @doc false
  @spec init({pid(), Repo.t(), State.adapter(), atom(), State.interval()}) :: {:ok, State.t()}
  @impl true
  def init({caller, repo, adapter, pool_id, interval}) do
    state = %State{
      repo: repo,
      adapter: adapter,
      pool_id: pool_id,
      interval: interval,
      caller: caller
    }

    {:ok, state}
  end

  @impl true
  def handle_info(
        :poll,
        %{repo: repo, adapter: adapter, interval: interval, caller: caller} = state
      ) do
    %{name: repo_name} = repo

    Logger.info("polling info for repo: #{repo_name}")

    case Service.get_tags(adapter, repo) do
      {:ok, tags} = res ->
        case update_repo_tags(repo, tags, state) do
          {:ok, new_state} ->
            schedule_poll(interval)
            if caller, do: send(caller, res)
            {:noreply, new_state}

          {:error, reason} ->
            if caller, do: send(caller, reason)
            {:stop, reason, state}
        end

      {:error, :rate_limit, retry} = err ->
        Logger.warn("rate limit reached for repo: #{repo_name} retrying in #{retry} ms")
        schedule_poll(retry)
        if caller, do: send(caller, err)
        {:noreply, state}

      {:error, reason} = err ->
        Logger.error("error polling info for repo: #{repo_name} reason: #{inspect(reason)}")
        schedule_poll(interval)
        if caller, do: send(caller, err)
        {:noreply, state}
    end
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  #############
  # Internals #
  #############

  @spec schedule_poll(State.interval()) :: reference()
  defp schedule_poll(interval) do
    Process.send_after(self(), :poll, interval)
  end

  @spec update_repo_tags(Repo.t(), list(Tag.t()), State.t()) ::
          {:ok, State.t()} | {:error, :out_of_retries}
  defp update_repo_tags(repo, tags, state) do
    repo
    |> DB.get_tags()
    |> Tag.new_tags(tags)
    |> case do
      [] ->
        {:ok, state}

      new_tags ->
        new_repo = Repo.set_tags(repo, tags)
        schedule_jobs(state, new_repo, new_tags)
    end
  end

  @spec schedule_jobs(State.t(), Repo.t(), list(Tag.t()), non_neg_integer()) ::
          {:ok, State.t()} | {:error, :out_of_retries}
  defp schedule_jobs(state, repo, tags, retries \\ 5)
  defp schedule_jobs(_state, _repo, _tags, 0), do: {:error, :out_of_retries}

  defp schedule_jobs(
         %{pool_id: pool_id} = state,
         %{owner: owner, name: name} = repo,
         tags,
         retries
       ) do
    job = NewReleaseJob.new(repo, tags)
    BugsBunny.with_channel(pool_id, fn error_or_channel ->
      with {:ok, channel} <- error_or_channel,
           job_payload <- NewReleaseJobSerializer.serialize!(job),
           :ok <- Logger.info("publishing new releases for #{owner}/#{name}"),
           :ok <- publish_new_tags(channel, job_payload) do
        :ok = DB.save(repo)
        {:ok, %State{state | repo: repo}}
      else
        {:error, reason} ->
          Logger.error("error publishing new releases for #{owner}/#{name} reason: #{reason}")
          :timer.sleep(5_000)
          schedule_jobs(state, repo, tags, retries - 1)
      end
    end)
  end

  @spec publish_new_tags(AMQP.Channel.t(), String.t() | iodata()) :: :ok | AMQP.Basic.error()
  defp publish_new_tags(channel, payload) do
    # pass general config options when publishing new tags e.g :persistent, :mandatory, :immediate etc
    config = get_rabbitmq_config()
    queue = get_rabbitmq_queue()
    exchange = get_rabbitmq_exchange()
    get_rabbitmq_client().publish(channel, exchange, queue, payload, config)
  end

  defp get_rabbitmq_config() do
    Application.get_env(:repo_poller, :rabbitmq_config)
  end

  defp get_rabbitmq_queue() do
    Application.get_env(:repo_poller, :rabbitmq_config)
    |> Keyword.fetch!(:queue)
  end

  defp get_rabbitmq_exchange() do
    Application.get_env(:repo_poller, :rabbitmq_config)
    |> Keyword.fetch!(:exchange)
  end

  defp get_rabbitmq_client() do
    Application.get_env(:repo_poller, :rabbitmq_config)
    |> Keyword.get(:client, BugsBunny.RabbitMQ)
  end
end
