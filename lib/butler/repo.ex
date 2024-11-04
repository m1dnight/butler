defmodule Butler.Repo do
  use Ecto.Repo,
    otp_app: :butler,
    adapter: Ecto.Adapters.SQLite3
end
