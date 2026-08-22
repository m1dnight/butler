defmodule Butler.Repo.Migrations.ActionsUpdate do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add(:is_action, :boolean, default: false)
    end
  end
end
