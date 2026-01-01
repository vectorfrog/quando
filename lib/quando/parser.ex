defmodule Quando.Parser do
  @moduledoc """
  NimbleParsec-based parser for Taskwarrior-style date expressions.

  Supports:
  - Duration offsets: `-7d`, `+2w`, `-2m`, `+1y`, `5min`, `3h`
  - Chained durations: `+1d+9h`
  - Synonyms: `now`, `today`, `yesterday`, `tomorrow`
  - Day names: `monday`, `tue`, etc.
  - Month names: `january`, `feb`, etc.
  - Period boundaries: `sow`, `eow`, `som`, `eom`, `soy`, `eoy`, `soq`, `eoq`
  - Ordinals: `1st`, `2nd`, `15th`
  - ISO-8601 durations: `P3D`, `P1Y2M3DT12H40M50S`
  """

  import NimbleParsec

  # ==========================================================================
  # Basic Building Blocks
  # ==========================================================================

  # Optional sign: + or -
  sign =
    choice([
      string("+") |> replace(:+),
      string("-") |> replace(:-)
    ])

  # Positive integer
  pos_integer = integer(min: 1)

  # ==========================================================================
  # Duration Units (Taskwarrior style)
  # Key: m = months, min/mins = minutes
  # ==========================================================================

  # Minutes must come before months to handle "min"/"mins" prefix
  minutes_unit =
    choice([string("mins"), string("min")])
    |> replace(:minutes)

  # Other duration units
  seconds_unit =
    choice([string("seconds"), string("second"), string("secs"), string("sec"), string("s")])
    |> replace(:seconds)

  hours_unit =
    choice([string("hours"), string("hour"), string("hrs"), string("hr"), string("h")])
    |> replace(:hours)

  days_unit =
    choice([string("days"), string("day"), string("d")])
    |> replace(:days)

  weeks_unit =
    choice([string("weeks"), string("week"), string("wks"), string("wk"), string("w")])
    |> replace(:weeks)

  months_unit =
    choice([
      string("months"),
      string("month"),
      string("mths"),
      string("mth"),
      string("mo"),
      string("m")
    ])
    |> replace(:months)

  years_unit =
    choice([string("years"), string("year"), string("yrs"), string("yr"), string("y")])
    |> replace(:years)

  # Order matters: minutes before months due to "m" collision
  duration_unit =
    choice([
      seconds_unit,
      minutes_unit,
      hours_unit,
      days_unit,
      weeks_unit,
      months_unit,
      years_unit
    ])

  # ==========================================================================
  # Simple Duration: +7d, -2w, 3h, 5min
  # ==========================================================================

  simple_duration =
    optional(sign)
    |> concat(pos_integer)
    |> concat(duration_unit)
    |> post_traverse(:build_duration)

  defp build_duration(rest, [unit, amount], context, _line, _offset) do
    {rest, [{:duration, %{sign: :+, amount: amount, unit: unit}}], context}
  end

  defp build_duration(rest, [unit, amount, sign], context, _line, _offset) do
    {rest, [{:duration, %{sign: sign, amount: amount, unit: unit}}], context}
  end

  # ==========================================================================
  # Chained Durations: +1d+9h, -2w+3d
  # ==========================================================================

  chained_duration =
    simple_duration
    |> repeat(simple_duration)
    |> post_traverse(:build_chained_duration)

  defp build_chained_duration(rest, durations, context, _line, _offset) do
    # Durations come in reverse order from parsing
    durations = Enum.reverse(durations)
    {rest, [{:chained_duration, durations}], context}
  end

  # ==========================================================================
  # Date Synonyms
  # ==========================================================================

  now_synonym = string("now") |> replace({:synonym, :now})
  today_synonym = string("today") |> replace({:synonym, :today})
  yesterday_synonym = string("yesterday") |> replace({:synonym, :yesterday})
  tomorrow_synonym = string("tomorrow") |> replace({:synonym, :tomorrow})

  synonym =
    choice([
      now_synonym,
      today_synonym,
      yesterday_synonym,
      tomorrow_synonym
    ])

  # ==========================================================================
  # Day Names (full and abbreviated)
  # ==========================================================================

  monday = choice([string("monday"), string("mon")]) |> replace({:weekday, 1})
  tuesday = choice([string("tuesday"), string("tue")]) |> replace({:weekday, 2})
  wednesday = choice([string("wednesday"), string("wed")]) |> replace({:weekday, 3})
  thursday = choice([string("thursday"), string("thu")]) |> replace({:weekday, 4})
  friday = choice([string("friday"), string("fri")]) |> replace({:weekday, 5})
  saturday = choice([string("saturday"), string("sat")]) |> replace({:weekday, 6})
  sunday = choice([string("sunday"), string("sun")]) |> replace({:weekday, 7})

  weekday =
    choice([
      # Full names first to avoid prefix matching issues
      monday,
      tuesday,
      wednesday,
      thursday,
      friday,
      saturday,
      sunday
    ])

  # ==========================================================================
  # Month Names (full and abbreviated)
  # ==========================================================================

  january = choice([string("january"), string("jan")]) |> replace({:month, 1})
  february = choice([string("february"), string("feb")]) |> replace({:month, 2})
  march = choice([string("march"), string("mar")]) |> replace({:month, 3})
  april = choice([string("april"), string("apr")]) |> replace({:month, 4})
  may = string("may") |> replace({:month, 5})
  june = choice([string("june"), string("jun")]) |> replace({:month, 6})
  july = choice([string("july"), string("jul")]) |> replace({:month, 7})
  august = choice([string("august"), string("aug")]) |> replace({:month, 8})
  september = choice([string("september"), string("sep")]) |> replace({:month, 9})
  october = choice([string("october"), string("oct")]) |> replace({:month, 10})
  november = choice([string("november"), string("nov")]) |> replace({:month, 11})
  december = choice([string("december"), string("dec")]) |> replace({:month, 12})

  month_name =
    choice([
      january,
      february,
      march,
      april,
      may,
      june,
      july,
      august,
      september,
      october,
      november,
      december
    ])

  # ==========================================================================
  # Period Boundaries
  # ==========================================================================

  # Start of periods
  sow = string("sow") |> replace({:period_boundary, :start_of_week})
  som = string("som") |> replace({:period_boundary, :start_of_month})
  soq = string("soq") |> replace({:period_boundary, :start_of_quarter})
  soy = string("soy") |> replace({:period_boundary, :start_of_year})

  # End of periods
  eow = string("eow") |> replace({:period_boundary, :end_of_week})
  eod = string("eod") |> replace({:period_boundary, :end_of_day})
  eom = string("eom") |> replace({:period_boundary, :end_of_month})
  eoq = string("eoq") |> replace({:period_boundary, :end_of_quarter})
  eoy = string("eoy") |> replace({:period_boundary, :end_of_year})

  # Taskwarrior also supports: socw, eocw (current week), socm, eocm, etc.
  socw = string("socw") |> replace({:period_boundary, :start_of_week})
  eocw = string("eocw") |> replace({:period_boundary, :end_of_week})
  socm = string("socm") |> replace({:period_boundary, :start_of_month})
  eocm = string("eocm") |> replace({:period_boundary, :end_of_month})
  socy = string("socy") |> replace({:period_boundary, :start_of_year})
  eocy = string("eocy") |> replace({:period_boundary, :end_of_year})

  period_boundary =
    choice([
      # Longer strings first to avoid prefix matching
      socw,
      eocw,
      socm,
      eocm,
      socy,
      eocy,
      sow,
      som,
      soq,
      soy,
      eow,
      eod,
      eom,
      eoq,
      eoy
    ])

  # ==========================================================================
  # Ordinals: 1st, 2nd, 3rd, 4th, ..., 31st
  # ==========================================================================

  ordinal_suffix =
    choice([
      string("st"),
      string("nd"),
      string("rd"),
      string("th")
    ])

  ordinal =
    pos_integer
    |> ignore(ordinal_suffix)
    |> post_traverse(:build_ordinal)

  defp build_ordinal(rest, [day], context, _line, _offset) when day >= 1 and day <= 31 do
    {rest, [{:ordinal, day}], context}
  end

  defp build_ordinal(rest, [_day], context, _line, _offset) do
    # Invalid ordinal (0 or > 31) - return empty result to trigger parse failure
    {rest, [], context}
  end

  # ==========================================================================
  # ISO-8601 Durations: P3D, P1Y2M3DT12H40M50S
  # ==========================================================================

  # ISO-8601 uses uppercase letters, but we lowercase input for case-insensitivity
  iso_years =
    pos_integer
    |> ignore(string("y"))
    |> unwrap_and_tag(:years)

  iso_months =
    pos_integer
    |> ignore(string("m"))
    |> unwrap_and_tag(:months)

  iso_weeks =
    pos_integer
    |> ignore(string("w"))
    |> unwrap_and_tag(:weeks)

  iso_days =
    pos_integer
    |> ignore(string("d"))
    |> unwrap_and_tag(:days)

  iso_hours =
    pos_integer
    |> ignore(string("h"))
    |> unwrap_and_tag(:hours)

  # In the time part, M means minutes
  iso_minutes =
    pos_integer
    |> ignore(string("m"))
    |> unwrap_and_tag(:minutes)

  iso_seconds =
    pos_integer
    |> ignore(string("s"))
    |> unwrap_and_tag(:seconds)

  # Date part: P[nY][nM][nD] or P[nW]
  iso_date_part =
    optional(iso_years)
    |> optional(iso_months)
    |> optional(iso_days)

  # Week part is exclusive (can't mix with Y/M/D)
  iso_week_part = iso_weeks

  # Time part: T[nH][nM][nS]
  iso_time_part =
    ignore(string("t"))
    |> optional(iso_hours)
    |> optional(iso_minutes)
    |> optional(iso_seconds)

  # Full ISO duration (lowercase p since we lowercase input)
  iso_duration =
    ignore(string("p"))
    |> choice([
      iso_week_part,
      iso_date_part |> optional(iso_time_part)
    ])
    |> post_traverse(:build_iso_duration)

  defp build_iso_duration(_rest, [], _context, _line, _offset) do
    {:error, "Empty ISO-8601 duration"}
  end

  defp build_iso_duration(rest, components, context, _line, _offset) do
    # Components come in reverse, convert to map
    duration_map =
      components
      |> Enum.reverse()
      |> Enum.into(%{})

    {rest, [{:iso_duration, duration_map}], context}
  end

  # ==========================================================================
  # Main Expression Parser
  # ==========================================================================

  # Combined parser - order matters for disambiguation
  expression =
    choice([
      # ISO duration must come early (starts with P)
      iso_duration,
      # Period boundaries before other keywords
      period_boundary,
      # Synonyms before durations
      synonym,
      # Weekday and month names
      weekday,
      month_name,
      # Ordinals
      ordinal,
      # Durations (can be chained)
      chained_duration
    ])

  defparsec(:parse_expression, expression |> eos())

  # ==========================================================================
  # Public API
  # ==========================================================================

  @doc """
  Parse a Taskwarrior-style date expression.

  Returns `{:ok, ast}` on success or `{:error, reason}` on failure.
  """
  def parse(input) when is_binary(input) do
    input = String.downcase(String.trim(input))

    case parse_expression(input) do
      {:ok, [result], "", _context, _line, _column} ->
        {:ok, result}

      {:ok, _, rest, _context, _line, _column} ->
        {:error, "Unexpected input: #{inspect(rest)}"}

      {:error, reason, _rest, _context, _line, _column} ->
        {:error, reason}
    end
  end
end
