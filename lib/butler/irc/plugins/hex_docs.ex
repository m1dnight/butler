defmodule Butler.Plugins.HexDocs do
  @moduledoc """
  Searches the documentation on hexdocs.pm.

  Queries go to https://search.hexdocs.pm, the search index behind the search
  box on hexdocs.pm.
  """
  use Butler.Plugin.Macros

  @search_url "https://search.hexdocs.pm/"
  @hexdocs_url "https://hexdocs.pm"

  # Sections of a function are documents of their own, titled after the section
  # they document, and they answer nothing that the function does not.
  @groups 100

  help do
    [
      {"`,fun <query>`", "Searches the documentation on hexdocs.pm for a specific function."},
      {"`,behaviour <query>`",
       "Searches the documentation on hexdocs.pm for a specific behaviour."},
      {"`,search <query>`",
       "Searches the documentation on hexdocs.pm without any type filtering."}
    ]
  end

  hear ~r/^[ \t]*,fun\s+(?<query>.+?)[ \t]*$/i, e do
    {:reply, search_fun(e.captures["query"]), e.state}
  end

  hear ~r/^[ \t]*,behaviour\s+(?<query>.+?)[ \t]*$/i, e do
    {:reply, search_behaviour(e.captures["query"]), e.state}
  end

  hear ~r/^[ \t]*,search\s+(?<query>.+?)[ \t]*$/i, e do
    {:reply, search_free(e.captures["query"]), e.state}
  end

  defp search_fun(query) do
    URI.encode_query(
      q: query,
      query_by: "title",
      filter_by: "type:=function && title:!=Examples*",
      group_by: "package",
      group_limit: 10,
      per_page: @groups
    )
    |> search()
  end

  defp search_behaviour(query) do
    URI.encode_query(
      q: query,
      query_by: "title",
      filter_by: "type:=behaviour && title:!=Examples*",
      group_by: "package",
      per_page: @groups
    )
    |> search()
  end

  defp search_free(query) do
    URI.encode_query(
      q: query,
      query_by: "title",
      group_by: "package",
      per_page: @groups
    )
    |> search()
  end

  defp search(params) do
    # Names are looked for in the title. Matching them against the body of the
    # documentation only finds every page that mentions them in a sentence.

    with {:ok, %{status_code: 200, body: body}} <- get(@search_url <> "?" <> params),
         {:ok, %{"grouped_hits" => groups}} <- Jason.decode(body) do
      sort(groups)
    else
      {:ok, %{status_code: status}} -> "The search came back with #{status}."
      {:error, reason} -> "I can't reach the search: #{inspect(reason)}."
    end
  end

  defp get(url) do
    HTTPoison.get(url, [], recv_timeout: 15_000, timeout: 15_000)
  end

  # always make the elixir packages go to the top. search for explicit packages
  # works by just adding the package name to it.
  defp sort(groups) do
    groups
    |> Enum.sort_by(&String.jaro_distance(hd(&1["group_key"]), "elixir"), :desc)
    |> format()
  end

  # A package is grouped per version, so every group holds one version of one
  # package. Answering from the first group answers from the best matching one,
  # and the same function cannot turn up twice.
  defp format([]) do
    "Nothing found."
  end

  # sort the results by length of their title (probably closest match?)
  defp format([group | _rest]) do
    group["hits"]
    |> Enum.sort_by(&String.length(get_in(&1, ["document", "title"])), :asc)
    |> Enum.take(5)
    |> Enum.map_join(" || ", &line/1)
  end

  defp line(%{"document" => document}) do
    # \x02	bold
    # \x1D	italic
    # \x1F	underline
    # \x1E	strikethrough
    # \x11	monospace
    # \x03NN	colour, NN = foreground; \x03NN,MM adds a background
    # \x0F	reset everything
    # Colours 00–15: 00 white, 01 black, 02 blue, 03 green, 04 red, 05 brown, 06
    # magenta, 07 orange, 08 yellow, 09 light green, 10 cyan, 11 light cyan, 12
    # light blue, 13 pink, 14 grey, 15 light grey.
    "\x1F\x1D\x02#{document["title"]}\x0F: \x0314 #{url(document)}\x0F"
  end

  # The index keys a package as "name-version", and a package name never
  # contains a hyphen while a version regularly does. The version is left out
  # of the link: hexdocs serves the newest release from a link without one.
  defp url(%{"package" => package, "ref" => ref}) do
    [name | _version] = String.split(package, "-", parts: 2)
    "#{@hexdocs_url}/#{name}/#{ref}"
  end
end
