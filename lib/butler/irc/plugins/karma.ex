defmodule Butler.Plugins.Karma do
  @moduledoc """
  The Karma plugin allows the bot to keep track of karma points for users.
  """
  use Butler.Plugin.Macros
  require Logger

  help do
    [
      {"`,<subject> ++/--`", "Increases (++) or decreases (--) the karma of <subject>."},
      {
        "`karma <subject>`",
        "Prints the karma of <subject> in the main channel."
      },
      {"`karmalist`", "Returns a webpage that contains the current karma list."},
      {"`karmatop`", "Prints out the top 15 of karma points in a private message."}
    ]
  end

  init_state do
    %{}
  end

  react ~r/[ \t]*(?<sub>[a-zA-Z0-9\.]+)(?<op>\+\+|--)[ \t]*/, e do
    sub = e.captures["sub"]
    op = e.captures["op"]
    load_state()
    |> Map.update(sub, 1, fn karma ->
      case op do
        "++" -> karma + 1
        "--" -> karma - 1
      end
    end)
    |> put_state()

    {:noreply, e.state}
  end

  react ~r/^,karma\s(?<sub>.+)/i, e do
    karma =
      load_state()
      |> Map.get(e.captures["sub"], 0)

    {:reply, "'#{e.captures["sub"]}' has #{karma} karma points.", e.state}
  end

  dm ~r/^[ \t]*,karmatop[ \t]*$/i, e do
    top =
      load_state()
      |> Enum.into([])
      |> Enum.sort_by(&elem(&1, 1), :desc)
      |> Enum.take(15)
      |> Enum.map_join("\n", fn {k, v} -> "#{k}: #{v}" end)

    {:reply, "Karma top 15\n#{top}", e.state}
  end
end
