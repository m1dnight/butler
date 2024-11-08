defmodule ButlerWeb.PageController do
  use ButlerWeb, :controller

  def home(conn, _params) do
    messages = Butler.Data.last_n_messages(25)
    render(conn, :home, messages: messages)
  end
end
