defmodule Butler.Plugins.NickTracker do
  @moduledoc """
  The NickTracker plugin tracks nickname changes of users.
  """
  use Butler.Plugin.Macros

  help do
    [
      {"*", "Tracks previous nicknames for a user"}
    ]
  end

  init_state do
    %{}
  end

  # track nickname changes
  rename e do
    old_nick = e.old
    new_nick = e.new

    load_state()
    |> store_alias(old_nick, new_nick)
    |> put_state()

    {:noreply, e.state}
  end

  # mark the sender as currently seen now.
  react ~r/.*/, e do
    load_state()
    |> mark_seen(e.from)
    |> put_state()

    {:noreply, e.state}
  end

  react ~r/^[ \t]*,seen\s(?<user>[^\ \*\.]+)[ \t]*/, e do
    user = e.captures["user"]

    case Regex.compile(user) do
      {:ok, regex} ->
        last_seen = last_seen(load_state(), regex)

        reply =
          if Enum.count(last_seen) > 3 do
            "Too many results"
          else
            format_last_seens(last_seen)
          end

        {:reply, reply, e.state}

      {:error, _} ->
        {:reply, "No clue", e.state}
    end
  end

  ############################################################
  #                       Helpers                            #
  ############################################################

  defp store_alias(state, old_nick, new_nick) do
    state
    |> Map.update("nicks", %{old_nick => [new_nick]}, fn aliases ->
      Map.update(aliases, old_nick, [new_nick], fn aliases ->
        [new_nick | aliases]
      end)
    end)
  end

  # update the last seen timestamp for a user
  defp mark_seen(state, user) do
    Map.update(
      state,
      "seens",
      %{user => DateTime.utc_now()},
      &Map.put(&1, user, DateTime.utc_now())
    )
  end

  # return a list of the matching users and the timestamp they were last seen.
  defp last_seen(state, user_regex) do
    state
    |> Map.get("seens", %{})
    |> Enum.filter(fn {k, _v} ->
      Regex.match?(user_regex, k)
    end)
  end

  # format a list of nicks and their timestamp into a message
  def format_last_seens(seens) do
    seens
    |> Enum.map(fn {k, v} ->
      {:ok, date, _} = DateTime.from_iso8601(v)
      timestamp = Timex.format!(date, "%d %b %Y, %H:%M", :strftime)
      {k, timestamp}
    end)
    |> Enum.map_join(", ", fn {k, v} -> "#{k} at #{v}" end)
  end
end
