# DockerApi

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `docker_api` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:docker_api, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/docker_api](https://hexdocs.pm/docker_api).


remove unnecessary images
docker rmi $(sudo docker images --filter "dangling=true" -q --no-trunc)