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

    rabbitmq_config = [
      port: String.to_integer(System.get_env("POLLER_RMQ_PORT") || "5672")
    ]

    {:ok, conn} = Connection.open(rabbitmq_config)
    {:ok, channel} = Channel.open(conn)
    {:ok, %{queue: queue}} = Queue.declare(channel, @queue)

    on_exit(fn ->
      DB.clear()
      {:ok, _} = Queue.delete(channel, queue)
      :ok = Connection.close(conn)
    end)
  end

  setup do
    caller = self()

    rabbitmq_config = [
      channels: 1,
      port: String.to_integer(System.get_env("POLLER_RMQ_PORT") || "5672"),
      queue: @queue,
      exchange: "",
      caller: caller
    ]

    rabbitmq_conn_pool = [
      :rabbitmq_conn_pool,
      pool_id: :test_pool,
      name: {:local, :test_pool},
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

    {:ok, pool_id: :test_pool}
  end

  test "place new job in rabbitmq to be processed later - single tag", %{pool_id: pool_id} do
    repo = Repo.new("https://github.com/new-tag/elixir")
    pid = start_supervised!({Poller, {self(), repo, GithubFake, pool_id}})
    Poller.poll(pid)
    assert_receive {:ok, _tags}, 1000
    db_repo = DB.get_repo(repo)
    refute Enum.empty?(db_repo.tags)

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
  end

  test "place multiple jobs in rabbitmq to be processed later - multiple new tags", %{
    pool_id: pool_id
  } do
    repo = Repo.new("https://github.com/2-new-tags/elixir")
    pid = start_supervised!({Poller, {self(), repo, GithubFake, pool_id}})
    Poller.poll(pid)
    assert_receive {:ok, _tags}, 1000

    BugsBunny.with_channel(pool_id, fn {:ok, channel} ->
      {:ok, consumer_tag} = Basic.consume(channel, @queue)

      assert_receive {:basic_deliver, payload1,
                      %{consumer_tag: ^consumer_tag, delivery_tag: delivery_tag}}

      job1 = JobSerializer.deserialize!(payload1)

      assert job1 ==
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

      :ok = Basic.ack(channel, delivery_tag)

      assert_receive {:basic_deliver, payload2,
                      %{consumer_tag: ^consumer_tag, delivery_tag: delivery_tag}}

      :ok = Basic.ack(channel, delivery_tag)

      job2 = JobSerializer.deserialize!(payload2)

      assert job2 ==
               %NewReleaseJob{
                 repo: repo,
                 new_tag: %Tag{
                   commit: %{
                     sha: "8aab53b941ee955f005e7b4e08c333f0b94c48b7",
                     url:
                       "https://api.github.com/repos/elixir-lang/elixir/commits/8aab53b941ee955f005e7b4e08c333f0b94c48b7"
                   },
                   name: "v1.7.1",
                   node_id: "MDM6UmVmMTIzNDcxNDp2MS43LjE=",
                   tarball_url: "https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.1",
                   zipball_url: "https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.1"
                 }
               }
    end)
  end

  test "doesn't publish new jobs", %{pool_id: pool_id} do
    repo = Repo.new("https://github.com/2-new-tags/elixir")
    pid = start_supervised!({Poller, {self(), repo, GithubFake, pool_id}})

    {:ok, tags} = GithubFake.get_tags(repo)

    :ok =
      repo
      |> Repo.add_tags(tags)
      |> DB.save()

    Poller.poll(pid)

    BugsBunny.with_channel(pool_id, fn {:ok, channel} ->
      {:ok, consumer_tag} = Basic.consume(channel, @queue)

      refute_receive {:basic_deliver, _payload, %{consumer_tag: ^consumer_tag}}, 1000
    end)
  end

  test "only publishes new tags jobs", %{pool_id: pool_id} do
    repo = Repo.new("https://github.com/2-new-tags/elixir")
    {:ok, [new_tag, tag]} = GithubFake.get_tags(repo)
    repo = Repo.add_tags(repo, [tag])
    :ok = DB.save(repo)
    pid = start_supervised!({Poller, {self(), repo, GithubFake, pool_id}})

    Poller.poll(pid)

    assert_receive {:ok, _tags}, 1000

    BugsBunny.with_channel(pool_id, fn {:ok, channel} ->
      {:ok, consumer_tag} = Basic.consume(channel, @queue)

      assert_receive {:basic_deliver, payload, %{consumer_tag: ^consumer_tag}}

      job = JobSerializer.deserialize!(payload)

      assert %NewReleaseJob{
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
             } = job

      %{tags: tags} = DB.get_repo(repo)
      assert tags == [new_tag, tag]
    end)
  end
end
