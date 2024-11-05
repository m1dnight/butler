defmodule Butler.Plugin.Supervisor do
  use Supervisor

  alias Butler.Plugin.Runner

  require Logger

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init([exirc_client, config]) do
    Logger.debug("starting plugin supervisor")
    # Create runner child specs for all the modules in the config file.
    children =
      config
      |> Map.get(:plugins)
      |> Enum.map(fn module ->
        Supervisor.child_spec({Runner, [module, exirc_client, config]}, id: module)
      end)

    children =
      [
        {Butler.Plugin.Manager, [exirc_client, config]}
      ] ++ children

    Supervisor.init(children, strategy: :one_for_all)
  end
end
