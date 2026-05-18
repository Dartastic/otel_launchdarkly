// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_launchdarkly/otel_launchdarkly.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_launchdarkly-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('emits INTERNAL span with feature_flag.* attrs', () async {
    final value = await tracedLaunchDarklyEval<bool>(
      flagKey: 'new-checkout-flow',
      defaultValue: false,
      contextKey: 'user-42',
      invoke: () async => true,
      onSuccessVariant: (v) => v ? 'on' : 'off',
    );
    expect(value, isTrue);
    final span =
        spans.findSpanByName('feature_flag.evaluate new-checkout-flow');
    expect(span, isNotNull);
    expect(span!.kind, SpanKind.internal);
    final a = attrsOf(span);
    expect(a['feature_flag.key'], 'new-checkout-flow');
    expect(a['feature_flag.provider_name'], 'launchdarkly');
    expect(a['feature_flag.context.id'], 'user-42');
    expect(a['feature_flag.default'], 'false');
    expect(a['feature_flag.value'], 'true');
    expect(a['feature_flag.variant'], 'on');
  });

  test('records exception on throw', () async {
    await expectLater(
      tracedLaunchDarklyEval<bool>(
        flagKey: 'x',
        invoke: () async => throw StateError('client_not_ready'),
      ),
      throwsA(isA<StateError>()),
    );
    final span = spans.findSpanByName('feature_flag.evaluate x');
    expect(span!.status, SpanStatusCode.Error);
    expect(attrsOf(span)['error.type'], 'StateError');
  });

  test('suppression skips the span', () async {
    final v = await runWithoutLaunchDarklyInstrumentationAsync(() async {
      return tracedLaunchDarklyEval<bool>(
        flagKey: 'x',
        invoke: () async => false,
      );
    });
    expect(v, isFalse);
    expect(spans.findSpansStartingWith('feature_flag'), isEmpty);
  });
}
