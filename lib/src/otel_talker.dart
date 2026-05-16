// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:talker/talker.dart' as talker_lib;

import 'otel_talker_suppression.dart';

/// A `package:talker` [TalkerObserver] that mirrors every event
/// into the OpenTelemetry logs pipeline.
///
/// Attach it to a `Talker` instance so structured records flow to
/// your OTel backend while Talker continues to render its own
/// dev-friendly output:
///
/// ```dart
/// final talker = Talker(observer: OTelTalkerObserver());
/// talker.info('user signed in');
/// ```
///
/// Each `TalkerData` becomes one OTel log record:
/// - `body` — the rendered message (`data.generateTextMessage()` if
///   `useRenderedMessage` is `true`, otherwise `data.message`)
/// - `severity_number` — mapped from `data.logLevel` (verbose →
///   TRACE, debug → DEBUG, info → INFO, warning → WARN, error →
///   ERROR, critical → FATAL)
/// - `severity_text` — `data.logLevel.name`
/// - `timestamp` — `data.time`
/// - attributes — `exception.type` / `exception.message` /
///   `exception.stacktrace` when the entry is a `TalkerError` or
///   `TalkerException`
///
/// Records inherit `trace_id` / `span_id` from `Context.current` for
/// free via the OTel logger's `emit` path — log calls inside a
/// `Tracer.startActiveSpan` block are auto-correlated with the
/// surrounding span.
class OTelTalkerObserver extends talker_lib.TalkerObserver {
  /// Creates the observer.
  ///
  /// - [loggerProvider] — defaults to `OTel.loggerProvider()` at
  ///   first use.
  /// - [loggerName] — instrumentation scope name. Defaults to
  ///   `package.talker`.
  /// - [includeStackTrace] — when `false`, the stack trace from
  ///   `TalkerError` / `TalkerException` is not added as an
  ///   attribute. Defaults to `true`.
  /// - [useRenderedMessage] — when `true` (default), the body is the
  ///   fully rendered Talker output (which preserves Talker's
  ///   prefixes). When `false`, only the raw message is emitted.
  OTelTalkerObserver({
    LoggerProvider? loggerProvider,
    String loggerName = 'package.talker',
    bool includeStackTrace = true,
    bool useRenderedMessage = true,
  })  : _provider = loggerProvider,
        _loggerName = loggerName,
        _includeStackTrace = includeStackTrace,
        _useRenderedMessage = useRenderedMessage;

  final LoggerProvider? _provider;
  final String _loggerName;
  final bool _includeStackTrace;
  final bool _useRenderedMessage;

  @override
  void onLog(talker_lib.TalkerData log) {
    _emit(log, error: null, stackTrace: null);
  }

  @override
  void onError(talker_lib.TalkerError err) {
    _emit(
      err,
      error: err.error,
      stackTrace: err.stackTrace,
    );
  }

  @override
  void onException(talker_lib.TalkerException err) {
    _emit(
      err,
      error: err.exception,
      stackTrace: err.stackTrace,
    );
  }

  void _emit(
    talker_lib.TalkerData data, {
    required Object? error,
    required StackTrace? stackTrace,
  }) {
    if (talkerInstrumentationSuppressed()) return;
    final provider = _provider ?? OTel.loggerProvider();
    final logger = provider.getLogger(_loggerName);

    final attrs = <Attribute<Object>>[];
    if (error != null) {
      attrs
        ..add(OTel.attributeString(
          'exception.type',
          error.runtimeType.toString(),
        ))
        ..add(OTel.attributeString(
          'exception.message',
          error.toString(),
        ));
    }
    if (_includeStackTrace && stackTrace != null) {
      attrs.add(OTel.attributeString(
        'exception.stacktrace',
        stackTrace.toString(),
      ));
    }

    final body =
        _useRenderedMessage ? data.generateTextMessage() : (data.message ?? '');
    final levelName = data.logLevel?.name ?? 'info';

    logger.emit(
      timeStamp: data.time,
      severityNumber: _mapLevel(data.logLevel),
      severityText: levelName,
      body: body,
      attributes: attrs.isEmpty ? null : OTel.attributes(attrs),
    );
  }
}

Severity _mapLevel(talker_lib.LogLevel? level) {
  switch (level) {
    case talker_lib.LogLevel.verbose:
      return Severity.TRACE;
    case talker_lib.LogLevel.debug:
      return Severity.DEBUG;
    case talker_lib.LogLevel.info:
      return Severity.INFO;
    case talker_lib.LogLevel.warning:
      return Severity.WARN;
    case talker_lib.LogLevel.error:
      return Severity.ERROR;
    case talker_lib.LogLevel.critical:
      return Severity.FATAL;
    case null:
      return Severity.INFO;
  }
}
