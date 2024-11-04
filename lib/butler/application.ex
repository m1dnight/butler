defmodule Butler.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ButlerWeb.Telemetry,
      Butler.Repo,
      {DNSCluster, query: Application.get_env(:butler, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Butler.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Butler.Finch},
      # Start a worker by calling: Butler.Worker.start_link(arg)
      # {Butler.Worker, arg},
      # Start to serve requests, typically the last entry
      ButlerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Butler.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ButlerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
