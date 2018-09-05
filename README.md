# ReleasePoller

[![Build Status](https://travis-ci.org/sescobb27/release_poller.svg?branch=master)](https://travis-ci.org/sescobb27/release_poller)

Poll Github (for now) looking for new tags and releases of given repositories,
if there is a new one, put a job into a RabbitMQ queue to be processed later.
Then from another app (the RabbitMQ consumer), consume new jobs in the queue
and exceute the provided tasks on it. Each task is going to be a pointer to a
repository that depend on new releases of the given repo, also is going to have
a way to run the given task via a Makefile and a series of commands or targets
on it.

Makefiles are going to have access to the following ENV variables

```bash
${REPO_NAME}_TAG # points to the new tag e.g ELIXIR_TAG="v1.7.2"
${REPO_NAME}_ZIP # points to the zipped content of the tag e.g ELIXIR_ZIP="https://api.github.com/repos/elixir-lang/elixir/zipball/v1.7.2"
${REPO_NAME}_TAR # points to the tar content of the tag e.g ELIXIR_TAR=https://api.github.com/repos/elixir-lang/elixir/tarball/v1.7.2
```

## Setup RabbitMQ with docker

```bash
# pull RabbitMQ image from docker
$> docker pull rabbitmq:3.7.7-management
# run docker in background
# name the container
# remove container if already exists
# attach default port between the container and your laptop
# attach default management port between the container and your laptop
# start rabbitmq with management console
$> docker run --detach --rm --hostname bugs-bunny --name roger_rabbit -p 5672:5672 -p 15672:15672 rabbitmq:3.7.7-management
# if you need to stop the container
$> docker stop roger_rabbit
# if you need to remove the container manually
$> docker container rm roger_rabbit
```

# Jobs Poller

## Config

```ex
# Repo Poller Config

config :repo_poller, :repos, [
  {
    # repo to poll
    "https://github.com/erlang/otp",
    # how to poll that repo (we only support github for now)
    RepoPoller.Repository.Github,
    # poll interval in seconds
    3600,
    # tasks
    [
      [
        # task to fetch
        url: "https://github.com/emqtt/emqttd",
        # commands or targets to execute secuentially
        commands: ["app", "rel"],
        # how to fetch the task
        source: Domain.Tasks.Sources.Github,
        # how to build, execute the task
        runner: Domain.Tasks.Runners.Make,
        # {Key, Value} tuples to pass as ENV to make please refer to [System.cmd/3](https://hexdocs.pm/elixir/System.html#cmd/3)
        env: []
      ]
    ]
  }
]

config :repo_poller, :github_auth, GITHUB_TOKEN # default System.get_env("GITHUB_AUTH")

# RabbitMQ Connection Config

config :repo_poller, :rabbitmq_config,
  host: "localhost",
  port: 5672,
  channels: 1000,
  queue: QUEUE_NAME, # required
  exchange: "",
  reconnect: 1000,
  password: "guest",
  username: "guest"

# RabbitMQ Connection Pool Config

config :repo_poller, :rabbitmq_conn_pool,
  pool_id: POOL_NAME, # required
  name: {:local, POOL_NAME}, # required
  worker_module: BugsBunny.Worker.RabbitConnection,
  size: 2,
  max_overflow: 0
```

# Repo Jobs

it needs a list of pre-installed packages with its associated dependencies: [git, make]

```ex
# Repo Poller Config

config :repo_jobs, :consumers, NUMBER_OF_CONSUMERS # required

# RabbitMQ Connection Config

config :repo_jobs, :rabbitmq_config,
  host: "localhost",
  port: 5672,
  channels: 1000,
  queue: QUEUE_NAME, # required
  exchange: "",
  reconnect: 1000,
  password: "guest",
  username: "guest"

# RabbitMQ Connection Pool Config

config :repo_jobs, :rabbitmq_conn_pool,
  pool_id: POOL_NAME, # required
  name: {:local, POOL_NAME}, # required
  worker_module: BugsBunny.Worker.RabbitConnection,
  size: 2,
  max_overflow: 0
```

## Setup releases

```bash
# Release the repo_jobs app along its dependencies
MIX_ENV=prod mix release --name=jobs

# Release the repo_poller app along its dependencies
MIX_ENV=prod mix release --name=poller
```
