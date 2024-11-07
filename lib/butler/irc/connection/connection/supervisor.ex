defmodule Butler.Irc.Connection do
  @moduledoc """
  Supervisor for the IRC connection.
  """
  use Supervisor

  require Logger

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    config = config()
    Logger.debug("config: #{inspect(config)}")

    children = [
      %{id: ExIRC.Client, start: {ExIRC.Client, :start_link, [[], [name: ExIRC.Client]]}},
      {Butler.Irc.ConnectionHandler, [ExIRC.Client, config]},
      {Butler.Irc.LoginHandler, [ExIRC.Client, config]},
      {Butler.Irc.MessageHandler, [ExIRC.Client, config]},
      {Butler.Plugin.Supervisor, [ExIRC.Client, config]}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  defp config do
    server = Application.get_env(:butler, :server)
    port = Application.get_env(:butler, :port)
    nickname = Application.get_env(:butler, :nickname)
    password = Application.get_env(:butler, :password)
    user = Application.get_env(:butler, :user)
    channels = Application.get_env(:butler, :channels)
    plugins = Application.get_env(:butler, :plugins)

    %{
      server: server,
      port: port,
      nickname: nickname,
      password: password,
      user: user,
      channels: channels,
      plugins: plugins
    }
  end
end
