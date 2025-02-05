defmodule ButlerWeb.HomeLive do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use ButlerWeb, :live_view

  alias Phoenix.PubSub
  alias Butler.Plugins.Logger

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

    socket
    |> assign(:messages, messages)
    |> assign(:karmas_top, karmas_top)
    |> assign(:karmas_bottom, karmas_bottom)
    |> assign(:message_count, message_count)
    |> assign(:average_message_per_day, avg_per_day)
    |> assign(:known_users, users)
    |> assign(:average_message_length, average_message_length)
    |> assign(:most_active_day, most_active_day)
  end
end
