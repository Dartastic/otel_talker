// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #otel_talker_suppress;

/// Whether Talker instrumentation is suppressed in the current [Zone].
///
/// `OTelTalkerObserver` checks this before emitting; inside a
/// [runWithoutTalkerInstrumentation] scope it returns `true` and the
/// observer drops the record.
bool talkerInstrumentationSuppressed() {
  return Zone.current[_suppressKey] == true;
}

/// Runs [body] with Talker instrumentation suppressed.
///
/// Talker calls made (synchronously) inside [body] are not mirrored
/// to the OTel logs pipeline. Useful to avoid feedback loops when
/// logging from within telemetry plumbing itself.
T runWithoutTalkerInstrumentation<T>(T Function() body) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}

/// Async variant of [runWithoutTalkerInstrumentation]: the suppression
/// zone stays in effect across `await` points inside [body].
Future<T> runWithoutTalkerInstrumentationAsync<T>(
  Future<T> Function() body,
) {
  return runZoned(body, zoneValues: {_suppressKey: true});
}
