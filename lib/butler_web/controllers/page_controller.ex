defmodule ButlerWeb.PageController do
  use ButlerWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    messages = Butler.Repo.all(Butler.Plugins.Logger, order_by: [desc: :inserted_at])
    |> Enum.take(25)
    |> tap(fn x -> IO.inspect(x, label: "msgs") end)
    render(conn, :home, messages: messages)
  end
end
