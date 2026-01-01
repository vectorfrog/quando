defmodule Quando.ParserTest do
  use ExUnit.Case, async: true

  alias Quando.Parser

  describe "duration parsing" do
    test "parses positive days with + sign" do
      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 7, unit: :days}}]}} =
               Parser.parse("+7d")
    end

    test "parses negative days with - sign" do
      assert {:ok, {:chained_duration, [{:duration, %{sign: :-, amount: 3, unit: :days}}]}} =
               Parser.parse("-3d")
    end

    test "parses days without sign (defaults to +)" do
      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 5, unit: :days}}]}} =
               Parser.parse("5d")
    end

    test "parses full word 'days'" do
      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 2, unit: :days}}]}} =
               Parser.parse("2days")
    end

    test "parses singular 'day'" do
      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 1, unit: :days}}]}} =
               Parser.parse("1day")
    end

    test "parses weeks" do
      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 2, unit: :weeks}}]}} =
               Parser.parse("+2w")

      assert {:ok, {:chained_duration, [{:duration, %{sign: :-, amount: 1, unit: :weeks}}]}} =
               Parser.parse("-1week")
    end

    test "parses months (m = months)" do
      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 3, unit: :months}}]}} =
               Parser.parse("+3m")

      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 6, unit: :months}}]}} =
               Parser.parse("6months")
    end

    test "parses years" do
      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 1, unit: :years}}]}} =
               Parser.parse("+1y")

      assert {:ok, {:chained_duration, [{:duration, %{sign: :-, amount: 2, unit: :years}}]}} =
               Parser.parse("-2years")
    end

    test "parses hours" do
      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 5, unit: :hours}}]}} =
               Parser.parse("+5h")

      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 12, unit: :hours}}]}} =
               Parser.parse("12hours")
    end

    test "parses minutes (min/mins, NOT m)" do
      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 30, unit: :minutes}}]}} =
               Parser.parse("+30min")

      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 45, unit: :minutes}}]}} =
               Parser.parse("45mins")
    end

    test "parses seconds" do
      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 30, unit: :seconds}}]}} =
               Parser.parse("+30s")

      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 15, unit: :seconds}}]}} =
               Parser.parse("15sec")
    end

    test "handles case insensitivity" do
      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 7, unit: :days}}]}} =
               Parser.parse("+7D")

      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 2, unit: :weeks}}]}} =
               Parser.parse("+2W")
    end

    test "handles whitespace" do
      assert {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 7, unit: :days}}]}} =
               Parser.parse("  +7d  ")
    end
  end

  describe "chained duration parsing" do
    test "parses two durations chained" do
      assert {:ok, {:chained_duration, durations}} = Parser.parse("+1d+9h")
      assert length(durations) == 2

      assert {:duration, %{sign: :+, amount: 1, unit: :days}} = Enum.at(durations, 0)
      assert {:duration, %{sign: :+, amount: 9, unit: :hours}} = Enum.at(durations, 1)
    end

    test "parses mixed sign durations" do
      assert {:ok, {:chained_duration, durations}} = Parser.parse("-2w+3d")
      assert length(durations) == 2

      assert {:duration, %{sign: :-, amount: 2, unit: :weeks}} = Enum.at(durations, 0)
      assert {:duration, %{sign: :+, amount: 3, unit: :days}} = Enum.at(durations, 1)
    end

    test "parses three durations chained" do
      assert {:ok, {:chained_duration, durations}} = Parser.parse("+1y+2m+3d")
      assert length(durations) == 3
    end

    test "parses complex chain with time units" do
      assert {:ok, {:chained_duration, durations}} = Parser.parse("+1d+2h+30min")
      assert length(durations) == 3

      assert {:duration, %{sign: :+, amount: 1, unit: :days}} = Enum.at(durations, 0)
      assert {:duration, %{sign: :+, amount: 2, unit: :hours}} = Enum.at(durations, 1)
      assert {:duration, %{sign: :+, amount: 30, unit: :minutes}} = Enum.at(durations, 2)
    end
  end

  describe "synonym parsing" do
    test "parses 'now'" do
      assert {:ok, {:synonym, :now}} = Parser.parse("now")
    end

    test "parses 'today'" do
      assert {:ok, {:synonym, :today}} = Parser.parse("today")
    end

    test "parses 'yesterday'" do
      assert {:ok, {:synonym, :yesterday}} = Parser.parse("yesterday")
    end

    test "parses 'tomorrow'" do
      assert {:ok, {:synonym, :tomorrow}} = Parser.parse("tomorrow")
    end

    test "handles case insensitivity" do
      assert {:ok, {:synonym, :today}} = Parser.parse("TODAY")
      assert {:ok, {:synonym, :tomorrow}} = Parser.parse("Tomorrow")
    end
  end

  describe "weekday parsing" do
    test "parses full weekday names" do
      assert {:ok, {:weekday, 1}} = Parser.parse("monday")
      assert {:ok, {:weekday, 2}} = Parser.parse("tuesday")
      assert {:ok, {:weekday, 3}} = Parser.parse("wednesday")
      assert {:ok, {:weekday, 4}} = Parser.parse("thursday")
      assert {:ok, {:weekday, 5}} = Parser.parse("friday")
      assert {:ok, {:weekday, 6}} = Parser.parse("saturday")
      assert {:ok, {:weekday, 7}} = Parser.parse("sunday")
    end

    test "parses abbreviated weekday names" do
      assert {:ok, {:weekday, 1}} = Parser.parse("mon")
      assert {:ok, {:weekday, 2}} = Parser.parse("tue")
      assert {:ok, {:weekday, 3}} = Parser.parse("wed")
      assert {:ok, {:weekday, 4}} = Parser.parse("thu")
      assert {:ok, {:weekday, 5}} = Parser.parse("fri")
      assert {:ok, {:weekday, 6}} = Parser.parse("sat")
      assert {:ok, {:weekday, 7}} = Parser.parse("sun")
    end

    test "handles case insensitivity" do
      assert {:ok, {:weekday, 1}} = Parser.parse("MONDAY")
      assert {:ok, {:weekday, 5}} = Parser.parse("Friday")
      assert {:ok, {:weekday, 7}} = Parser.parse("SUN")
    end
  end

  describe "month name parsing" do
    test "parses full month names" do
      assert {:ok, {:month, 1}} = Parser.parse("january")
      assert {:ok, {:month, 2}} = Parser.parse("february")
      assert {:ok, {:month, 3}} = Parser.parse("march")
      assert {:ok, {:month, 4}} = Parser.parse("april")
      assert {:ok, {:month, 5}} = Parser.parse("may")
      assert {:ok, {:month, 6}} = Parser.parse("june")
      assert {:ok, {:month, 7}} = Parser.parse("july")
      assert {:ok, {:month, 8}} = Parser.parse("august")
      assert {:ok, {:month, 9}} = Parser.parse("september")
      assert {:ok, {:month, 10}} = Parser.parse("october")
      assert {:ok, {:month, 11}} = Parser.parse("november")
      assert {:ok, {:month, 12}} = Parser.parse("december")
    end

    test "parses abbreviated month names" do
      assert {:ok, {:month, 1}} = Parser.parse("jan")
      assert {:ok, {:month, 2}} = Parser.parse("feb")
      assert {:ok, {:month, 3}} = Parser.parse("mar")
      assert {:ok, {:month, 4}} = Parser.parse("apr")
      assert {:ok, {:month, 5}} = Parser.parse("may")
      assert {:ok, {:month, 6}} = Parser.parse("jun")
      assert {:ok, {:month, 7}} = Parser.parse("jul")
      assert {:ok, {:month, 8}} = Parser.parse("aug")
      assert {:ok, {:month, 9}} = Parser.parse("sep")
      assert {:ok, {:month, 10}} = Parser.parse("oct")
      assert {:ok, {:month, 11}} = Parser.parse("nov")
      assert {:ok, {:month, 12}} = Parser.parse("dec")
    end
  end

  describe "period boundary parsing" do
    test "parses start of week" do
      assert {:ok, {:period_boundary, :start_of_week}} = Parser.parse("sow")
      assert {:ok, {:period_boundary, :start_of_week}} = Parser.parse("socw")
    end

    test "parses end of week" do
      assert {:ok, {:period_boundary, :end_of_week}} = Parser.parse("eow")
      assert {:ok, {:period_boundary, :end_of_week}} = Parser.parse("eocw")
    end

    test "parses start of month" do
      assert {:ok, {:period_boundary, :start_of_month}} = Parser.parse("som")
      assert {:ok, {:period_boundary, :start_of_month}} = Parser.parse("socm")
    end

    test "parses end of month" do
      assert {:ok, {:period_boundary, :end_of_month}} = Parser.parse("eom")
      assert {:ok, {:period_boundary, :end_of_month}} = Parser.parse("eocm")
    end

    test "parses start of year" do
      assert {:ok, {:period_boundary, :start_of_year}} = Parser.parse("soy")
      assert {:ok, {:period_boundary, :start_of_year}} = Parser.parse("socy")
    end

    test "parses end of year" do
      assert {:ok, {:period_boundary, :end_of_year}} = Parser.parse("eoy")
      assert {:ok, {:period_boundary, :end_of_year}} = Parser.parse("eocy")
    end

    test "parses start of quarter" do
      assert {:ok, {:period_boundary, :start_of_quarter}} = Parser.parse("soq")
    end

    test "parses end of quarter" do
      assert {:ok, {:period_boundary, :end_of_quarter}} = Parser.parse("eoq")
    end

    test "parses end of day" do
      assert {:ok, {:period_boundary, :end_of_day}} = Parser.parse("eod")
    end

    test "handles case insensitivity" do
      assert {:ok, {:period_boundary, :end_of_month}} = Parser.parse("EOM")
      assert {:ok, {:period_boundary, :start_of_week}} = Parser.parse("SOW")
    end
  end

  describe "ordinal parsing" do
    test "parses ordinals with 'st' suffix" do
      assert {:ok, {:ordinal, 1}} = Parser.parse("1st")
      assert {:ok, {:ordinal, 21}} = Parser.parse("21st")
      assert {:ok, {:ordinal, 31}} = Parser.parse("31st")
    end

    test "parses ordinals with 'nd' suffix" do
      assert {:ok, {:ordinal, 2}} = Parser.parse("2nd")
      assert {:ok, {:ordinal, 22}} = Parser.parse("22nd")
    end

    test "parses ordinals with 'rd' suffix" do
      assert {:ok, {:ordinal, 3}} = Parser.parse("3rd")
      assert {:ok, {:ordinal, 23}} = Parser.parse("23rd")
    end

    test "parses ordinals with 'th' suffix" do
      assert {:ok, {:ordinal, 4}} = Parser.parse("4th")
      assert {:ok, {:ordinal, 5}} = Parser.parse("5th")
      assert {:ok, {:ordinal, 10}} = Parser.parse("10th")
      assert {:ok, {:ordinal, 11}} = Parser.parse("11th")
      assert {:ok, {:ordinal, 12}} = Parser.parse("12th")
      assert {:ok, {:ordinal, 13}} = Parser.parse("13th")
      assert {:ok, {:ordinal, 15}} = Parser.parse("15th")
      assert {:ok, {:ordinal, 20}} = Parser.parse("20th")
    end

    test "rejects ordinals greater than 31" do
      assert {:error, _} = Parser.parse("32nd")
      assert {:error, _} = Parser.parse("50th")
    end

    test "rejects ordinal 0" do
      assert {:error, _} = Parser.parse("0th")
    end
  end

  describe "ISO-8601 duration parsing" do
    test "parses days only" do
      assert {:ok, {:iso_duration, %{days: 3}}} = Parser.parse("P3D")
    end

    test "parses weeks only" do
      assert {:ok, {:iso_duration, %{weeks: 2}}} = Parser.parse("P2W")
    end

    test "parses years only" do
      assert {:ok, {:iso_duration, %{years: 1}}} = Parser.parse("P1Y")
    end

    test "parses months only" do
      assert {:ok, {:iso_duration, %{months: 6}}} = Parser.parse("P6M")
    end

    test "parses years and months" do
      assert {:ok, {:iso_duration, %{years: 1, months: 6}}} = Parser.parse("P1Y6M")
    end

    test "parses full date part" do
      assert {:ok, {:iso_duration, %{years: 1, months: 2, days: 3}}} = Parser.parse("P1Y2M3D")
    end

    test "parses time part only" do
      assert {:ok, {:iso_duration, %{hours: 1}}} = Parser.parse("PT1H")
      assert {:ok, {:iso_duration, %{minutes: 30}}} = Parser.parse("PT30M")
      assert {:ok, {:iso_duration, %{seconds: 45}}} = Parser.parse("PT45S")
    end

    test "parses full time part" do
      assert {:ok, {:iso_duration, %{hours: 12, minutes: 40, seconds: 50}}} =
               Parser.parse("PT12H40M50S")
    end

    test "parses complex duration with date and time" do
      assert {:ok, {:iso_duration, components}} = Parser.parse("P1Y2M3DT12H40M50S")
      assert components[:years] == 1
      assert components[:months] == 2
      assert components[:days] == 3
      assert components[:hours] == 12
      assert components[:minutes] == 40
      assert components[:seconds] == 50
    end

    test "handles case insensitivity" do
      assert {:ok, {:iso_duration, %{days: 3}}} = Parser.parse("p3d")
      assert {:ok, {:iso_duration, %{hours: 1}}} = Parser.parse("pt1h")
    end

    test "rejects empty ISO duration" do
      assert {:error, _} = Parser.parse("P")
      assert {:error, _} = Parser.parse("PT")
    end
  end

  describe "error handling" do
    test "returns error for invalid input" do
      assert {:error, _} = Parser.parse("invalid")
      assert {:error, _} = Parser.parse("123")
      assert {:error, _} = Parser.parse("")
    end

    test "returns error for partial matches" do
      assert {:error, _} = Parser.parse("+7d extra")
      assert {:error, _} = Parser.parse("today at noon")
    end
  end
end
