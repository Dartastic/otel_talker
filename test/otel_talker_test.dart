// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_talker/otel_talker.dart';
import 'package:talker/talker.dart';
import 'package:test/test.dart';

class _MemoryLogExporter implements LogRecordExporter {
  final List<LogRecord> records = [];
  bool _shutdown = false;

  @override
  Future<ExportResult> export(List<LogRecord> r) async {
    if (_shutdown) return ExportResult.failure;
    records.addAll(r);
    return ExportResult.success;
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

void main() {
  group('OTelTalkerObserver', () {
    late _MemoryLogExporter exporter;
    late Talker talker;

    setUp(() async {
      await OTel.reset();
      exporter = _MemoryLogExporter();
      await OTel.initialize(
        serviceName: 'otel_talker-test',
        detectPlatformResources: false,
        logRecordProcessor: SimpleLogRecordProcessor(exporter),
      );
      talker = Talker(observer: OTelTalkerObserver());
    });

    tearDown(() async {
      await OTel.shutdown();
      await OTel.reset();
    });

    test('emits an OTel log record for talker.info()', () async {
      talker.info('user signed in');
      await OTel.loggerProvider().forceFlush();
      expect(exporter.records, hasLength(1));
      final rec = exporter.records.first;
      expect(rec.body.toString(), contains('user signed in'));
      expect(rec.severityNumber, Severity.INFO);
    });

    test('maps severities across levels', () async {
      talker.verbose('v');
      talker.debug('d');
      talker.info('i');
      talker.warning('w');
      talker.error('e');
      talker.critical('c');
      await OTel.loggerProvider().forceFlush();
      final sevs = exporter.records.map((r) => r.severityNumber).toSet();
      expect(
          sevs,
          containsAll(<Severity>[
            Severity.TRACE,
            Severity.DEBUG,
            Severity.INFO,
            Severity.WARN,
            Severity.ERROR,
            Severity.FATAL,
          ]));
    });

    test('records exception attributes on talker.handle()', () async {
      try {
        throw StateError('boom');
      } catch (e, st) {
        talker.handle(e, st, 'caught it');
      }
      await OTel.loggerProvider().forceFlush();
      expect(exporter.records, isNotEmpty);
      final rec = exporter.records.last;
      final attrMap = <String, Object>{
        for (final a in rec.attributes?.toList() ?? <Attribute>[])
          a.key: a.value,
      };
      expect(attrMap['exception.type'], 'StateError');
      expect(attrMap['exception.message'], contains('boom'));
    });

    test('respects zone-scoped suppression', () async {
      runWithoutTalkerInstrumentation(() {
        talker.info('should not appear');
      });
      await OTel.loggerProvider().forceFlush();
      expect(exporter.records, isEmpty);
    });
  });
}
