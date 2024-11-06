defmodule Butler.Plugin.Macros do
  @moduledoc """
  Contains the macro definitions for the Butler plugin system.
  """
  defmacro __using__(_options) do
    caller = __CALLER__.module

    quote do
      require Logger
      import unquote(__MODULE__)
      alias unquote(caller)
      use TypedEctoSchema

      Module.register_attribute(__MODULE__, :reactions, accumulate: true)
      Module.register_attribute(__MODULE__, :dms, accumulate: true)
      Module.register_attribute(__MODULE__, :rename, accumulate: false)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def reactions, do: @reactions

      def dms, do: @dms

      def rename, do: @rename
    end
  end

  #############################################################################
  # Records

  defmacro defrecord(opts, do: fields) do
    caller_module = __CALLER__.module
    {:__block__, [], field_entries} = fields

    field_names = Enum.map(field_entries, fn {_, _, [name, _type]} -> name end)

    quote do
      @table_name unquote(opts[:table])

      typed_schema unquote(opts[:table]) do
        unquote(fields)
      end

      def changeset(record, attrs) do
        record
        |> Ecto.Changeset.cast(attrs, unquote(field_names))
      end

      def persist(record) do
        struct(unquote(caller_module))
        |> changeset(record)
        |> Butler.Repo.insert()
      end
    end
  end

  #############################################################################
  # State

  defmacro init_state(do: initial_state) do
    caller = __CALLER__.module

    quote do
      def init do
        if Butler.Storage.load_state(unquote(caller)) == nil do
          Butler.Storage.put_state(unquote(caller), unquote(initial_state))
        end
      end
    end
  end

  defmacro init_state(_opts, do: initial_state) do
    caller = __CALLER__.module

    quote do
      def init do
        if Butler.Storage.load_state(unquote(caller)) == nil do
          Butler.Storage.put_state(unquote(caller), unquote(initial_state))
        end
      end
    end
  end

  defmacro load_state do
    caller = __CALLER__.module

    quote do
      Butler.Storage.load_state(unquote(caller))
      |> Map.get(:value)
    end
  end

  defmacro put_state(state) do
    caller = __CALLER__.module

    quote do
      Butler.Storage.put_state(unquote(caller), unquote(state))
    end
  end

  ##############################################################################
  # Define help string.

  defmacro help(do: body) do
    quote do
      def help do
        unquote(body)
      end
    end
  end

  #############################################################################
  # React to nickname changes.

  defmacro rename(event_var, do: action_block) do
    quote do
      rename(unquote(event_var), [], do: unquote(action_block))
    end
  end

  defmacro rename(event_var, options, do: action_block) do
    func_name = "rename" |> String.to_atom()

    quote do
      @rename %{
        func: unquote(func_name),
        opts: unquote(options),
        module: __MODULE__
      }

      def unquote(func_name)(unquote(event_var)) do
        unquote(action_block)
      end
    end
  end

  #############################################################################
  # React to both dm's and public messages.

  defmacro hear(regex, event_var, do: action_block) do
    quote do
      dm(unquote(regex), unquote(event_var), do: unquote(action_block))

      react(unquote(regex), unquote(event_var), do: unquote(action_block))
    end
  end

  ##############################################################################
  # React to direct messages

  defmacro dm(regex, event_var, do: action_block) do
    quote do
      def_dm(unquote(regex), unquote(event_var), [], do: unquote(action_block))
    end
  end

  defmacro def_dm(regex, event_var, options, do: action_block) do
    func_name = "dm_#{inspect(regex)}" |> String.to_atom()

    quote do
      @dms %{
        regex: unquote(regex),
        func: unquote(func_name),
        opts: unquote(options),
        module: __MODULE__
      }

      def unquote(func_name)(unquote(event_var)) do
        unquote(action_block)
      end
    end
  end

  ##############################################################################
  # React reacts to an incoming message in a channel.

  defmacro react(regex, event_var, do: action_block) do
    quote do
      def_react(unquote(regex), unquote(event_var), [], do: unquote(action_block))
    end
  end

  defmacro react(regex, event_var, options, do: action_block) do
    quote do
      def_react(unquote(regex), unquote(event_var), unquote(options), do: unquote(action_block))
    end
  end

  defmacro def_react(regex, event_var, options, do: action_block) do
    func_name = "reaction_#{inspect(regex)}" |> String.to_atom()

    quote do
      @reactions %{
        regex: unquote(regex),
        func: unquote(func_name),
        opts: unquote(options),
        module: __MODULE__
      }

      def unquote(func_name)(unquote(event_var)) do
        unquote(action_block)
      end
    end
  end
end
