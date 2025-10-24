defmodule Armitage.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Armitage.Repo,
      ArmitageWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:armitage, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Armitage.PubSub},
      # Start the Finch HTTP client for sending emails
      #{Finch, name: Req.Finch},
      # Start a worker by calling: Armitage.Worker.start_link(arg)
      # {Armitage.Worker, arg},
      # Start to serve requests, typically the last entry
      maybe_scheduler(),
      ArmitageWeb.Endpoint
    ]
    |> Enum.filter(& &1)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Armitage.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ArmitageWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp maybe_scheduler do
    if Application.get_env(:armitage,:enable_scheduler,:false) do
      Armitage.Scheduler
    else
      nil
    end
  end
end
