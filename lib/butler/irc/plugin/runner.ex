defmodule Butler.Plugin.Runner do
  @moduledoc """
  Defines the process that runs a plugin.
  """

  use GenServer
  require Logger

  alias Butler.Plugin.Runner
  alias Butler.Plugin.Manager

  defstruct module: nil, module_state: nil, client: nil, config: nil

  ################################################################################
  # Callbacks

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init([module, client, config]) do
    # Register the runner as the plugin module name.
    Process.register(self(), module)

    # initialize the plugin
    if Keyword.has_key?(module.__info__(:functions), :init) do
      module.init()
    end

    # Register with the manager.
    helps =
      if Keyword.has_key?(module.__info__(:functions), :help) do
        module.help()
      else
        []
      end

    Manager.register(module, helps)

    # Listen to incoming messages from ExIRC.
    ExIRC.Client.add_handler(client, self())

    # Get the initial state from the module.
    mod_state =
      if Keyword.has_key?(module.__info__(:functions), :initial_state) do
        module.initial_state()
      else
        nil
      end

    # Initial runner state.
    state = %Runner{module: module, client: client, config: config, module_state: mod_state}
    {:ok, state}
  end

  #############################################################################
  # Nickchange

  def handle_info({:nick_changed, old, new}, state) do
    if Kernel.function_exported?(state.module, :rename, 1) do
      mod_state = execute_rename(state.module.rename, old, new, state)
      state = %{state | module_state: mod_state}
      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  ##############################################################################
  # Direct message.

  def handle_info({:received, message, sender}, state) do
    state =
      state.module.dms
      |> Enum.reduce(state, fn dm_reaction, state ->
        mod_state = execute_dm(dm_reaction, message, sender, state)
        %{state | module_state: mod_state}
      end)

    {:noreply, state}
  end

  ##############################################################################
  # Message in channel.

  def handle_info({:received, message, sender, channel}, state) do
    # Call the module its actions and accumulate the state.
    state =
      state.module.reactions
      |> Enum.reduce(state, fn reaction, state ->
        mod_state = execute_react(reaction, message, sender, channel, state)
        %{state | module_state: mod_state}
      end)

    {:noreply, state}
  end

  ##############################################################################
  # /me message

  def handle_info({:me, message, sender, channel}, state) do
    # Call the module its actions and accumulate the state.
    state =
      state.module.observations()
      |> Enum.reduce(state, fn observation, state ->
        mod_state = execute_observation(observation, message, sender, channel, state)
        %{state | module_state: mod_state}
      end)

    {:noreply, state}
  end

  ##############################################################################
  # Catch-all.

  def handle_info(_m, state) do
    {:noreply, state}
  end

  ##############################################################################
  # Helpers

  # ----------------------------------------------------------------------------
  # Handler for nick changes.

  def execute_rename(rename, old_nick, new_nick, state) do
    m = rename.module
    f = rename.func
    o = rename.opts

    p = 1.0 - Keyword.get(o, :probability, 1.0)

    if :rand.uniform() >= p do
      event = %{
        old: old_nick,
        new: new_nick,
        state: state.module_state,
        config: state.config
      }

      case apply(m, f, [event]) do
        {:noreply, mod_state} ->
          mod_state

        r ->
          Logger.error(
            "Response from nick change in #{inspect(state.module)} is invalid!: #{inspect(r)}"
          )
      end
    else
      state.module_state
    end
  end

  # ----------------------------------------------------------------------------
  # Handler for channel messages.

  def execute_react(react, message, sender, channel, state) do
    from = sender.nick

    r = react.regex
    m = react.module
    f = react.func
    o = react.opts

    p = 1.0 - Keyword.get(o, :probability, 1.0)

    if :rand.uniform() >= p and Regex.match?(r, message) do
      named_captures = Regex.named_captures(r, message)

      event = %{
        from: from,
        message: message,
        channel: channel,
        captures: named_captures,
        state: state.module_state,
        config: state.config
      }

      case apply(m, f, [event]) do
        {:noreply, mod_state} ->
          mod_state

        {:reply, response, mod_state} ->
          lines = response |> String.split("\n") |> Enum.filter(&(&1 != ""))

          for line <- lines do
            ExIRC.Client.msg(state.client, :privmsg, channel, line)
            Process.sleep(500)
          end

          mod_state

        r ->
          Logger.error(
            "Response from reaction in #{inspect(state.module)} is invalid!: #{inspect(r)}"
          )
      end
    else
      state.module_state
    end
  end

  # ----------------------------------------------------------------------------
  # Handler for channel actions.

  def execute_observation(observation, message, sender, channel, state) do
    from = sender.nick

    r = observation.regex
    m = observation.module
    f = observation.func
    o = observation.opts

    p = 1.0 - Keyword.get(o, :probability, 1.0)

    if :rand.uniform() >= p and Regex.match?(r, message) do
      named_captures = Regex.named_captures(r, message)

      event = %{
        from: from,
        message: message,
        channel: channel,
        captures: named_captures,
        state: state.module_state,
        config: state.config
      }

      case apply(m, f, [event]) do
        {:noreply, mod_state} ->
          mod_state

        {:reply, response, mod_state} ->
          lines = response |> String.split("\n") |> Enum.filter(&(&1 != ""))

          for line <- lines do
            ExIRC.Client.msg(state.client, :privmsg, channel, line)
            Process.sleep(500)
          end

          mod_state

        r ->
          Logger.error(
            "Response from observation in #{inspect(state.module)} is invalid!: #{inspect(r)}"
          )
      end
    else
      state.module_state
    end
  end

  # ----------------------------------------------------------------------------
  # Handlers for direct messages.

  def execute_dm(dm_reaction, message, sender, state) do
    r = dm_reaction.regex
    m = dm_reaction.module
    f = dm_reaction.func
    o = dm_reaction.opts

    from = sender.nick

    p = 1.0 - Keyword.get(o, :probability, 1.0)

    if :rand.uniform() >= p and Regex.match?(r, message) do
      named_captures = Regex.named_captures(r, message)

      event = %{
        from: from,
        message: message,
        channel: from,
        captures: named_captures,
        state: state.module_state,
        config: state.config
      }

      case apply(m, f, [event]) do
        {:noreply, mod_state} ->
          mod_state

        {:reply, response, mod_state} ->
          lines = response |> String.split("\n") |> Enum.filter(&(&1 != ""))

          for line <- lines do
            ExIRC.Client.msg(state.client, :privmsg, from, line)
            Process.sleep(500)
          end

          mod_state

        _ ->
          Logger.error("Response from dm in #{inspect(state.module)} is invalid!")
      end
    else
      state.module_state
    end
  end
end
