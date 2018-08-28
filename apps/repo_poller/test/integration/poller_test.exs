defmodule RepoPoller.Integration.PollerTest do
  use ExUnit.Case

  alias AMQP.{Connection, Channel, Queue, Basic}

  alias RepoPoller.Poller
  alias RepoPoller.Repository.GithubFake
  alias Domain.Repos.Repo
  alias Domain.Tags.Tag
  alias Domain.Jobs.NewReleaseJob
  alias Domain.Serializers.NewReleaseJobSerializer, as: JobSerializer
  alias RepoPoller.DB

  @moduletag :integration
  @queue "test.new_releases.queue"

  setup do
    DB.clear()
    # setup test queue in RabbitMQ
    {:ok, conn} = Connection.open()
    {:ok, channel} = Channel.open(conn)
    {:ok, %{queue: queue}} = Queue.declare(channel, @queue)

    on_exit(fn ->
      DB.clear()
      {:ok, _} = Queue.delete(channel, queue)
      :ok = Connection.close(conn)
    end)
  end

  setup do
    pool_id = String.to_atom("test_pool")
    caller = self()

    rabbitmq_config = [
      channels: 1,
      queue: @queue,
      exchange: "",
      caller: caller
    ]

    rabbitmq_conn_pool = [
      :rabbitmq_conn_pool,
      pool_id: pool_id,
      name: {:local, pool_id},
      worker_module: BugsBunny.Worker.RabbitConnection,
      size: 1,
      max_overflow: 0
    ]

    Application.put_env(:repo_poller, :rabbitmq_config, rabbitmq_config)

    start_supervised!(%{
      id: BugsBunny.PoolSupervisorTest,
      start:
        {BugsBunny.PoolSupervisor, :start_link,
         [
           [rabbitmq_config: rabbitmq_config, rabbitmq_conn_pool: rabbitmq_conn_pool],
           BugsBunny.PoolSupervisorTest
         ]},
      type: :supervisor
    })

    {:ok, pool_id: pool_id}
  end

  test "place new tags in rabbitmq to be processed later", %{pool_id: pool_id} do
    repo = Repo.new("https://github.com/new-tag/elixir")
    pid = start_supervised!({Poller, {self(), repo, GithubFake, pool_id, 10_000}})
    Poller.poll(pid)
    assert_receive {:ok, _tags}, 1000
    tags = DB.get_tags(repo)
    refute Enum.empty?(tags)

    BugsBunny.with_channel(pool_id, fn {:ok, channel} ->
      {:ok, consumer_tag} = Basic.consume(channel, @queue)
      assert_receive {:basic_deliver, payload, %{consumer_tag: ^consumer_tag}}
      job = JobSerializer.deserialize!(payload)

      assert job ==
               %NewReleaseJob{
                 repo: repo,
                 new_tag: %Tag{
                   commit: %{
                     sha: "2b338092b6da5cd5101072dfdd627cfbb49e4736",
                     url:
                       "https://api.github.com/repos/elixir-lang/elixir/commits/2b338092b6da5cd5101072dfdd627cfbb49e4736"
                   },
                   name: "v1.7.2",
                   node_id: "MDM6UmVmMTIzNDcxNDp2MS43LjI=",
                   tarball_url: "https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.2",
                   zipball_url: "https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.2"
                 }
               }
    end)

    # TODO: Test new tags are prepended to old tags and scheduled
    # TODO: test no job to publish
    # TODO: test publish multiple jobs - multiple new tags
  end
end
