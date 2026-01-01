defmodule Quando.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/vectorfrog/quando"

  def project do
    [
      app: :quando,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "Quando",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Taskwarrior-style date expression parser for Elixir. Parse expressions like '+7d', 'eom', 'monday', or 'P1Y2M3D' into DateTime structs."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      maintainers: ["vectorfrog"]
    ]
  end

  defp docs do
    [
      main: "Quando",
      extras: ["README.md"]
    ]
  end
end
