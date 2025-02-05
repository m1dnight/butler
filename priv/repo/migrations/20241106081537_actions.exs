defmodule Butler.Repo.Migrations.Messages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add(:is_action, :boolean, default: false)
    end
  end
end
