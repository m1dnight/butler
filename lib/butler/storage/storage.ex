defmodule Butler.Storage do
  @moduledoc """
  Defines functions to read/write state to the database.
  """
  alias Butler.Repo
  import Ecto.Query
  alias Butler.Storage.KeyValue
  alias Ecto.Multi

  def load_state(module) do
    module_name = "#{module}"
    Repo.one(from k in KeyValue, where: k.module == ^module_name)
  end

  def put_state(module, state) when is_map(state) do
    module_name = "#{module}"

    Ecto.Multi.new()
    |> Multi.run(:load, fn _repo, _changes_so_far ->
      if kv = load_state(module) do
        KeyValue.changeset(kv, %{value: state})
        |> Butler.Repo.update()
      else
        Repo.insert(%KeyValue{module: module_name, value: state})
      end
    end)
    |> Repo.transaction(mode: :immediate)
  end
end
