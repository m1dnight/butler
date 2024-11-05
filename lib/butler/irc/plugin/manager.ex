defmodule Butler.Plugin.Manager do
  use GenServer
  require Logger

  ################################################################################
  # API

  def register(module, help) do
    send(__MODULE__, {:register, module, help})
  end

  def get_help(module) do
    GenServer.call(__MODULE__, {:get_help, module})
  end

  def registered_plugins do
    GenServer.call(__MODULE__, :registered_plugins)
  end

  ################################################################################
  # Callbacks

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([client, config]) do
    {:ok, {client, config, %{}}}
  end

  ################################################################################
  # Message handlers

  def handle_call(:registered_plugins, _from, {client, config, plugins}) do
    plugin_list =
      plugins
      |> Enum.map(fn {p, _h} -> p end)

    {:reply, plugin_list, {client, config, plugins}}
  end

  def handle_call({:get_help, module}, _from, {client, config, plugins}) do
    {:reply, Map.get(plugins, module, nil), {client, config, plugins}}
  end

  def handle_info({:register, plugin, helps}, {client, config, plugins}) do
    Logger.debug("Registering #{inspect(plugin)}: #{inspect(helps)}")

    plugins = Map.put(plugins, plugin, helps)
    {:noreply, {client, config, plugins}}
  end

  # Catch-all for messages you don't care about
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
