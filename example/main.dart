// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_zoom/otel_zoom.dart';

/// Traces Zoom calls with OpenTelemetry.
///
/// `otel_zoom` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Zoom call in
/// [tracedZoom]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'zoom-example');

  // Wraps a Zoom REST API call (meetings.create, users.list, webinars.update) in a CLIENT span.
  final zoomId = await tracedZoom<String>(
    resource: 'Order',
    action: 'example',
    meetingId: 'meeting_8f3a2c',
    webinarId: 'webinar_8f3a2c',
    userId: 'user_8f3a2c',
    invoke: () async {
      // Make the Zoom call here, then report what it returned.
      return 'zoom_8f3a2c';
    },
  );
  OTelLog.info('tracedZoom meetings.create returned $zoomId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutZoomInstrumentationAsync.
  await runWithoutZoomInstrumentationAsync(
    () => tracedZoom<String>(
      resource: 'Order',
      action: 'example',
      meetingId: 'meeting_8f3a2c',
      webinarId: 'webinar_8f3a2c',
      userId: 'user_8f3a2c',
      invoke: () async {
        return 'zoom_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
