# Debugging tricks

## Listening in on docker API communications when using socket file to communicate with the server.

We use the utility `socat`. `socat` : 
Creates a new socket file `/tmp/fake` to which `socat` listens.
`socat` copies all communications to stdout
`socat` forwards all communications to the real docker socket file `/var/run/docker.sock`

Try it out : 

```
socat -v UNIX-LISTEN:/tmp/fake,fork UNIX-CONNECT:/var/run/docker.sock
```

```
from docker import Client
c = Client(base_url='unix:///tmp/fake')
host_config = c.create_host_config(binds=['/tmp:/data'])
container = c.create_container('alpine:latest', '/bin/sh -c "echo test > /data/baz.txt"',  host_config=host_config)
c.start(container=container.get('Id'))
c.commit(container)
```

Or.. 

```
export DOCKER_HOST=unix:///tmp/fake
docker run -t -v /tmp:/data alpine /bin/sh -c "echo test > /data/baz.txt"
```

Just watch the socat output and you can determine exactly what's being communicated.
