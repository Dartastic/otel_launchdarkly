// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_launchdarkly_suppression.dart';

const _tracerName = 'dartastic_otel_libs_launchdarkly';
const _providerName = 'launchdarkly';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps a LaunchDarkly flag evaluation in an INTERNAL OTel span
/// following the OpenFeature/OTel `feature_flag.*` semantic
/// conventions.
///
/// Works with `launchdarkly_flutter_client_sdk`, the server SDK, or
/// any direct HTTP integration — pass your call inside [invoke] and
/// the bridge records:
///
/// - `feature_flag.key` — the flag key
/// - `feature_flag.provider_name` — `launchdarkly`
/// - `feature_flag.variant` — the variant index (when available)
/// - `feature_flag.context.id` — the LaunchDarkly context key
///
/// ```dart
/// final showNewCheckout = await tracedLaunchDarklyEval<bool>(
///   flagKey: 'new-checkout-flow',
///   contextKey: user.id,
///   defaultValue: false,
///   invoke: () => ldClient.boolVariation(
///     'new-checkout-flow',
///     defaultValue: false,
///   ),
///   onSuccessVariant: (v) => v ? 'on' : 'off',
/// );
/// ```
///
/// Use this around the variation call itself; pair with your business
/// span (which becomes the parent) so flag evaluations decorate the
/// trace at the point they affect logic.
Future<T> tracedLaunchDarklyEval<T>({
  required String flagKey,
  required Future<T> Function() invoke,
  T? defaultValue,
  String? contextKey,
  String? Function(T)? onSuccessVariant,
}) async {
  if (launchDarklyInstrumentationSuppressed()) return invoke();

  final m = <String, Object>{
    'feature_flag.key': flagKey,
    'feature_flag.provider_name': _providerName,
  };
  if (contextKey != null) m['feature_flag.context.id'] = contextKey;
  if (defaultValue != null) {
    m['feature_flag.default'] = defaultValue.toString();
  }

  final span = _tracer().startSpan(
    'feature_flag.evaluate $flagKey',
    kind: SpanKind.internal,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final value = await invoke();
    final extra = <Attribute<Object>>[
      OTelAPI.attributeString('feature_flag.value', value.toString()),
    ];
    final variant = onSuccessVariant?.call(value);
    if (variant != null) {
      extra.add(OTelAPI.attributeString('feature_flag.variant', variant));
    }
    span.addAttributes(OTelAPI.attributes(extra));
    return value;
  } catch (e, st) {
    span.addAttributes(
      OTelAPI.attributes([
        OTelAPI.attributeString(
          ErrorAttributes.errorType.key,
          e.runtimeType.toString(),
        ),
      ]),
    );
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
