defmodule HubRegistration.Mixfile do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"
  Mix.shell.info([:green, """
  Env
    MIX_TARGET:   #{@target}
    MIX_ENV:      #{Mix.env}
  """, :reset])
  def project do
    [app: :hub_registration,
     version: "0.1.0",
     elixir: "~> 1.6",
     target: @target,
     archives: [nerves_bootstrap: "~> 1.0"],
     deps_path: "deps/#{@target}",
     build_path: "_build/#{@target}",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(@target),
     deps: deps()]
  end

  def application, do: application(@target)

  def application("host") do
    [extra_applications: [:logger]]
  end
  def application(_target) do
    [mod: {HubRegistration.Application, []},
     extra_applications: [:logger, :httpoison, :nerves_runtime, :nerves_leds, :nerves_network]]
  end

  def deps do
    [
      {:nerves, "~> 0.9.4", runtime: false},
      {:httpoison, "~> 0.12.0"},

    ] ++
    deps(@target)
  end

  # Specify target specific dependencies
  def deps("host"), do: []
  def deps(target) do
    [
      {:"nerves_system_#{target}", "~> 0.20.0", runtime: false},
      {:nerves_leds, "~> 0.8.0"},
      {:nerves_runtime, "~> 0.5.3"},
      {:nerves_network, "~> 0.3.6"}
    ]
  end

  # We do not invoke the Nerves Env when running on the Host
  def aliases("host"), do: []
  def aliases(_target) do
    [] |> Nerves.Bootstrap.add_aliases()
  end

end
