defmodule Butler.Storage.KeyValue do
  @moduledoc """
  Defines the schema for storing key-value pairs in the database.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "plugin_key_values" do
    field :module, :string
    field :value, :map, default: %{}
  end

  @doc false
  def changeset(key_value, attrs) do
    key_value
    |> cast(attrs, [:module, :value])
    |> validate_required([:module, :value])
  end
end
