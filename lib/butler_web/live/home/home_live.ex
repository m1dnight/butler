defmodule ButlerWeb.HomeLive do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use ButlerWeb, :live_view

  alias Butler.Plugins.Logger
  alias Contex.BarChart
  alias Contex.Dataset
  alias Contex.Plot
  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    # subscribe to updates of new messages
    PubSub.subscribe(Butler.PubSub, "plugin")

    {:ok, put_assigns(socket)}
  end

  def handle_info(%Logger{}, socket) do
    {:noreply, put_assigns(socket)}
  end

  ############################################################
  #                       Helpers                            #
  ############################################################

  # @doc """
  # Updates the socket with the computed values from the database. This is done
  # every update, because the data is all changed as soon as a new message
  # arrives.
  # """
  defp put_assigns(socket) do
    messages = Butler.Data.last_n_messages(10) |> Enum.reverse()
    karmas_top = Butler.Data.karma_top(10)
    karmas_bottom = Butler.Data.karma_bottom(10)
    message_count = Butler.Data.most_active(10)
    avg_per_day = Butler.Data.average_messages_per_day()
    users = Butler.Data.known_users()
    average_message_length = Butler.Data.average_message_length()
    most_active_day = Butler.Data.most_active_day()
    day_totals = Butler.Data.day_totals(14)
    hour_totals = Butler.Data.hour_totals()
    month_totals = Butler.Data.month_totals()

    socket
    |> assign(:messages, messages)
    |> assign(:karmas_top, karmas_top)
    |> assign(:karmas_bottom, karmas_bottom)
    |> assign(:message_count, message_count)
    |> assign(:average_message_per_day, avg_per_day)
    |> assign(:known_users, users)
    |> assign(:average_message_length, average_message_length)
    |> assign(:most_active_day, most_active_day)
    |> assign(:day_totals, day_totals)
    |> assign(:hour_totals, hour_totals)
    |> assign(:month_totals, month_totals)
  end

  defp build_pointplot(day_totals) do
    day_totals =
      day_totals
      |> Enum.map(fn %{count: count, day: day} ->
        {day, count}
      end)

    options = [
      mapping: %{category_col: "Bucket", value_cols: ["Value"]},
      orientation: :horizontal,
      colour_palette: Enum.shuffle(["ff9838", "fdae53", "fbc26f", "fad48e", "fbe5af", "fff5d1"])
    ]

    test_data = Dataset.new(day_totals, ["Bucket", "Value"])

    Plot.new(test_data, BarChart, 500, 400, options)
    |> Plot.axis_labels("", "")
    |> Plot.to_svg()
  end
end
