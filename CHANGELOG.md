# Changelog

## [0.1.0-beta.1-wip]

### Added

- `OTelTalkerObserver` — a `package:talker` `TalkerObserver` that
  mirrors every log / error / exception into the OpenTelemetry logs
  pipeline.
- Severity mapping (verbose → TRACE, debug → DEBUG, info → INFO,
  warning → WARN, error → ERROR, critical → FATAL).
- `exception.type` / `exception.message` / `exception.stacktrace`
  attributes for `TalkerError` and `TalkerException` entries.
- Zone-scoped instrumentation suppression via
  `runWithoutTalkerInstrumentation()`.
