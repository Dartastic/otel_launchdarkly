// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_launchdarkly/otel_launchdarkly.dart';

/// Traces Launchdarkly calls with OpenTelemetry.
///
/// `otel_launchdarkly` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Launchdarkly call in
/// [tracedLaunchDarklyEval]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'launchdarkly-example');

  // Wraps a LaunchDarkly flag evaluation in an INTERNAL OTel span following the OpenFeature/OTel feature_flag.* semantic conventions.
  final launchDarklyEvalId = await tracedLaunchDarklyEval<String>(
    flagKey: 'orders/2026/inv-1042.pdf',
    contextKey: 'orders/2026/inv-1042.pdf',
    invoke: () async {
      // Make the Launchdarkly call here, then report what it returned.
      return 'launchdarkly_8f3a2c';
    },
  );
  OTelLog.info(
      'tracedLaunchDarklyEval feature_flag.key returned $launchDarklyEvalId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutLaunchDarklyInstrumentationAsync.
  await runWithoutLaunchDarklyInstrumentationAsync(
    () => tracedLaunchDarklyEval<String>(
      flagKey: 'orders/2026/inv-1042.pdf',
      contextKey: 'orders/2026/inv-1042.pdf',
      invoke: () async {
        return 'launchdarkly_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
