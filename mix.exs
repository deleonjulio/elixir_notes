defmodule ElixirNotes.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_notes,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ElixirNotes.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.6"},
      {:corsica, "~> 2.1.3"},
      {:jason, "~> 1.4.4"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, "~> 0.18.0"},
    ]
  end
end
