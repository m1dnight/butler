defmodule Butler.Irc.MessageHandler do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([client, config]) do
    ExIRC.Client.add_handler(client, self())
    {:ok, {client, config}}
  end

  # You joined a channel.
  def handle_info({:joined, channel}, state) do
    Logger.debug("Joined #{channel}")
    {:noreply, state}
  end

  # Somebody else joined a channel we are in.
  def handle_info({:joined, channel, user}, state) do
    Logger.debug("#{user} joined #{channel}")
    {:noreply, state}
  end

  # Topic in a channel changed.
  def handle_info({:topic_changed, channel, topic}, state) do
    Logger.debug("#{channel} topic changed to #{topic}")
    {:noreply, state}
  end

  # Changed our own nick.
  def handle_info({:nick_changed, nick}, state) do
    Logger.debug("We changed our nick to #{nick}")
    {:noreply, state}
  end

  # Somebody else changed their nick.
  def handle_info({:nick_changed, old, new}, state) do
    Logger.debug("#{old} is now known as #{new}")
    {:noreply, state}
  end

  # Direct message.
  def handle_info({:received, message, sender}, state) do
    from = sender.nick
    Logger.debug("#{from} sent us a private message: #{message}")
    {:noreply, state}
  end

  # Message in channel.
  def handle_info({:received, message, sender, channel}, state) do
    from = sender.nick
    Logger.debug("#{from} sent a message to #{channel}: #{message}")
    {:noreply, state}
  end

  # Somebody highlighted us.
  def handle_info({:mentioned, message, sender, channel}, state) do
    from = sender.nick
    Logger.debug("#{from} mentioned us in #{channel}: #{message}")
    {:noreply, state}
  end

  # Somebody did /me ..
  def handle_info({:me, message, sender, channel}, state) do
    from = sender.nick
    Logger.debug("* #{from} #{message} in #{channel}")
    {:noreply, state}
  end

  # Catch-all for messages you don't care about
  def handle_info(msg, state) do
    Logger.debug("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end
end
