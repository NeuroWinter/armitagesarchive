FROM hexpm/elixir:1.16.3-erlang-26.2.3-debian-trixie-20251020-slim  AS build-system

RUN apt-get update && \
    apt-get install -y \
    build-essential \
    git \
    curl

ENV MIX_ENV=prod

WORKDIR /opt/armitage

COPY . .

# Here we want to build the final release.
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix deps.compile && \
    mix compile && \
    mix phx.digest && \
    mix release


# Now lets have a smaller slimmer final image.
FROM debian:trixie-slim as final

RUN apt-get update && \
    apt-get install -y \
    libssl3 \
    openssl \
    ca-certificates \
    curl

ENV HOME=/opt/armitage
ENV PORT=4000
ENV LANG=C.UTF-8
WORKDIR $HOME

COPY --from=build-system /opt/armitage/_build/prod/rel/armitage ./
CMD ["bin/armitage", "start"]
