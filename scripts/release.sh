#!/bin/bash 

# https://elixirforum.com/t/elixir-docker-image-wont-build-for-linux-arm64-v8-using-github-actions/56383/13
export ERL_FLAGS="+JPperf true"
export MIX_ENV=prod

mix deps.get --only prod 

mix compile 

mix assets.deploy 

mix phx.gen.release 

mix release