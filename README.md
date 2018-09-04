# ReleasePoller

[![Build Status](https://travis-ci.org/sescobb27/release_poller.svg?branch=master)](https://travis-ci.org/sescobb27/release_poller)

**TODO: Add description**

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
  # {REPO_TO_POLL, HOW_TO_POLL, POLL_INTERVAL (seconds), [TASKS]}
  # TASKS: [
  #   url: TASK_TO_FETCH, # required
  #   runner: Make,
  #   source: Github,
  #   commands: []
  # ]
  {"https://github.com/erlang/otp", RepoPoller.Repository.Github, 3600,
   [
     [url: "https://github.com/DeadZen/goldrush", commands: ["all"]],
     [url: "https://github.com/emqtt/emqttd", commands: ["app", "rel"]]
   ]}
]

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
