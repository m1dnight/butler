defmodule ButlerWeb.Plugs.AccessToken do
  @moduledoc """
  Checks if the url contains a query parameter to give access to the user.
  """
  import Plug.Conn

  @token_validity 1 * 60 * 60
  def init(options) do
    init_table()
    options
  end

  def call(conn, _opts) do
    init_table()

    case conn.params do
      %{"token" => token} ->
        if valid_token?(token) do
          conn
        else
          unauthorized(conn)
        end

      _ ->
        unauthorized(conn)
    end
  end

  def create_token do
    init_table()
    token = Base.encode16(:crypto.strong_rand_bytes(8))
    :ets.insert(:access_tokens, {token, DateTime.utc_now()})
    token
  end

  def valid_token?(token) do
    init_table()

    case :ets.lookup(:access_tokens, token) do
      [{^token, created_at}] ->
        valid? = DateTime.diff(DateTime.utc_now(), created_at) < @token_validity

        # cleanup token if invalid
        if not valid? do
          :ets.delete(:access_tokens, token)
        end

        valid?

      _ ->
        false
    end
  end

  defp unauthorized(conn) do
    conn
    |> resp(401, "Unauthorized")
    |> halt()
  end

  defp init_table do
    # start an ets table to hold the valid tokens
    if :undefined == :ets.whereis(:access_tokens) do
      :ets.new(:access_tokens, [:set, :public, :named_table])
    end
  end
end
