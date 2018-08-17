defmodule RepoPoller.Poller do
  use GenServer
  require Logger

  alias RepoPoller.DB
  alias RepoPoller.Domain.{Repo, Tag}
  alias RepoPoller.Repository.Service

  defmodule State do
    @enforce_keys [:repo]

    @type adapter :: module()
    @type interval :: non_neg_integer()

    @type t :: %__MODULE__{
            repo: Repo.t(),
            adapter: adapter(),
            interval: interval(),
            pool_id: atom()
          }
    defstruct(repo: nil, adapter: nil, interval: nil, pool_id: nil)
  end

  def start_link({%{name: repo_name}, _adapter, _pool_id, _interval} = args) do
    GenServer.start_link(__MODULE__, args, name: String.to_atom(repo_name))
  end

  @spec init({Repo.t(), State.adapter(), atom(), State.interval()}) :: {:ok, State.t()}
  @impl true
  def init({repo, adapter, pool_id, interval}) do
    state = %State{repo: repo, adapter: adapter, pool_id: pool_id, interval: interval}
    schedule_poll(0)
    {:ok, state}
  end

  @impl true
  def handle_info(:poll, %{repo: repo, adapter: adapter, interval: interval} = state) do
    %{name: repo_name} = repo

    Logger.info("polling info for repo: #{repo_name}")

    new_state =
      case Service.get_tags(adapter, repo) do
        {:ok, tags} ->
          new_state = update_repo_tags(repo, tags, state)
          schedule_poll(interval)
          new_state

        {:error, :rate_limit, retry} ->
          Logger.warn("rate limit reached for repo: #{repo_name} retrying in #{retry} ms")
          schedule_poll(retry)
          state

        {:error, reason} ->
          Logger.error("error polling info for repo: #{repo_name} reason: #{inspect(reason)}")
          schedule_poll(interval)
          state
      end

    {:noreply, new_state}
  end

  @spec schedule_poll(State.interval()) :: reference()
  defp schedule_poll(interval) do
    Process.send_after(self(), :poll, interval)
  end

  @spec update_repo_tags(Repo.t(), list(Tag.t()), State.t()) :: State.t()
  defp update_repo_tags(repo, tags, state) do
    DB.get_tags(repo)
    |> Tag.new_tags(tags)
    |> case do
      [] -> state
      new_tags ->
        new_repo = Repo.set_tags(repo, tags)
        :ok = DB.save(new_repo)
        schedule_jobs(state, new_repo, new_tags)
        %State{state | repo: new_repo}
    end
  end

  @spec schedule_jobs(State.t(), Repo.t(), list(Tag.t())) :: :ok
  defp schedule_jobs(%{pool_id: pool_id}, %{owner: owner, name: name}, tags) do
    BugsBunny.with_channel(pool_id, fn channel ->
      encoded_tags = Poison.encode!(tags)
      Logger.info("publishing new releases for #{owner}/#{name}")
      queue = get_rabbitmq_queue()
      exchange = get_rabbitmq_exchange()
      BugsBunny.RabbitMQ.publish(channel, exchange, queue, encoded_tags)
    end)
  end

  defp get_rabbitmq_queue() do
    Application.get_env(:repo_poller, :rabbitmq_config)
    |> Keyword.fetch!(:queue)
  end

  defp get_rabbitmq_exchange() do
    Application.get_env(:repo_poller, :rabbitmq_config)
    |> Keyword.fetch!(:exchange)
  end
end
