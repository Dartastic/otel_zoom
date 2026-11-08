// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_zoom_suppression.dart';

const _tracerName = 'dartastic_otel_libs_zoom';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps a Zoom REST API call (`meetings.create`, `users.list`,
/// `webinars.update`) in a CLIENT span.
Future<T> tracedZoom<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? meetingId,
  String? webinarId,
  String? userId,
}) async {
  if (zoomInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'zoom.resource': resource,
    'zoom.action': action,
    'zoom.operation': '$resource.$action',
  };
  if (meetingId != null) m['zoom.meeting.id'] = meetingId;
  if (webinarId != null) m['zoom.webinar.id'] = webinarId;
  if (userId != null) m['zoom.user.id'] = userId;

  final span = _tracer().startSpan(
    'zoom $resource.$action',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
