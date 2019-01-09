# RepoPoller

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `repo_poller` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:repo_poller, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/repo_poller](https://hexdocs.pm/repo_poller).

## General Overview

- BugsBunny creates a pool of connections to RabbitMQ
- each connection worker traps exits and links the connection process to it
- each connection worker creates a pool of channels and links them to it
- when a client checks out a channel out of the pool the connection worker monitors that client to return the channel into it in case of a crash
- RepoPoller polls GitHub repos for new tags
- if there are new tags it publishes a message to RabbitMQ using the connection/channels pool

## High Level Architecture

when starting a connection worker we are going to start within it a pool of multiplexed channels to RabbitMQ and store them in its state (we can move this later to ets). Then, inside the connection worker we are going to trap exits and link each channel to it. this way if a channel crashes, the connection worker is going to be able to start another channel and if a connection to RabbitMQ crashes we are going to be able to restart that connection, remove all crashed channels and then restart them with a new connection; also we are going to be able to easily monitor client accessing channels, queue an dequeue channels from the pool in order to make them accessible by 1 client at a time making them race condition free.

![screen shot 2018-08-17 at 7 51 36 am](https://user-images.githubusercontent.com/1157892/44267068-71e83100-a1f2-11e8-8d73-2bc7a1914733.png)
