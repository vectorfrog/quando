# Taskwarrior Date Syntax Implementation

> Parent: [PLAN.md](../PLAN.md)
> Status: 26/26 tasks complete | 100% done
> Estimate: 24h | Actual: ~4h

---

## [x] Phase 1: Project Setup & Refactoring (3h)

- [x] Update project description in mix.exs to reflect Taskwarrior syntax focus (15m)
- [x] Update README.md with Taskwarrior syntax overview and examples (30m)
- [x] Archive old natural language parser code or refactor into new structure (45m)
- [x] Create test structure with comprehensive test cases for each syntax type (1h)
- [~] Set up property-based testing with StreamData for edge cases (30m) - deferred

## [x] Phase 2: Duration Offset Parsers (5h)

### Core Duration Units
- [x] Implement simple duration parser: `+/-Nd` (days) (30m)
- [x] Implement weeks parser: `+/-Nw` (1h)
- [x] Implement months parser: `+/-Nm` (months, not minutes) (1h)
- [x] Implement years parser: `+/-Ny` (30m)
- [x] Implement hours parser: `+/-Nh` (30m)
- [x] Implement minutes parser: `Nmin/Nmins` (handle collision with months) (1h)
- [x] Implement chained durations: `+1d+9h` (1.5h)

## [x] Phase 3: Date Synonyms (4h)

### Basic Synonyms
- [x] Implement `now`, `today`, `yesterday`, `tomorrow` (30m)
- [x] Implement day names with abbreviated forms: `monday`, `mon`, `tue`, etc. (1h)
- [x] Implement month names with abbreviations: `january`, `jan`, `feb`, etc. (1h)

### Period Boundaries
- [x] Implement week boundaries: `sow`, `eow` (start/end of week) (30m)
- [x] Implement month boundaries: `som`, `eom` (30m)
- [x] Implement year boundaries: `soy`, `eoy` (30m)
- [x] Implement quarter boundaries: `soq`, `eoq` (need to define Q1-Q4) (1h)

### Ordinals
- [x] Implement ordinal day parsing: `1st`, `2nd`, `3rd`, `15th`, `31st` (1h)

## [x] Phase 4: ISO-8601 Duration Support (3h)

- [x] Implement basic ISO-8601 duration parser: `P3D`, `P2W` (1h)
- [x] Implement complex ISO-8601: `P1Y2M3DT12H40M50S` (date + time parts) (1.5h)
- [x] Handle edge cases: `PT1H` (time-only), `P1M` (ambiguous month/minute) (30m)

## [x] Phase 5: DateTime Calculation Engine (4h)

- [x] Create offset calculator for duration-based expressions (1h)
- [x] Implement weekday resolution (next/previous occurrence) (1h)
- [x] Implement period boundary calculation (start/end of week/month/year/quarter) (1h)
- [x] Handle timezone-aware calculations (use system timezone by default) (1h)

## [x] Phase 6: Public API & Documentation (3h)

- [x] Design public API: `Quando.parse/2` with options (30m)
- [x] Implement error handling with clear error messages (1h)
- [x] Write comprehensive ExDoc documentation with examples (1h)
- [x] Create usage guide in README with common patterns (30m)

## [x] Phase 7: Testing & Validation (2h)

- [x] Write unit tests for all parser combinators (1h)
- [x] Write integration tests for complex expressions (30m)
- [~] Add property-based tests for duration calculations (30m) - deferred
- [x] Validate against Taskwarrior behavior (manual testing reference) (30m)

---

## Notes

### Key Design Decisions

1. **Minute vs Month Disambiguation**: Use `Nmin`/`Nmins` for minutes, `Nm` for months
2. **Week Start**: Assume Monday as start of week (configurable?)
3. **Quarter Definition**: Q1=Jan-Mar, Q2=Apr-Jun, Q3=Jul-Sep, Q4=Oct-Dec
4. **Timezone Handling**: Default to system timezone, allow override in options
5. **Chained Durations**: Process left-to-right: `+1d+9h` = (now + 1 day) + 9 hours

### Reference Links

- [Taskwarrior Date & Time Documentation](https://taskwarrior.org/docs/dates/)
- [ISO-8601 Duration Format](https://en.wikipedia.org/wiki/ISO_8601#Durations)
- [NimbleParsec Documentation](https://hexdocs.pm/nimble_parsec/)

### Future Enhancements (Not in Scope)

- [ ] Time-of-day specifications: `monday at 3pm`
- [ ] Relative expressions: `3 days before christmas`
- [ ] Recurrence patterns: `every monday`
- [ ] Custom period definitions
