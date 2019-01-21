# base image elixir to start with
FROM bitwalker/alpine-elixir:1.7.4

# install docker client
RUN apk --update add curl \
    && mkdir -p /tmp/download \
    && curl -L "https://download.docker.com/linux/static/stable/x86_64/docker-18.09.1.tgz" | tar -xz -C /tmp/download \
    && mv /tmp/download/docker/docker /usr/local/bin/ \
    && rm -rf /tmp/download \
    && apk del curl \
    && rm -rf /var/cache/apk/*

VOLUME /var/lib/docker

# install hex package manager
RUN mix local.hex --force

# create app folder
RUN mkdir /app
WORKDIR /app
COPY . /app

# setting the environment (prod = PRODUCTION!)
ENV MIX_ENV=prod

# install dependencies (production only)
RUN mix local.rebar --force
RUN mix deps.get --only prod
RUN mix compile

# create release
RUN mix release --name=jobs

ENV REPLACE_OS_VARS=true
ENTRYPOINT ["_build/prod/rel/jobs/bin/jobs"]

# run elixir app
CMD ["foreground"]
