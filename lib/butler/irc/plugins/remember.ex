defmodule Butler.Plugins.Remember do
  @moduledoc """
  The Remember plugin allows the bot to remember things for you.
  It's like a database for keywords.
  """
  use Butler.Plugin.Macros

  help do
    [
      {
        "`remember <subject> is <value>`",
        "Remembers that <subject> is <value>."
      },
      {"`<subject>?`", "If <subject> is a known alias, prints out its value."}
    ]
  end

  init_state do
    %{}
  end

  react ~r/^[ \t]*,remember (?<sub>.+) is (?<exp>.+)[ \t]*/i, e do
    sub = e.captures["sub"]
    exp = e.captures["exp"]

    load_state()
    |> Map.put(sub, exp)
    |> put_state()

    {:reply, "I noted that '#{sub}' is '#{exp}'", e.state}
  end

  react ~r/^[ \t]*,(?<sub>.+?)[ \t]*\?[ \t]*/i, e do
    sub = e.captures["sub"]

    answer =
      case Map.get(load_state(), sub) do
        nil -> "I don't know what '#{sub}' is."
        value -> "#{sub} is #{value}"
      end

    {:reply, "#{answer}", e.state}
  end
end
