# Changelog

## [1.0.0-wip]

### Changed

- Requires `dartastic_opentelemetry ^1.1.0-beta.17` and
  `dartastic_opentelemetry_api >=1.0.0-rc.4 <1.0.0-rc.5`.
- First 1.0 release: the public API of this package is stable and
  follows semantic versioning from here on.

## [0.1.0] - 2026-08-10

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
