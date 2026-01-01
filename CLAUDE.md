# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Quando is an Elixir library that parses Taskwarrior-style date expressions using NimbleParsec. Designed for CLI tools where users need quick relative date input.

**Supported syntax:**
- Duration offsets: `-7d`, `+2w`, `-2m`, `+1y`, `5min`, `3h`
- Chained durations: `+1d+9h`
- Synonyms: `now`, `today`, `yesterday`, `tomorrow`
- Day/month names: `monday`, `tue`, `january`, `feb`
- Period boundaries: `sow`, `eow`, `som`, `eom`, `soy`, `eoy`, `soq`, `eoq`
- Ordinals: `1st`, `2nd`, `15th`
- ISO-8601 durations: `P3D`, `P1Y2M3DT12H40M50S`

**Key disambiguation:** `m` = months, `min`/`mins` = minutes (follows Taskwarrior convention)

## Commands

```bash
mix deps.get          # Install dependencies
mix compile           # Compile the project
mix test              # Run all tests
mix test test/quando_test.exs:5  # Run a specific test by line number
mix format            # Format code
mix docs              # Generate documentation
```

## Architecture

- `lib/quando.ex` - Public API: `parse/1`, `parse!/1`
- `lib/quando/parser.ex` - NimbleParsec combinators for Taskwarrior syntax

## Dependencies

- `nimble_parsec` - Parser combinator library
- `ex_doc` - Documentation generator (dev only)

## Reference

- [Taskwarrior Dates](https://taskwarrior.org/docs/dates/)
- [Taskwarrior Durations](https://taskwarrior.org/docs/durations/)
