defmodule Quando.CalculatorTest do
  use ExUnit.Case, async: true

  alias Quando.Calculator

  # Fixed reference time for deterministic tests
  @reference ~U[2026-06-15 10:30:00Z]

  describe "synonym calculations" do
    test "now returns reference time" do
      assert {:ok, @reference} = Calculator.calculate({:synonym, :now}, reference: @reference)
    end

    test "today returns start of reference day" do
      assert {:ok, result} = Calculator.calculate({:synonym, :today}, reference: @reference)
      assert result == ~U[2026-06-15 00:00:00Z]
    end

    test "yesterday returns start of previous day" do
      assert {:ok, result} = Calculator.calculate({:synonym, :yesterday}, reference: @reference)
      assert result == ~U[2026-06-14 00:00:00Z]
    end

    test "tomorrow returns start of next day" do
      assert {:ok, result} = Calculator.calculate({:synonym, :tomorrow}, reference: @reference)
      assert result == ~U[2026-06-16 00:00:00Z]
    end
  end

  describe "duration calculations" do
    test "adds days" do
      duration = {:duration, %{sign: :+, amount: 7, unit: :days}}
      assert {:ok, result} = Calculator.calculate(duration, reference: @reference)
      assert result == ~U[2026-06-22 10:30:00Z]
    end

    test "subtracts days" do
      duration = {:duration, %{sign: :-, amount: 5, unit: :days}}
      assert {:ok, result} = Calculator.calculate(duration, reference: @reference)
      assert result == ~U[2026-06-10 10:30:00Z]
    end

    test "adds weeks" do
      duration = {:duration, %{sign: :+, amount: 2, unit: :weeks}}
      assert {:ok, result} = Calculator.calculate(duration, reference: @reference)
      assert result == ~U[2026-06-29 10:30:00Z]
    end

    test "adds months" do
      duration = {:duration, %{sign: :+, amount: 3, unit: :months}}
      assert {:ok, result} = Calculator.calculate(duration, reference: @reference)
      assert result == ~U[2026-09-15 10:30:00Z]
    end

    test "subtracts months" do
      duration = {:duration, %{sign: :-, amount: 2, unit: :months}}
      assert {:ok, result} = Calculator.calculate(duration, reference: @reference)
      assert result == ~U[2026-04-15 10:30:00Z]
    end

    test "adds years" do
      duration = {:duration, %{sign: :+, amount: 1, unit: :years}}
      assert {:ok, result} = Calculator.calculate(duration, reference: @reference)
      assert result == ~U[2027-06-15 10:30:00Z]
    end

    test "adds hours" do
      duration = {:duration, %{sign: :+, amount: 5, unit: :hours}}
      assert {:ok, result} = Calculator.calculate(duration, reference: @reference)
      assert result == ~U[2026-06-15 15:30:00Z]
    end

    test "adds minutes" do
      duration = {:duration, %{sign: :+, amount: 45, unit: :minutes}}
      assert {:ok, result} = Calculator.calculate(duration, reference: @reference)
      assert result == ~U[2026-06-15 11:15:00Z]
    end

    test "adds seconds" do
      duration = {:duration, %{sign: :+, amount: 90, unit: :seconds}}
      assert {:ok, result} = Calculator.calculate(duration, reference: @reference)
      assert result == ~U[2026-06-15 10:31:30Z]
    end

    test "handles month overflow correctly" do
      # Adding 1 month to January 31 should not overflow
      ref = ~U[2026-01-31 10:00:00Z]
      duration = {:duration, %{sign: :+, amount: 1, unit: :months}}
      assert {:ok, result} = Calculator.calculate(duration, reference: ref)
      # February doesn't have 31 days, Date.shift handles this
      assert result.month == 2
      assert result.day == 28
    end
  end

  describe "chained duration calculations" do
    test "chains multiple durations" do
      chained =
        {:chained_duration,
         [
           {:duration, %{sign: :+, amount: 1, unit: :days}},
           {:duration, %{sign: :+, amount: 9, unit: :hours}}
         ]}

      assert {:ok, result} = Calculator.calculate(chained, reference: @reference)
      # June 15 + 1 day = June 16, 10:30 + 9 hours = 19:30
      assert result == ~U[2026-06-16 19:30:00Z]
    end

    test "chains durations with mixed signs" do
      chained =
        {:chained_duration,
         [
           {:duration, %{sign: :-, amount: 2, unit: :weeks}},
           {:duration, %{sign: :+, amount: 3, unit: :days}}
         ]}

      assert {:ok, result} = Calculator.calculate(chained, reference: @reference)
      # June 15 - 2 weeks = June 1, + 3 days = June 4
      assert result == ~U[2026-06-04 10:30:00Z]
    end

    test "chains three durations" do
      chained =
        {:chained_duration,
         [
           {:duration, %{sign: :+, amount: 1, unit: :years}},
           {:duration, %{sign: :+, amount: 2, unit: :months}},
           {:duration, %{sign: :+, amount: 3, unit: :days}}
         ]}

      assert {:ok, result} = Calculator.calculate(chained, reference: @reference)
      assert result == ~U[2027-08-18 10:30:00Z]
    end
  end

  describe "weekday calculations" do
    # June 15, 2026 is a Monday
    test "returns next occurrence of weekday" do
      # Today is Monday (1), asking for Tuesday (2)
      assert {:ok, result} = Calculator.calculate({:weekday, 2}, reference: @reference)
      assert result == ~U[2026-06-16 00:00:00Z]
      assert Date.day_of_week(DateTime.to_date(result)) == 2
    end

    test "returns next week if same weekday" do
      # Today is Monday (1), asking for Monday (1) should give next Monday
      assert {:ok, result} = Calculator.calculate({:weekday, 1}, reference: @reference)
      assert result == ~U[2026-06-22 00:00:00Z]
      assert Date.day_of_week(DateTime.to_date(result)) == 1
    end

    test "calculates previous weekday correctly" do
      # Today is Monday (1), asking for Friday (5) should give this Friday
      assert {:ok, result} = Calculator.calculate({:weekday, 5}, reference: @reference)
      assert result == ~U[2026-06-19 00:00:00Z]
      assert Date.day_of_week(DateTime.to_date(result)) == 5
    end

    test "calculates Sunday correctly" do
      # Today is Monday (1), asking for Sunday (7) should give this Sunday
      assert {:ok, result} = Calculator.calculate({:weekday, 7}, reference: @reference)
      assert result == ~U[2026-06-21 00:00:00Z]
      assert Date.day_of_week(DateTime.to_date(result)) == 7
    end
  end

  describe "month name calculations" do
    test "returns next occurrence of month (future month this year)" do
      # June 15, asking for December
      assert {:ok, result} = Calculator.calculate({:month, 12}, reference: @reference)
      assert result == ~U[2026-12-01 00:00:00Z]
    end

    test "returns next year if month has passed" do
      # June 15, asking for January
      assert {:ok, result} = Calculator.calculate({:month, 1}, reference: @reference)
      assert result == ~U[2027-01-01 00:00:00Z]
    end

    test "returns next year if same month" do
      # June 15, asking for June
      assert {:ok, result} = Calculator.calculate({:month, 6}, reference: @reference)
      assert result == ~U[2027-06-01 00:00:00Z]
    end
  end

  describe "ordinal calculations" do
    test "returns day in current month if not passed" do
      # June 15, asking for 20th
      assert {:ok, result} = Calculator.calculate({:ordinal, 20}, reference: @reference)
      assert result == ~U[2026-06-20 00:00:00Z]
    end

    test "returns day in next month if passed" do
      # June 15, asking for 10th
      assert {:ok, result} = Calculator.calculate({:ordinal, 10}, reference: @reference)
      assert result == ~U[2026-07-10 00:00:00Z]
    end

    test "returns next month if today is the ordinal day" do
      # June 15, asking for 15th
      assert {:ok, result} = Calculator.calculate({:ordinal, 15}, reference: @reference)
      assert result == ~U[2026-07-15 00:00:00Z]
    end

    test "clamps to valid day for month" do
      # Asking for 31st when landing in a month without 31 days
      ref = ~U[2026-01-30 10:00:00Z]
      assert {:ok, result} = Calculator.calculate({:ordinal, 31}, reference: ref)
      assert result == ~U[2026-01-31 00:00:00Z]

      # February clamping - asking for 31st on Feb 1
      # Since 31 > 1, we stay in February but clamp to 28
      ref = ~U[2026-02-01 10:00:00Z]
      assert {:ok, result} = Calculator.calculate({:ordinal, 31}, reference: ref)
      assert result == ~U[2026-02-28 00:00:00Z]
    end
  end

  describe "period boundary calculations" do
    # June 15, 2026 is a Monday
    test "start of week (Monday start)" do
      assert {:ok, result} =
               Calculator.calculate({:period_boundary, :start_of_week}, reference: @reference)

      # June 15 is a Monday, so start of week is June 15
      assert result == ~U[2026-06-15 00:00:00Z]
    end

    test "start of week with custom week_start" do
      # If week starts on Sunday (7), then start of week for Monday June 15
      # would be Sunday June 14
      assert {:ok, result} =
               Calculator.calculate({:period_boundary, :start_of_week},
                 reference: @reference,
                 week_start: 7
               )

      assert result == ~U[2026-06-14 00:00:00Z]
    end

    test "end of week" do
      assert {:ok, result} =
               Calculator.calculate({:period_boundary, :end_of_week}, reference: @reference)

      # Monday + 6 days = Sunday June 21
      assert result == ~U[2026-06-21 23:59:59Z]
    end

    test "start of month" do
      assert {:ok, result} =
               Calculator.calculate({:period_boundary, :start_of_month}, reference: @reference)

      assert result == ~U[2026-06-01 00:00:00Z]
    end

    test "end of month" do
      assert {:ok, result} =
               Calculator.calculate({:period_boundary, :end_of_month}, reference: @reference)

      assert result == ~U[2026-06-30 23:59:59Z]
    end

    test "start of year" do
      assert {:ok, result} =
               Calculator.calculate({:period_boundary, :start_of_year}, reference: @reference)

      assert result == ~U[2026-01-01 00:00:00Z]
    end

    test "end of year" do
      assert {:ok, result} =
               Calculator.calculate({:period_boundary, :end_of_year}, reference: @reference)

      assert result == ~U[2026-12-31 23:59:59Z]
    end

    test "start of quarter (Q2)" do
      assert {:ok, result} =
               Calculator.calculate({:period_boundary, :start_of_quarter}, reference: @reference)

      # June is Q2, starts April
      assert result == ~U[2026-04-01 00:00:00Z]
    end

    test "end of quarter (Q2)" do
      assert {:ok, result} =
               Calculator.calculate({:period_boundary, :end_of_quarter}, reference: @reference)

      # June is Q2, ends June 30
      assert result == ~U[2026-06-30 23:59:59Z]
    end

    test "start of quarter (Q1)" do
      ref = ~U[2026-02-15 10:00:00Z]

      assert {:ok, result} =
               Calculator.calculate({:period_boundary, :start_of_quarter}, reference: ref)

      assert result == ~U[2026-01-01 00:00:00Z]
    end

    test "start of quarter (Q3)" do
      ref = ~U[2026-08-15 10:00:00Z]

      assert {:ok, result} =
               Calculator.calculate({:period_boundary, :start_of_quarter}, reference: ref)

      assert result == ~U[2026-07-01 00:00:00Z]
    end

    test "start of quarter (Q4)" do
      ref = ~U[2026-11-15 10:00:00Z]

      assert {:ok, result} =
               Calculator.calculate({:period_boundary, :start_of_quarter}, reference: ref)

      assert result == ~U[2026-10-01 00:00:00Z]
    end

    test "end of day" do
      assert {:ok, result} =
               Calculator.calculate({:period_boundary, :end_of_day}, reference: @reference)

      assert result == ~U[2026-06-15 23:59:59Z]
    end
  end

  describe "ISO-8601 duration calculations" do
    test "adds days" do
      assert {:ok, result} =
               Calculator.calculate({:iso_duration, %{days: 3}}, reference: @reference)

      assert result == ~U[2026-06-18 10:30:00Z]
    end

    test "adds weeks" do
      assert {:ok, result} =
               Calculator.calculate({:iso_duration, %{weeks: 2}}, reference: @reference)

      assert result == ~U[2026-06-29 10:30:00Z]
    end

    test "adds years" do
      assert {:ok, result} =
               Calculator.calculate({:iso_duration, %{years: 1}}, reference: @reference)

      assert result == ~U[2027-06-15 10:30:00Z]
    end

    test "adds complex duration" do
      duration = %{years: 1, months: 2, days: 3, hours: 4, minutes: 5, seconds: 6}

      assert {:ok, result} =
               Calculator.calculate({:iso_duration, duration}, reference: @reference)

      # 2026-06-15 + 1Y = 2027-06-15
      # + 2M = 2027-08-15
      # + 3D = 2027-08-18
      # 10:30:00 + 4H = 14:30:00
      # + 5M = 14:35:00
      # + 6S = 14:35:06
      assert result == ~U[2027-08-18 14:35:06Z]
    end

    test "adds time-only duration" do
      assert {:ok, result} =
               Calculator.calculate({:iso_duration, %{hours: 12, minutes: 30}},
                 reference: @reference
               )

      assert result == ~U[2026-06-15 23:00:00Z]
    end
  end
end
