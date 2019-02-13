# ReleasePoller

[![Build Status](https://travis-ci.org/esl/release_poller.svg?branch=master)](https://travis-ci.org/esl/release_poller)

## Project Split

The Release Poller project have been split into multiple repositories under the name of `Buildex`

- [Release Poller now called Buildex Poller](https://github.com/esl/buildex_poller)
- [Release Jobs now called Buildex Jobs](https://github.com/esl/buildex_jobs)
- [Release Domain now called Buildex Common](https://github.com/esl/buildex_common)
- [Buildex API](https://github.com/esl/buildex_api)

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

config :repo_poller, :github_auth, GITHUB_TOKEN # default System.get_env("GITHUB_AUTH")

# RabbitMQ Connection Config

# Optional, just QUEUE_NAME is required either in config or in ENV
config :repo_poller, :rabbitmq_config,
  host: "localhost", # optional
  port: 5672,        # optional
  channels: 1000,    # optional
  queue: QUEUE_NAME, # required
  exchange: "",      # optional
  reconnect: 1000,   # optional
  password: "guest", # optional
  username: "guest"  # optional

# RabbitMQ Connection Pool Config

config :repo_poller, :rabbitmq_conn_pool,
  pool_id: POOL_NAME,                               # required
  name: {:local, POOL_NAME},                        # required
  worker_module: BugsBunny.Worker.RabbitConnection, # required
  size: 2,                                          # required
  max_overflow: 0                                   # required
```

# Repo Jobs

it needs a list of pre-installed packages with its associated dependencies: [git, make]

```ex
# Repo Poller Config

config :repo_jobs, :consumers, NUMBER_OF_CONSUMERS # required

# RabbitMQ Connection Config

# Optional, just QUEUE_NAME is required either in config or in ENV
config :repo_jobs, :rabbitmq_config,
  host: "localhost", # optional
  port: 5672,        # optional
  channels: 1000,    # optional
  queue: QUEUE_NAME, # required
  exchange: "",      # optional
  reconnect: 1000,   # optional
  password: "guest", # optional
  username: "guest"  # optional

# RabbitMQ Connection Pool Config

config :repo_jobs, :rabbitmq_conn_pool,
  pool_id: POOL_NAME,                               # required
  name: {:local, POOL_NAME},                        # required
  worker_module: BugsBunny.Worker.RabbitConnection, # required
  size: 2,                                          # required
  max_overflow: 0                                   # required
```

## Environment

```bash
# Use this ENV variable if not using `config :repo_*, :rabbitmq_config, [queue: NAME]`
export QUEUE_NAME="new_releases.queue"
```

## Setup releases

```bash
# Release the repo_jobs app along its dependencies
MIX_ENV=prod mix release --name=jobs
# run the release
_build/prod/rel/jobs/bin/jobs foreground

# Release the repo_poller app along its dependencies
MIX_ENV=prod mix release --name=poller
# run the release
_build/prod/rel/poller/bin/poller foreground
```

## Development

in another terminal window, setup the admin server so poller and jobs
can get the repositories, tags and tasks out of it.

```bash
cd PATH/TO/ADMIN
iex --name admin@127.0.0.1 --cookie hola -S mix phx.server
```

```bash
cd apps/repo_jobs
iex --name jobs@127.0.0.1 --cookie hola -S mix
```

```bash
cd apps/repo_poller
iex --name poller@127.0.0.1 --cookie hola -S mix
```

### Using Nix (Totally Optional !)

In the root of project you will find a file called `shell.nix` which
can be executed using the `nix-shell` command (if available on the
system). This should create an environment with all the things needed
to run the project.
