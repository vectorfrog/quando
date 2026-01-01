defmodule QuandoTest do
  use ExUnit.Case, async: true

  # Fixed reference time for deterministic tests
  # June 15, 2026 is a Monday
  @reference ~U[2026-06-15 10:30:00Z]

  describe "parse/1 - duration offsets" do
    test "parses +7d" do
      assert {:ok, result} = Quando.parse("+7d", reference: @reference)
      assert result == ~U[2026-06-22 10:30:00Z]
    end

    test "parses -3d" do
      assert {:ok, result} = Quando.parse("-3d", reference: @reference)
      assert result == ~U[2026-06-12 10:30:00Z]
    end

    test "parses +2w" do
      assert {:ok, result} = Quando.parse("+2w", reference: @reference)
      assert result == ~U[2026-06-29 10:30:00Z]
    end

    test "parses +3m (months)" do
      assert {:ok, result} = Quando.parse("+3m", reference: @reference)
      assert result == ~U[2026-09-15 10:30:00Z]
    end

    test "parses 30min (minutes)" do
      assert {:ok, result} = Quando.parse("30min", reference: @reference)
      assert result == ~U[2026-06-15 11:00:00Z]
    end

    test "parses +1y" do
      assert {:ok, result} = Quando.parse("+1y", reference: @reference)
      assert result == ~U[2027-06-15 10:30:00Z]
    end

    test "parses +5h" do
      assert {:ok, result} = Quando.parse("+5h", reference: @reference)
      assert result == ~U[2026-06-15 15:30:00Z]
    end

    test "parses 90s" do
      assert {:ok, result} = Quando.parse("90s", reference: @reference)
      assert result == ~U[2026-06-15 10:31:30Z]
    end
  end

  describe "parse/1 - chained durations" do
    test "parses +1d+9h" do
      assert {:ok, result} = Quando.parse("+1d+9h", reference: @reference)
      assert result == ~U[2026-06-16 19:30:00Z]
    end

    test "parses -2w+3d" do
      assert {:ok, result} = Quando.parse("-2w+3d", reference: @reference)
      assert result == ~U[2026-06-04 10:30:00Z]
    end

    test "parses +1y+2m+3d" do
      assert {:ok, result} = Quando.parse("+1y+2m+3d", reference: @reference)
      assert result == ~U[2027-08-18 10:30:00Z]
    end

    test "parses complex chain +1d+2h+30min" do
      assert {:ok, result} = Quando.parse("+1d+2h+30min", reference: @reference)
      assert result == ~U[2026-06-16 13:00:00Z]
    end
  end

  describe "parse/1 - synonyms" do
    test "parses now" do
      assert {:ok, result} = Quando.parse("now", reference: @reference)
      assert result == @reference
    end

    test "parses today" do
      assert {:ok, result} = Quando.parse("today", reference: @reference)
      assert result == ~U[2026-06-15 00:00:00Z]
    end

    test "parses yesterday" do
      assert {:ok, result} = Quando.parse("yesterday", reference: @reference)
      assert result == ~U[2026-06-14 00:00:00Z]
    end

    test "parses tomorrow" do
      assert {:ok, result} = Quando.parse("tomorrow", reference: @reference)
      assert result == ~U[2026-06-16 00:00:00Z]
    end

    test "handles case insensitivity" do
      assert {:ok, _} = Quando.parse("TODAY", reference: @reference)
      assert {:ok, _} = Quando.parse("Tomorrow", reference: @reference)
    end
  end

  describe "parse/1 - weekday names" do
    test "parses full weekday names" do
      # June 15, 2026 is Monday, so Tuesday is June 16
      assert {:ok, result} = Quando.parse("tuesday", reference: @reference)
      assert result == ~U[2026-06-16 00:00:00Z]
    end

    test "parses abbreviated weekday names" do
      assert {:ok, result} = Quando.parse("fri", reference: @reference)
      assert result == ~U[2026-06-19 00:00:00Z]
    end

    test "returns next week for same weekday" do
      # Asking for Monday on a Monday gives next Monday
      assert {:ok, result} = Quando.parse("monday", reference: @reference)
      assert result == ~U[2026-06-22 00:00:00Z]
    end
  end

  describe "parse/1 - month names" do
    test "parses full month names" do
      assert {:ok, result} = Quando.parse("december", reference: @reference)
      assert result == ~U[2026-12-01 00:00:00Z]
    end

    test "parses abbreviated month names" do
      assert {:ok, result} = Quando.parse("dec", reference: @reference)
      assert result == ~U[2026-12-01 00:00:00Z]
    end

    test "returns next year for past months" do
      assert {:ok, result} = Quando.parse("january", reference: @reference)
      assert result == ~U[2027-01-01 00:00:00Z]
    end
  end

  describe "parse/1 - period boundaries" do
    test "parses sow (start of week)" do
      assert {:ok, result} = Quando.parse("sow", reference: @reference)
      assert result == ~U[2026-06-15 00:00:00Z]
    end

    test "parses eow (end of week)" do
      assert {:ok, result} = Quando.parse("eow", reference: @reference)
      assert result == ~U[2026-06-21 23:59:59Z]
    end

    test "parses som (start of month)" do
      assert {:ok, result} = Quando.parse("som", reference: @reference)
      assert result == ~U[2026-06-01 00:00:00Z]
    end

    test "parses eom (end of month)" do
      assert {:ok, result} = Quando.parse("eom", reference: @reference)
      assert result == ~U[2026-06-30 23:59:59Z]
    end

    test "parses soy (start of year)" do
      assert {:ok, result} = Quando.parse("soy", reference: @reference)
      assert result == ~U[2026-01-01 00:00:00Z]
    end

    test "parses eoy (end of year)" do
      assert {:ok, result} = Quando.parse("eoy", reference: @reference)
      assert result == ~U[2026-12-31 23:59:59Z]
    end

    test "parses soq (start of quarter)" do
      assert {:ok, result} = Quando.parse("soq", reference: @reference)
      assert result == ~U[2026-04-01 00:00:00Z]
    end

    test "parses eoq (end of quarter)" do
      assert {:ok, result} = Quando.parse("eoq", reference: @reference)
      assert result == ~U[2026-06-30 23:59:59Z]
    end

    test "parses eod (end of day)" do
      assert {:ok, result} = Quando.parse("eod", reference: @reference)
      assert result == ~U[2026-06-15 23:59:59Z]
    end

    test "parses alternate forms (socw, eocw, etc.)" do
      assert {:ok, _} = Quando.parse("socw", reference: @reference)
      assert {:ok, _} = Quando.parse("eocw", reference: @reference)
      assert {:ok, _} = Quando.parse("socm", reference: @reference)
      assert {:ok, _} = Quando.parse("eocm", reference: @reference)
    end
  end

  describe "parse/1 - ordinals" do
    test "parses 1st" do
      assert {:ok, result} = Quando.parse("1st", reference: @reference)
      # 1st of July since we're past the 1st of June
      assert result == ~U[2026-07-01 00:00:00Z]
    end

    test "parses 20th" do
      assert {:ok, result} = Quando.parse("20th", reference: @reference)
      assert result == ~U[2026-06-20 00:00:00Z]
    end

    test "parses 31st" do
      assert {:ok, result} = Quando.parse("31st", reference: @reference)
      # June only has 30 days, so clamps to 30
      assert result == ~U[2026-06-30 00:00:00Z]
    end
  end

  describe "parse/1 - ISO-8601 durations" do
    test "parses P3D" do
      assert {:ok, result} = Quando.parse("P3D", reference: @reference)
      assert result == ~U[2026-06-18 10:30:00Z]
    end

    test "parses P2W" do
      assert {:ok, result} = Quando.parse("P2W", reference: @reference)
      assert result == ~U[2026-06-29 10:30:00Z]
    end

    test "parses PT1H" do
      assert {:ok, result} = Quando.parse("PT1H", reference: @reference)
      assert result == ~U[2026-06-15 11:30:00Z]
    end

    test "parses P1Y2M3D" do
      assert {:ok, result} = Quando.parse("P1Y2M3D", reference: @reference)
      assert result == ~U[2027-08-18 10:30:00Z]
    end

    test "parses P1Y2M3DT12H40M50S" do
      assert {:ok, result} = Quando.parse("P1Y2M3DT12H40M50S", reference: @reference)
      assert result == ~U[2027-08-18 23:10:50Z]
    end

    test "handles lowercase" do
      assert {:ok, _} = Quando.parse("p3d", reference: @reference)
      assert {:ok, _} = Quando.parse("pt1h", reference: @reference)
    end
  end

  describe "parse/1 - options" do
    test "week_start option changes start of week calculation" do
      # Default week start is Monday (1)
      assert {:ok, monday_start} = Quando.parse("sow", reference: @reference, week_start: 1)
      assert monday_start == ~U[2026-06-15 00:00:00Z]

      # Sunday week start (7)
      assert {:ok, sunday_start} = Quando.parse("sow", reference: @reference, week_start: 7)
      assert sunday_start == ~U[2026-06-14 00:00:00Z]
    end
  end

  describe "parse/1 - error handling" do
    test "returns error for invalid input" do
      assert {:error, _reason} = Quando.parse("invalid")
      assert {:error, _reason} = Quando.parse("123abc")
      assert {:error, _reason} = Quando.parse("")
    end

    test "returns error for partial matches" do
      assert {:error, _} = Quando.parse("today at noon")
      assert {:error, _} = Quando.parse("+7d extra")
    end
  end

  describe "parse!/1" do
    test "returns DateTime on success" do
      result = Quando.parse!("tomorrow", reference: @reference)
      assert result == ~U[2026-06-16 00:00:00Z]
    end

    test "raises ArgumentError on failure" do
      assert_raise ArgumentError, ~r/Failed to parse/, fn ->
        Quando.parse!("invalid")
      end
    end
  end

  describe "parse_ast/1" do
    test "returns parsed AST without calculation" do
      assert {:ok, {:synonym, :tomorrow}} = Quando.parse_ast("tomorrow")

      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 7, unit: :days}}]}} =
               Quando.parse_ast("+7d")
    end
  end

  describe "edge cases" do
    test "handles whitespace around input" do
      assert {:ok, _} = Quando.parse("  +7d  ", reference: @reference)
      assert {:ok, _} = Quando.parse("\ttomorrow\n", reference: @reference)
    end

    test "large duration values" do
      assert {:ok, result} = Quando.parse("+365d", reference: @reference)
      assert result.year == 2027
    end

    test "negative duration crossing year boundary" do
      ref = ~U[2026-01-15 10:00:00Z]
      assert {:ok, result} = Quando.parse("-30d", reference: ref)
      assert result.year == 2025
      assert result.month == 12
    end

    test "month calculation on last day of month" do
      ref = ~U[2026-01-31 10:00:00Z]
      assert {:ok, result} = Quando.parse("+1m", reference: ref)
      # Feb 2026 has 28 days
      assert result == ~U[2026-02-28 10:00:00Z]
    end

    test "leap year handling" do
      ref = ~U[2024-02-29 10:00:00Z]
      assert {:ok, result} = Quando.parse("+1y", reference: ref)
      # 2025 is not a leap year, so Feb 29 becomes Feb 28
      assert result == ~U[2025-02-28 10:00:00Z]
    end
  end

  describe "real-world usage examples" do
    test "setting a reminder for next week" do
      assert {:ok, result} = Quando.parse("+1w", reference: @reference)
      assert Date.diff(DateTime.to_date(result), DateTime.to_date(@reference)) == 7
    end

    test "deadline at end of month" do
      assert {:ok, result} = Quando.parse("eom", reference: @reference)
      assert result.day == 30
      assert result.month == 6
    end

    test "quarterly review" do
      assert {:ok, result} = Quando.parse("eoq", reference: @reference)
      assert result.month == 6
      assert result.day == 30
    end

    test "next Friday meeting" do
      assert {:ok, result} = Quando.parse("fri", reference: @reference)
      assert Date.day_of_week(DateTime.to_date(result)) == 5
    end

    test "two and a half hours from now" do
      assert {:ok, result} = Quando.parse("+2h+30min", reference: @reference)
      assert result == ~U[2026-06-15 13:00:00Z]
    end
  end
end
