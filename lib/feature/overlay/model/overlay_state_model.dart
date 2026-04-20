// lib/features/overlay/model/overlay_state_model.dart

// ── Capture Type ──────────────────────────────────────────────────────────────

enum CaptureType { text, screenshot, note }

extension CaptureTypeX on CaptureType {
  String get label {
    switch (this) {
      case CaptureType.text:       return 'Text';
      case CaptureType.screenshot: return 'Screenshot';
      case CaptureType.note:       return 'Note';
    }
  }
}

// ── Overlay Capture ───────────────────────────────────────────────────────────

class OverlayCapture {
  final String id;
  final CaptureType type;
  final String content;      // text content or file path for screenshots
  final DateTime capturedAt;
  final String? summary;     // AI-generated summary (filled later)
  final String? savedToPillar; // e.g. 'trading', 'work', 'writing'

  const OverlayCapture({
    required this.id,
    required this.type,
    required this.content,
    required this.capturedAt,
    this.summary,
    this.savedToPillar,
  });

  OverlayCapture copyWith({
    String? summary,
    String? savedToPillar,
  }) {
    return OverlayCapture(
      id:            id,
      type:          type,
      content:       content,
      capturedAt:    capturedAt,
      summary:       summary       ?? this.summary,
      savedToPillar: savedToPillar ?? this.savedToPillar,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':            id,
    'type':          type.index,
    'content':       content,
    'capturedAt':    capturedAt.toIso8601String(),
    'summary':       summary,
    'savedToPillar': savedToPillar,
  };

  factory OverlayCapture.fromMap(Map<String, dynamic> map) {
    return OverlayCapture(
      id:            map['id'] as String,
      type:          CaptureType.values[map['type'] as int],
      content:       map['content'] as String,
      capturedAt:    DateTime.parse(map['capturedAt'] as String),
      summary:       map['summary'] as String?,
      savedToPillar: map['savedToPillar'] as String?,
    );
  }
}

// ── Overlay State ─────────────────────────────────────────────────────────────

class OverlayState {
  final bool isVisible;
  final bool isExpanded;          // pill is tapped — action buttons visible
  final double positionX;
  final double positionY;
  final List<OverlayCapture> captures;
  final bool isSummarizing;       // AI summarization in progress
  final bool hasPermission;       // SYSTEM_ALERT_WINDOW granted

  const OverlayState({
    required this.isVisible,
    required this.isExpanded,
    required this.positionX,
    required this.positionY,
    required this.captures,
    required this.isSummarizing,
    required this.hasPermission,
  });

  factory OverlayState.initial() => const OverlayState(
    isVisible:    false,
    isExpanded:   false,
    positionX:    20.0,
    positionY:    200.0,
    captures:     [],
    isSummarizing: false,
    hasPermission: false,
  );

  OverlayState copyWith({
    bool? isVisible,
    bool? isExpanded,
    double? positionX,
    double? positionY,
    List<OverlayCapture>? captures,
    bool? isSummarizing,
    bool? hasPermission,
  }) {
    return OverlayState(
      isVisible:     isVisible     ?? this.isVisible,
      isExpanded:    isExpanded    ?? this.isExpanded,
      positionX:     positionX     ?? this.positionX,
      positionY:     positionY     ?? this.positionY,
      captures:      captures      ?? this.captures,
      isSummarizing: isSummarizing ?? this.isSummarizing,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }

  int get captureCount => captures.length;
  List<OverlayCapture> get todayCaptures {
    final today = DateTime.now();
    return captures.where((c) =>
      c.capturedAt.year  == today.year  &&
      c.capturedAt.month == today.month &&
      c.capturedAt.day   == today.day,
    ).toList();
  }
}
