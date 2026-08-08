// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

// A minimal app that bridges `package:talker` into the OpenTelemetry
// logs pipeline: every Talker log / error / exception becomes an OTel
// log record while Talker keeps rendering its dev-friendly output.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_talker/otel_talker.dart';
import 'package:talker/talker.dart';

Future<void> main() async {
  // Configure exporters/endpoint via the standard OTEL_* environment
  // variables (e.g. OTEL_EXPORTER_OTLP_ENDPOINT).
  await OTel.initialize(serviceName: 'otel-talker-example');

  final talker = Talker(observer: OTelTalkerObserver());

  // Plain logs map to OTel severities (info -> INFO, warning -> WARN, ...).
  talker.info('user signed in');
  talker.warning('disk almost full');

  // Handled errors carry exception.type / exception.message /
  // exception.stacktrace attributes on the log record.
  try {
    throw StateError('boom');
  } catch (e, st) {
    talker.handle(e, st, 'caught it');
  }

  // Log calls inside an active span are auto-correlated with it
  // (trace_id / span_id flow onto the records via Context.current).
  final tracer = OTel.tracerProvider().getTracer('otel_talker_example');
  await tracer.startActiveSpanAsync<void>(
    name: 'checkout',
    fn: (span) async {
      talker.info('correlated with the checkout span');
      span.end();
    },
  );

  await OTel.shutdown();
}
