# otel_talker

OpenTelemetry log bridge for
[`package:talker`](https://pub.dev/packages/talker).

Mirrors every `Talker` log / error / exception into the OpenTelemetry
logs pipeline so structured records flow to your OTel backend while
Talker keeps rendering its dev-friendly output. Records inherit
`trace_id` / `span_id` from `Context.current`, so log calls inside a
`Tracer.startActiveSpan` block are auto-correlated with the surrounding
span.

## Install

```yaml
dependencies:
  talker: ^5.0.0
  otel_talker: ^0.1.0
```

## Use

```dart
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_talker/otel_talker.dart';
import 'package:talker/talker.dart';

Future<void> main() async {
  await OTel.initialize(
    serviceName: 'my-app',
  );

  final talker = Talker(observer: OTelTalkerObserver());

  talker.info('user signed in');
  talker.warning('slow query');
  try {
    throw StateError('boom');
  } catch (e, st) {
    talker.handle(e, st, 'caught it');
  }
}
```

## Severity mapping

| Talker     | OTel `severity_number` |
|------------|------------------------|
| `verbose`  | `TRACE`                |
| `debug`    | `DEBUG`                |
| `info`     | `INFO`                 |
| `warning`  | `WARN`                 |
| `error`    | `ERROR`                |
| `critical` | `FATAL`                |

## Suppression

To avoid recursion or to mute a code section, run inside
`runWithoutTalkerInstrumentation`:

```dart
runWithoutTalkerInstrumentation(() {
  talker.info('not exported to OTel');
});
```

## License

Apache 2.0 — copyright Mindful Software LLC.
