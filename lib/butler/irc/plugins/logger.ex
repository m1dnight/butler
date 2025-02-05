defmodule Butler.Plugins.Logger do
  @moduledoc """
  Logs the messages in the channel to the database.
  """
  use Butler.Plugin.Macros

  defrecord table: "messages" do
    field :from, :string
    field :content, :string
    field :channel, :string
    field :inserted_at, :utc_datetime
    field :is_action, :boolean
  end

  help do
    {"*", "Logs all the messages and shows them through the webinterface."}
  end

  react ~r/.*/, e do
    # Log messages.
    {:ok, _} =
      persist(%{
        from: e.from,
        content: e.message,
        channel: e.channel,
        inserted_at: DateTime.utc_now(),
        is_action: false
      })

    {:noreply, e.state}
  end

  observe ~r/.*/, e do
    # Log messages.
    {:ok, _} =
      persist(%{
        from: e.from,
        content: e.message,
        channel: e.channel,
        inserted_at: DateTime.utc_now(),
        is_action: true
      })

    {:noreply, e.state}
  end

  #############################################################################
  # Helpers
  def filter_url(string) do
    ~r"http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+"
    |> Regex.scan(string)
    |> Enum.flat_map(& &1)
  end
end
