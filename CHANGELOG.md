# Changelog

## [0.1.0-wip]

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
- Runnable example under `example/`.

### Changed

- Requires `talker` `^5.0.0`.
- Exception attribute keys now come from the semantic-conventions
  registry enums (`ExceptionAttributes`) instead of string literals
  (emitted keys are unchanged).
