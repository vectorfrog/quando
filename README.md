# Quando

A Taskwarrior-style date expression parser for Elixir. Parse expressions like `+7d`, `eom`, `monday`, or `P1Y2M3D` into DateTime structs using NimbleParsec.

## Installation

Add `quando` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:quando, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
# Parse relative durations
{:ok, dt} = Quando.parse("+7d")      # 7 days from now
{:ok, dt} = Quando.parse("-2w")      # 2 weeks ago
{:ok, dt} = Quando.parse("+3m")      # 3 months from now (m = months)
{:ok, dt} = Quando.parse("30min")    # 30 minutes from now

# Parse chained durations
{:ok, dt} = Quando.parse("+1d+9h")   # Tomorrow at this time + 9 hours

# Parse date synonyms
{:ok, dt} = Quando.parse("today")    # Start of today
{:ok, dt} = Quando.parse("tomorrow") # Start of tomorrow

# Parse period boundaries
{:ok, dt} = Quando.parse("eom")      # End of month
{:ok, dt} = Quando.parse("sow")      # Start of week

# Parse day/month names
{:ok, dt} = Quando.parse("monday")   # Next Monday
{:ok, dt} = Quando.parse("fri")      # Next Friday
{:ok, dt} = Quando.parse("december") # December 1st

# Parse ordinals
{:ok, dt} = Quando.parse("15th")     # 15th of current/next month

# Parse ISO-8601 durations
{:ok, dt} = Quando.parse("P3D")      # 3 days from now
{:ok, dt} = Quando.parse("PT1H30M")  # 1 hour 30 minutes from now

# Bang version raises on error
dt = Quando.parse!("+7d")

# Get the parsed AST without calculation
{:ok, ast} = Quando.parse_ast("+7d")
# => {:ok, {:chained_duration, [{:duration, %{sign: :+, amount: 7, unit: :days}}]}}
```

## Supported Syntax

### Duration Offsets

| Expression | Description |
|------------|-------------|
| `+7d`, `-3d`, `5d` | Days |
| `+2w`, `-1w` | Weeks |
| `+3m`, `-2m` | Months (note: `m` = months) |
| `+1y`, `-2y` | Years |
| `+5h`, `-2h` | Hours |
| `30min`, `45mins` | Minutes (use `min`/`mins` for minutes) |
| `+30s`, `-15sec` | Seconds |

### Chained Durations

Chain multiple durations together:

| Expression | Description |
|------------|-------------|
| `+1d+9h` | Tomorrow plus 9 hours |
| `-2w+3d` | Two weeks ago plus 3 days |
| `+1y+2m+3d` | 1 year, 2 months, 3 days from now |

### Date Synonyms

| Expression | Description |
|------------|-------------|
| `now` | Current time |
| `today` | Start of today (00:00:00) |
| `yesterday` | Start of yesterday |
| `tomorrow` | Start of tomorrow |

### Day Names

Full names and abbreviations are supported:

`monday`, `mon`, `tuesday`, `tue`, `wednesday`, `wed`, `thursday`, `thu`, `friday`, `fri`, `saturday`, `sat`, `sunday`, `sun`

Returns the next occurrence of the specified day.

### Month Names

Full names and abbreviations are supported:

`january`, `jan`, `february`, `feb`, `march`, `mar`, `april`, `apr`, `may`, `june`, `jun`, `july`, `jul`, `august`, `aug`, `september`, `sep`, `october`, `oct`, `november`, `nov`, `december`, `dec`

Returns the 1st of the next occurrence of the specified month.

### Period Boundaries

| Expression | Description |
|------------|-------------|
| `sow`, `socw` | Start of week |
| `eow`, `eocw` | End of week |
| `som`, `socm` | Start of month |
| `eom`, `eocm` | End of month |
| `soy`, `socy` | Start of year |
| `eoy`, `eocy` | End of year |
| `soq` | Start of quarter |
| `eoq` | End of quarter |
| `eod` | End of day |

### Ordinals

| Expression | Description |
|------------|-------------|
| `1st`, `2nd`, `3rd` | Day of month |
| `15th`, `31st` | Day of month |

Returns the specified day of the current month if not yet passed, otherwise the next month.

### ISO-8601 Durations

| Expression | Description |
|------------|-------------|
| `P3D` | 3 days |
| `P2W` | 2 weeks |
| `P1Y` | 1 year |
| `P1Y2M3D` | 1 year, 2 months, 3 days |
| `PT1H` | 1 hour |
| `PT30M` | 30 minutes |
| `PT45S` | 45 seconds |
| `P1Y2M3DT12H40M50S` | Complex duration |

## Options

### Reference Time

By default, calculations are relative to `DateTime.utc_now()`. You can specify a custom reference time:

```elixir
reference = ~U[2026-06-15 10:00:00Z]
{:ok, dt} = Quando.parse("+7d", reference: reference)
# => ~U[2026-06-22 10:00:00Z]
```

### Week Start

By default, weeks start on Monday (1). You can specify a different start day:

```elixir
# Week starts on Sunday
{:ok, dt} = Quando.parse("sow", week_start: 7)
```

## Key Disambiguation

Following Taskwarrior conventions:
- `m` = **months** (not minutes)
- `min` or `mins` = **minutes**

This matches CLI tools where quick typing is important and months are more commonly referenced than minutes for task scheduling.

## Reference

- [Taskwarrior Date Documentation](https://taskwarrior.org/docs/dates/)
- [Taskwarrior Duration Documentation](https://taskwarrior.org/docs/durations/)
- [ISO-8601 Duration Format](https://en.wikipedia.org/wiki/ISO_8601#Durations)

## License

MIT - see [LICENSE](LICENSE)
