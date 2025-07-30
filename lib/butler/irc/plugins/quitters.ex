defmodule Butler.Plugins.Quitters do
  @moduledoc """
  The Quitters plugin keeps track of people who join, and leave immediately.
  """
  use Butler.Plugin.Macros
  require Logger

  help do
    []
  end

  init_state do
    %{}
  end

  join e do
    seen? = last_seen(load_state(), e.nick) != nil

    IO.inspect(e, label: "e")
    load_state()
    |> mark_joined(e.nick)
    |> put_state()

    if not seen? do
      {:reply,
       "Welcome to #elixir! If you have questions, please wait around a bit. It can take a few hours for people to see your message. All praise Jose.",
       e.state}
    else
      {:noreply, e.state}
    end
  end

  leave e do
    # mark the user as left
    load_state()
    |> mark_left(e.nick)
    |> put_state()

    state = load_state()

    # get the current shortest stay, if there is one
    record = shortest_stay(load_state())
    user_stay_duration = stay_time(load_state(), e.nick)

    # update the user's stay duration
    load_state()
    |> put_stay_duration(e.nick, user_stay_duration)
    |> put_state()

    case record do
      nil ->
        {:reply, "New record! #{e.nick} stayed for #{user_stay_duration} seconds!", e.state}

      {record_holder, record} ->
        if record > user_stay_duration do
          {:reply,
           "New record! #{e.nick} stayed for #{user_stay_duration} seconds! #{record_holder} stayed for just #{record} seconds.",
           e.state}
        else
          {:noreply, e.state}
        end
    end
  end

  ############################################################
  #                       Helpers                            #
  ############################################################

  # update the last seen timestamp for a user
  defp mark_joined(state, user) do
    Map.update(
      state,
      "joins",
      %{user => DateTime.utc_now()},
      &Map.put(&1, user, DateTime.utc_now())
    )
  end

  defp last_seen(state, user) do
    get_in(state, ["joins", user])
  end

  defp mark_left(state, user) do
    Map.update(
      state,
      "leaves",
      %{user => DateTime.utc_now()},
      &Map.put(&1, user, DateTime.utc_now())
    )
  end

  defp shortest_stay(state) do
    Map.get(state, "durations", %{})
    |> Enum.sort_by(&elem(&1, 1), :asc)
    |> List.first()
  end

  defp put_stay_duration(state, user, duration) do
    Map.update(
      state,
      "durations",
      %{user => duration},
      &Map.put(&1, user, duration)
    )
  end

  defp stay_time(state, user) do
    joined = get_in(state, ["joins", user])
    left = get_in(state, ["leaves", user])

    with {:ok, joined, _} <- DateTime.from_iso8601(joined),
         {:ok, left, _} <- DateTime.from_iso8601(left) do
      DateTime.diff(left, joined)
    else
      _ -> 1_000_000
    end
  end
end
