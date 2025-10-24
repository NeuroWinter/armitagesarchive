# lib/armitage/scheduler.ex
defmodule Armitage.Scheduler do
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    schedule_sync()
    {:ok, state}
  end

  def handle_info(:sync_data, state) do
    Logger.info("Starting scheduled Readwise sync")

    Task.start(fn ->
      try do
        Armitage.Release.sync_new_data()
        Logger.info("Scheduled sync completed successfully")
      rescue
        e ->
          Logger.error("Scheduled sync failed: #{inspect(e)}")
      end
    end)

    schedule_sync()
    {:noreply, state}
  end

  defp schedule_sync do
    hours = Application.get_env(:armitage, :sync_interval_hours, 6)
    Process.send_after(self(), :sync_data, hours * 60 * 60 * 1000)
    Logger.info("Next sync scheduled in #{hours} hours")
  end

  def trigger_sync do
    GenServer.cast(__MODULE__, :sync_now)
  end

  def handle_cast(:sync_now, state) do
    send(self(), :sync_data)
    {:noreply, state}
  end
end
