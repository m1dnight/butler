defmodule Butler.Import do
  @moduledoc """
  Import a weechat log file into the database.
  """
  def import(file, channel) do
    {:ok, res} = File.read!(file) |> WeechatParser.try_parse_log()

    res
    |> Enum.filter(fn x -> x.type == :message end)
    |> Enum.chunk_every(1000)
    |> Enum.each(fn chunk ->
      spawn(fn ->
        Enum.map(chunk, &process_message(&1, channel))
      end)
    end)
  end

  defp process_message(%{timestamp: ts, from: f, message: m}, channel) do
    msg = {:received, m, %{nick: f}, channel}
    send(Process.whereis(Butler.Plugins.Karma), msg)
    # send(Process.whereis(Butler.Plugins.Logger), m)
    Butler.Plugins.Logger.persist(%{
      from: f,
      content: m,
      channel: channel,
      inserted_at: ts
    })
  end
end
