defmodule HubRegistration.Worker do
  use GenServer
  require Logger
  alias Nerves.Leds

  #@ssid System.get_env("SSID")
  #@psk System.get_env("PSK")
  @registration_url System.get_env("REGISTRATION_URL")

  @success_duration  100 # ms
  @error_duration 500 # ms

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    SystemRegistry.register
    {:ok, {"wlan0", nil}}
  end

  def handle_info({:system_registry, :global, registry}, {iface, current}) do
    ip = get_in(registry, [:state, :network_interface, "wlan0", :ipv4_address])

    if ip != current do
      Logger.info("Registry: #{inspect registry}")
      Logger.info "IP Address Changed: #{ip}"
      register_device()
    end
    {:noreply, {iface, ip}}
  end

  def handle_info({:system_registry, _, _}, {iface, current}) do
    {:noreply, {iface, current}}
  end

  defp register_device() do
    mac_address()
    |> post()
    |> blink()
  end

  defp post({:ok, mac_address}) do
    Logger.info "POSTING: #{@registration_url}"
    Logger.info "ID: #{inspect mac_address}"
    case HTTPoison.post(@registration_url, {:form, [{:mac_address, mac_address}]}, [{"content-type", "application/x-www-form-urlencoded"}]) do
      {:ok, %HTTPoison.Response{status_code: 200}} -> :success
      {_other, %HTTPoison.Response{} = resp} ->
        Logger.error("#{inspect resp}")
        :error
      other -> Logger.error("#{inspect other}")

    end
  end

  defp mac_address do
    id = try do
      {id, 0} = System.cmd("/usr/bin/boardid", ["-b", "rpi"])
      id |> String.split("\n") |> List.first
    rescue
      e in ErlangError ->
        Logger.info "#{inspect e}"
        "123456789"
    end
    {:ok, id}
  end

  defp blink(:success), do: blink(@success_duration)
  defp blink(:error), do: blink(@error_duration)
  defp blink(duration) do
    Leds.set [{:green, true}]
    :timer.sleep duration
    Leds.set [{:green, false}]
    :timer.sleep duration
    blink(duration)
  end
end
