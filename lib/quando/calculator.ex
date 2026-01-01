defmodule Quando.Calculator do
  @moduledoc """
  Calculates DateTime values from parsed Taskwarrior date expressions.

  Handles:
  - Duration offsets applied to a reference time
  - Period boundary calculations (start/end of week, month, year, quarter)
  - Weekday and month name resolution
  - Ordinal day calculations
  """

  @type reference_time :: DateTime.t() | nil

  @doc """
  Calculate the DateTime from a parsed expression.

  ## Options

  - `:reference` - Reference DateTime (defaults to now)
  - `:week_start` - Day the week starts on, 1 (Monday) to 7 (Sunday). Defaults to 1.
  """
  @spec calculate(term(), keyword()) :: {:ok, DateTime.t()} | {:error, String.t()}
  def calculate(ast, opts \\ []) do
    reference = Keyword.get(opts, :reference) || DateTime.utc_now()
    week_start = Keyword.get(opts, :week_start, 1)

    do_calculate(ast, reference, week_start)
  end

  # ==========================================================================
  # Synonyms
  # ==========================================================================

  defp do_calculate({:synonym, :now}, reference, _week_start) do
    {:ok, reference}
  end

  defp do_calculate({:synonym, :today}, reference, _week_start) do
    {:ok, start_of_day(reference)}
  end

  defp do_calculate({:synonym, :yesterday}, reference, _week_start) do
    {:ok, reference |> add_days(-1) |> start_of_day()}
  end

  defp do_calculate({:synonym, :tomorrow}, reference, _week_start) do
    {:ok, reference |> add_days(1) |> start_of_day()}
  end

  # ==========================================================================
  # Weekdays (next occurrence)
  # ==========================================================================

  defp do_calculate({:weekday, target_day}, reference, _week_start) do
    current_day = Date.day_of_week(DateTime.to_date(reference))

    days_ahead =
      if target_day > current_day do
        target_day - current_day
      else
        7 - current_day + target_day
      end

    # If today is the target day, return next week's occurrence
    days_ahead = if days_ahead == 0, do: 7, else: days_ahead

    {:ok, reference |> add_days(days_ahead) |> start_of_day()}
  end

  # ==========================================================================
  # Month Names (next occurrence of 1st of that month)
  # ==========================================================================

  defp do_calculate({:month, target_month}, reference, _week_start) do
    current_date = DateTime.to_date(reference)
    current_month = current_date.month
    current_year = current_date.year

    year =
      if target_month > current_month do
        current_year
      else
        current_year + 1
      end

    case Date.new(year, target_month, 1) do
      {:ok, date} -> {:ok, DateTime.new!(date, ~T[00:00:00], "Etc/UTC")}
      {:error, reason} -> {:error, "Invalid date: #{inspect(reason)}"}
    end
  end

  # ==========================================================================
  # Ordinals (day of current/next month)
  # ==========================================================================

  defp do_calculate({:ordinal, day}, reference, _week_start) do
    current_date = DateTime.to_date(reference)
    current_day = current_date.day

    # If the ordinal day has passed this month, use next month
    {year, month} =
      if day <= current_day do
        next_month(current_date.year, current_date.month)
      else
        {current_date.year, current_date.month}
      end

    # Clamp to valid day for the month
    days_in_month = Date.days_in_month(Date.new!(year, month, 1))
    actual_day = min(day, days_in_month)

    case Date.new(year, month, actual_day) do
      {:ok, date} -> {:ok, DateTime.new!(date, ~T[00:00:00], "Etc/UTC")}
      {:error, reason} -> {:error, "Invalid date: #{inspect(reason)}"}
    end
  end

  # ==========================================================================
  # Period Boundaries
  # ==========================================================================

  defp do_calculate({:period_boundary, :start_of_week}, reference, week_start) do
    {:ok, start_of_week(reference, week_start)}
  end

  defp do_calculate({:period_boundary, :end_of_week}, reference, week_start) do
    {:ok, end_of_week(reference, week_start)}
  end

  defp do_calculate({:period_boundary, :start_of_month}, reference, _week_start) do
    {:ok, start_of_month(reference)}
  end

  defp do_calculate({:period_boundary, :end_of_month}, reference, _week_start) do
    {:ok, end_of_month(reference)}
  end

  defp do_calculate({:period_boundary, :start_of_year}, reference, _week_start) do
    {:ok, start_of_year(reference)}
  end

  defp do_calculate({:period_boundary, :end_of_year}, reference, _week_start) do
    {:ok, end_of_year(reference)}
  end

  defp do_calculate({:period_boundary, :start_of_quarter}, reference, _week_start) do
    {:ok, start_of_quarter(reference)}
  end

  defp do_calculate({:period_boundary, :end_of_quarter}, reference, _week_start) do
    {:ok, end_of_quarter(reference)}
  end

  defp do_calculate({:period_boundary, :end_of_day}, reference, _week_start) do
    {:ok, end_of_day(reference)}
  end

  # ==========================================================================
  # Durations
  # ==========================================================================

  defp do_calculate({:chained_duration, durations}, reference, week_start) do
    Enum.reduce_while(durations, {:ok, reference}, fn duration, {:ok, acc} ->
      case do_calculate(duration, acc, week_start) do
        {:ok, new_dt} -> {:cont, {:ok, new_dt}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp do_calculate(
         {:duration, %{sign: sign, amount: amount, unit: unit}},
         reference,
         _week_start
       ) do
    multiplier = if sign == :-, do: -1, else: 1
    adjusted_amount = amount * multiplier

    result =
      case unit do
        :seconds -> add_seconds(reference, adjusted_amount)
        :minutes -> add_minutes(reference, adjusted_amount)
        :hours -> add_hours(reference, adjusted_amount)
        :days -> add_days(reference, adjusted_amount)
        :weeks -> add_weeks(reference, adjusted_amount)
        :months -> add_months(reference, adjusted_amount)
        :years -> add_years(reference, adjusted_amount)
      end

    {:ok, result}
  end

  # ==========================================================================
  # ISO-8601 Durations
  # ==========================================================================

  defp do_calculate({:iso_duration, components}, reference, _week_start) do
    result =
      reference
      |> maybe_add(:years, Map.get(components, :years))
      |> maybe_add(:months, Map.get(components, :months))
      |> maybe_add(:weeks, Map.get(components, :weeks))
      |> maybe_add(:days, Map.get(components, :days))
      |> maybe_add(:hours, Map.get(components, :hours))
      |> maybe_add(:minutes, Map.get(components, :minutes))
      |> maybe_add(:seconds, Map.get(components, :seconds))

    {:ok, result}
  end

  # Catch-all for unknown AST
  defp do_calculate(ast, _reference, _week_start) do
    {:error, "Unknown expression: #{inspect(ast)}"}
  end

  # ==========================================================================
  # Helper Functions
  # ==========================================================================

  defp maybe_add(dt, _unit, nil), do: dt
  defp maybe_add(dt, :years, amount), do: add_years(dt, amount)
  defp maybe_add(dt, :months, amount), do: add_months(dt, amount)
  defp maybe_add(dt, :weeks, amount), do: add_weeks(dt, amount)
  defp maybe_add(dt, :days, amount), do: add_days(dt, amount)
  defp maybe_add(dt, :hours, amount), do: add_hours(dt, amount)
  defp maybe_add(dt, :minutes, amount), do: add_minutes(dt, amount)
  defp maybe_add(dt, :seconds, amount), do: add_seconds(dt, amount)

  defp add_seconds(dt, seconds) do
    DateTime.add(dt, seconds, :second)
  end

  defp add_minutes(dt, minutes) do
    DateTime.add(dt, minutes * 60, :second)
  end

  defp add_hours(dt, hours) do
    DateTime.add(dt, hours * 3600, :second)
  end

  defp add_days(dt, days) do
    DateTime.add(dt, days * 86400, :second)
  end

  defp add_weeks(dt, weeks) do
    add_days(dt, weeks * 7)
  end

  defp add_months(dt, months) do
    date = DateTime.to_date(dt)
    time = DateTime.to_time(dt)

    new_date = Date.shift(date, month: months)
    DateTime.new!(new_date, time, dt.time_zone)
  end

  defp add_years(dt, years) do
    add_months(dt, years * 12)
  end

  defp start_of_day(dt) do
    date = DateTime.to_date(dt)
    DateTime.new!(date, ~T[00:00:00], dt.time_zone)
  end

  defp end_of_day(dt) do
    date = DateTime.to_date(dt)
    DateTime.new!(date, ~T[23:59:59], dt.time_zone)
  end

  defp start_of_week(dt, week_start) do
    date = DateTime.to_date(dt)
    current_day = Date.day_of_week(date)

    days_to_subtract =
      if current_day >= week_start do
        current_day - week_start
      else
        7 - week_start + current_day
      end

    start_date = Date.add(date, -days_to_subtract)
    DateTime.new!(start_date, ~T[00:00:00], dt.time_zone)
  end

  defp end_of_week(dt, week_start) do
    # End of week is 6 days after start of week
    start = start_of_week(dt, week_start)
    end_date = Date.add(DateTime.to_date(start), 6)
    DateTime.new!(end_date, ~T[23:59:59], dt.time_zone)
  end

  defp start_of_month(dt) do
    date = DateTime.to_date(dt)
    first = Date.beginning_of_month(date)
    DateTime.new!(first, ~T[00:00:00], dt.time_zone)
  end

  defp end_of_month(dt) do
    date = DateTime.to_date(dt)
    last = Date.end_of_month(date)
    DateTime.new!(last, ~T[23:59:59], dt.time_zone)
  end

  defp start_of_year(dt) do
    date = DateTime.to_date(dt)
    first = Date.new!(date.year, 1, 1)
    DateTime.new!(first, ~T[00:00:00], dt.time_zone)
  end

  defp end_of_year(dt) do
    date = DateTime.to_date(dt)
    last = Date.new!(date.year, 12, 31)
    DateTime.new!(last, ~T[23:59:59], dt.time_zone)
  end

  defp start_of_quarter(dt) do
    date = DateTime.to_date(dt)
    quarter_start_month = quarter_start_month(date.month)
    first = Date.new!(date.year, quarter_start_month, 1)
    DateTime.new!(first, ~T[00:00:00], dt.time_zone)
  end

  defp end_of_quarter(dt) do
    date = DateTime.to_date(dt)
    quarter_end_month = quarter_end_month(date.month)
    last = Date.end_of_month(Date.new!(date.year, quarter_end_month, 1))
    DateTime.new!(last, ~T[23:59:59], dt.time_zone)
  end

  defp quarter_start_month(month) when month in 1..3, do: 1
  defp quarter_start_month(month) when month in 4..6, do: 4
  defp quarter_start_month(month) when month in 7..9, do: 7
  defp quarter_start_month(month) when month in 10..12, do: 10

  defp quarter_end_month(month) when month in 1..3, do: 3
  defp quarter_end_month(month) when month in 4..6, do: 6
  defp quarter_end_month(month) when month in 7..9, do: 9
  defp quarter_end_month(month) when month in 10..12, do: 12

  defp next_month(year, 12), do: {year + 1, 1}
  defp next_month(year, month), do: {year, month + 1}
end
