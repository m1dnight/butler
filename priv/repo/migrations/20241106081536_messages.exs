defmodule Butler.Repo.Migrations.Messages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add(:from, :string)
      add(:content, :string)
      add(:channel, :string)
      add(:inserted_at, :utc_datetime)
    end
  end
end
