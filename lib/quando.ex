defmodule Quando do
  @moduledoc """
  Taskwarrior-style date expression parser for Elixir.

  Quando parses Taskwarrior-compatible date expressions into Elixir DateTime structs
  using NimbleParsec.

  ## Supported Syntax

  ### Duration Offsets
  - Days: `+7d`, `-3d`, `5d`
  - Weeks: `+2w`, `-1w`
  - Months: `+3m`, `-2m` (note: `m` = months)
  - Years: `+1y`, `-2y`
  - Hours: `+5h`, `-2h`
  - Minutes: `30min`, `45mins` (note: use `min`/`mins` for minutes)
  - Seconds: `+30s`, `-15sec`

  ### Chained Durations
  - `+1d+9h` - Tomorrow plus 9 hours
  - `-2w+3d` - Two weeks ago plus 3 days

  ### Synonyms
  - `now` - Current time
  - `today` - Start of today
  - `yesterday` - Start of yesterday
  - `tomorrow` - Start of tomorrow

  ### Day Names
  - Full names: `monday`, `tuesday`, `wednesday`, etc.
  - Abbreviations: `mon`, `tue`, `wed`, `thu`, `fri`, `sat`, `sun`

  ### Month Names
  - Full names: `january`, `february`, `march`, etc.
  - Abbreviations: `jan`, `feb`, `mar`, `apr`, `may`, `jun`, `jul`, `aug`, `sep`, `oct`, `nov`, `dec`

  ### Period Boundaries
  - Start of week: `sow`, `socw`
  - End of week: `eow`, `eocw`
  - Start of month: `som`, `socm`
  - End of month: `eom`, `eocm`
  - Start of year: `soy`, `socy`
  - End of year: `eoy`, `eocy`
  - Start of quarter: `soq`
  - End of quarter: `eoq`
  - End of day: `eod`

  ### Ordinals
  - `1st`, `2nd`, `3rd`, `15th`, `31st` - Day of month

  ### ISO-8601 Durations
  - Simple: `P3D`, `P2W`, `PT1H`
  - Complex: `P1Y2M3DT12H40M50S`

  ## Examples

      iex> Quando.parse("+7d")
      {:ok, ~U[...]}  # 7 days from now

      iex> Quando.parse("eom")
      {:ok, ~U[...]}  # End of current month

      iex> Quando.parse("monday")
      {:ok, ~U[...]}  # Next Monday

      iex> Quando.parse("P1Y2M3D")
      {:ok, ~U[...]}  # 1 year, 2 months, 3 days from now

  ## Options

  - `:reference` - Reference DateTime (defaults to `DateTime.utc_now/0`)
  - `:week_start` - Day the week starts on, 1 (Monday) to 7 (Sunday). Defaults to 1.

  """

  alias Quando.{Parser, Calculator}

  @doc """
  Parses a Taskwarrior-style date expression and returns a DateTime.

  Returns `{:ok, datetime}` on success or `{:error, reason}` on failure.

  ## Examples

      iex> {:ok, dt} = Quando.parse("tomorrow")
      iex> Date.diff(DateTime.to_date(dt), Date.utc_today())
      1

      iex> Quando.parse("invalid expression")
      {:error, _}

  ## Options

  - `:reference` - Reference DateTime for calculations (defaults to now)
  - `:week_start` - Day the week starts on, 1-7 (defaults to 1 for Monday)

  """
  @spec parse(String.t(), keyword()) :: {:ok, DateTime.t()} | {:error, String.t()}
  def parse(input, opts \\ []) when is_binary(input) do
    with {:ok, ast} <- Parser.parse(input),
         {:ok, datetime} <- Calculator.calculate(ast, opts) do
      {:ok, datetime}
    end
  end

  @doc """
  Parses a Taskwarrior-style date expression, raising on error.

  ## Examples

      iex> dt = Quando.parse!("+1d")
      iex> is_struct(dt, DateTime)
      true

  """
  @spec parse!(String.t(), keyword()) :: DateTime.t()
  def parse!(input, opts \\ []) when is_binary(input) do
    case parse(input, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, "Failed to parse '#{input}': #{reason}"
    end
  end

  @doc """
  Parses a Taskwarrior-style date expression and returns only the AST.

  Useful for debugging or when you want to inspect the parsed structure
  without calculating the actual date.

  ## Examples

      iex> Quando.parse_ast("+7d")
      {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 7, unit: :days}}]}}

  """
  @spec parse_ast(String.t()) :: {:ok, term()} | {:error, String.t()}
  def parse_ast(input) when is_binary(input) do
    Parser.parse(input)
  end
end
