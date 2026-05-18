// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

/// OpenTelemetry instrumentation for LaunchDarkly feature-flag
/// evaluations.
///
/// Single helper `tracedLaunchDarklyEval(...)` wraps any flag
/// variation call in an INTERNAL span carrying the OTel / OpenFeature
/// `feature_flag.*` semantic-convention attributes (key,
/// provider_name=launchdarkly, value, variant, context.id, default).
library;

export 'src/otel_launchdarkly.dart';
export 'src/otel_launchdarkly_suppression.dart';
