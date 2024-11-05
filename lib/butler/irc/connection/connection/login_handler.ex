defmodule Butler.Irc.LoginHandler do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([client, config]) do
    ExIRC.Client.add_handler(client, self())
    {:ok, {client, config}}
  end

  def handle_info(:logged_in, state = {client, config}) do
    Logger.debug("Logged in to server")

    # Join all the channels defined in the config.
    config
    |> Map.get(:channels)
    |> Enum.each(&ExIRC.Client.join(client, &1))

    {:noreply, state}
  end

  def handle_info({:login_failed, :nick_in_use}, _state) do
    Logger.error("Login failed, nickname in use")
    {:stop, "Nickname in use!"}
  end

  # Catch-all for messages you don't care about
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
