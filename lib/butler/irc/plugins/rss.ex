defmodule Butler.Plugins.RSS do
  @moduledoc """
  Periodically fetches the latest entries from an RSS feed.
  """
  use Butler.Plugin.Macros
  require Logger
  import SweetXml

  @trigger 2000

  help do
    [
      {"`,rss`", "Checks for new RSS entries on https://elixirstatus.com/rss"}
    ]
  end

  init_state do
    %{}
  end

  trigger e do
    state = load_state()

    {:ok, entries} = fetch_entries("https://elixirstatus.com/rss")

    new_entries =
      entries
      |> Enum.reject(fn {title, _data} -> Map.has_key?(state, title) end)
      |> Enum.sort_by(fn {_, %{date: date}} -> date end, {:desc, DateTime})

    Map.merge(state, entries)
    |> put_state()

    case new_entries do
      [] ->
        {:noreply, e.state}

      # only print one article per trigger to avoid spam
      entries when length(entries) > 1 ->
        [{title, %{link: link, date: date}}] = Enum.take(entries, 1)

        {:reply, "#{date}: #{title}: #{link} (and #{Enum.count(entries) - 1} others)", e.state}

      [{title, %{link: link, date: date}}] ->
        {:reply, "#{date}: #{title}: #{link} (and #{Enum.count(entries) - 1} others)", e.state}
    end
  end

  def fetch_entries(feed_url) do
    with {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(feed_url),
         {:ok, parsed} <- parse_feed(body) do
      {:ok, parsed}
    else
      {:ok, %{status: status}} -> {:error, "HTTP request failed with status #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_feed(xml_body) do
    try do
      # Try RSS format first (uses <item>)
      entries =
        xpath(xml_body, ~x"//item"l,
          title: ~x"./title/text()"s,
          link: ~x"./link/text()"s,
          pub_date: ~x"./pubDate/text()"s
        )

      # If no items found, try Atom format (uses <entry>)

      # Convert keyword lists to tuples
      result =
        Enum.map(entries, fn entry ->
          link = String.trim(entry[:link] || "")
          date = parse_date(String.trim(entry[:pub_date] || ""))
          title = String.trim(entry[:title] || "")
          {title, %{link: link, date: date}}
        end)
        |> Enum.into(%{})

      {:ok, result}
    rescue
      e -> {:error, "Feed parsing failed: #{inspect(e)}"}
    end
  end

  def parse_date(""), do: nil
  def parse_date(nil), do: nil

  def parse_date(date_string) do
    # Try custom RFC2822 format: "22 Jan 2026 12:56:36 +0000"
    case Timex.parse(date_string, "{D} {Mshort} {YYYY} {h24}:{m}:{s} {Z}") do
      {:ok, datetime} ->
        datetime

      {:error, _} ->
        # Try ISO8601 for Atom feeds
        case Timex.parse(date_string, "{ISO:Extended}") do
          {:ok, datetime} ->
            datetime

          {:error, _} ->
            nil
        end
    end
  end
end
