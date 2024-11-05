defmodule Butler.Irc.ConnectionHandler do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([client, config]) do
    ExIRC.Client.add_handler(client, self())
    ExIRC.Client.connect!(client, config.server, config.port)

    state = Map.put(config, :client, client)
    {:ok, state}
  end

  def handle_info({:connected, server, port}, state) do
    Logger.debug("Connected to #{server}:#{port}")
    ExIRC.Client.logon(state.client, state.password, state.nickname, state.user, state.user)
    {:noreply, state}
  end

  def handle_info(:disconnected, state) do
    Logger.error("Server disconnected!")
    # Only crash after 10 seconds to give the remote server to restart.
    Process.send_after(self(), :restart_connection, 10_000)

    {:noreply, state}
  end

  def handle_info(:restart_connection, state) do
    {:stop, :normal, state}
  end

  # Catch-all for messages you don't care about
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
