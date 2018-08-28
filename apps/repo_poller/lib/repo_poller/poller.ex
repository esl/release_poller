defmodule RepoPoller.Poller do
  use GenServer
  require Logger

  alias RepoPoller.{DB, Config}
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
        schedule_jobs(state, repo, new_tags)
    end
  end

  @spec schedule_jobs(State.t(), Repo.t(), list(Tag.t()), non_neg_integer()) ::
          {:ok, State.t()} | {:error, :out_of_retries}
  defp schedule_jobs(state, repo, new_tags, retries \\ 5)
  defp schedule_jobs(_state, _repo, _new_tags, 0), do: {:error, :out_of_retries}

  defp schedule_jobs(%{pool_id: pool_id} = state, repo, new_tags, retries) do
    BugsBunny.with_channel(pool_id, &do_with_channel(&1, state, repo, new_tags, retries))
  end

  @spec do_with_channel(
          {:ok, AMQP.Channel.t()} | {:error, :disconected | :out_of_channels},
          State.t(),
          Repo.t(),
          list(Tag.t()),
          non_neg_integer()
        ) :: {:ok, State.t()} | {:error, :out_of_retries}
  defp do_with_channel({:error, reason}, state, repo, new_tags, retries) do
    Logger.error("error getting a channel reason: #{reason}")
    :timer.sleep(5_000)
    schedule_jobs(state, repo, new_tags, retries - 1)
  end

  defp do_with_channel({:ok, channel}, %{caller: caller} = state, repo, new_tags, _retries) do
    %{owner: owner, name: name} = repo

    jobs = NewReleaseJob.new(repo, new_tags)
    Logger.info("publishing #{length(jobs)} releases for #{owner}/#{name}")

    for job <- jobs do
      job_payload = NewReleaseJobSerializer.serialize!(job)

      case publish_job(channel, job_payload) do
        {:error, reason} ->
          # TODO: handle publish errors e.g maybe remove tag from new_tags so it can be re-scheduled later
          Logger.error("error publishing new release for #{owner}/#{name} reason: #{reason}")

          :ok

        :ok ->
          if caller, do: send(caller, {:job_published, job_payload})
          :ok
      end
    end

    new_repo = Repo.add_tags(repo, new_tags)
    :ok = DB.save(new_repo)
    {:ok, %State{state | repo: new_repo}}
  end

  @spec publish_job(AMQP.Channel.t(), String.t() | iodata()) :: :ok | AMQP.Basic.error()
  defp publish_job(channel, payload) do
    # pass general config options when publishing new tags e.g :persistent, :mandatory, :immediate etc
    config = Config.get_rabbitmq_config()
    queue = Config.get_rabbitmq_queue()
    exchange = Config.get_rabbitmq_exchange()
    Config.get_rabbitmq_client().publish(channel, exchange, queue, payload, config)
  end
end
