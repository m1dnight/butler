#!/bin/bash

export NICKNAME=Butler
export USER=Butler
export SERVER=irc.libera.chat
export PASSWORD=""
export PORT=6667
export CHANNELS="#ircois"
export PLUGINS="Elixir.Butler.Plugins.Karma,Elixir.Butler.Plugins.Help,Elixir.Butler.Plugins.Remember"
export DATABASE_PATH=".db/.butlerdb"
KEY=$(openssl rand -base64 64)
export SECRET_KEY_BASE="${KEY}"
export PHX_SERVER=true


_build/prod/rel/butler/bin/butler eval "Butler.Release.migrate"
_build/prod/rel/butler/bin/butler start