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
