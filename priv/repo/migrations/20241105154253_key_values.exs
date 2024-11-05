defmodule Butler.Repo.Migrations.KeyValues do
  use Ecto.Migration

  def change do
    create table(:plugin_key_values) do
      add(:module, :string)
      add(:key, :string)
      add(:value, :map, default: %{})
    end
  end
end
