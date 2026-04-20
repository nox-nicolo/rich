// lib/features/overlay/viewmodel/overlay_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/overlay_state_model.dart';
import '../repository/overlay_repository.dart';
import '../service/overlay_service.dart';
import '../service/screenshot_service.dart';
import '../service/foreground_task_service.dart';

// ── ViewModel ─────────────────────────────────────────────────────────────────

class OverlayViewModel extends StateNotifier<OverlayState> {
  final OverlayRepository  _repo;
  final OverlayService     _overlayService;
  final ScreenshotService  _screenshotService;

  OverlayViewModel(
    this._repo,
    this._overlayService,
    this._screenshotService,
  ) : super(OverlayState.initial()) {
    _load();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final captures  = _repo.loadAllCaptures();
    final x         = _repo.loadPositionX();
    final y         = _repo.loadPositionY();
    final hasPerm   = await _overlayService.hasPermission();

    state = state.copyWith(
      captures:     captures,
      positionX:    x,
      positionY:    y,
      hasPermission: hasPerm,
    );
  }

  // ── Permission ────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final granted = await _overlayService.requestPermission();
    state = state.copyWith(hasPermission: granted);
    return granted;
  }

  // ── Visibility ────────────────────────────────────────────────────────────

  Future<void> show() async {
    if (!state.hasPermission) {
      await requestPermission();
      if (!state.hasPermission) return;
    }
    await ForegroundTaskService.start();
    await _overlayService.showOverlay();
    state = state.copyWith(isVisible: true);
  }

  Future<void> hide() async {
    await _overlayService.hideOverlay();
    state = state.copyWith(isVisible: false, isExpanded: false);
  }

  // ── Expand / Collapse pill ────────────────────────────────────────────────

  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void collapse() {
    state = state.copyWith(isExpanded: false);
  }

  // ── Position ──────────────────────────────────────────────────────────────

  Future<void> updatePosition(double x, double y) async {
    state = state.copyWith(positionX: x, positionY: y);
    await _repo.savePosition(x, y);
    await _overlayService.updatePosition(x, y);
  }

  // ── Text Note Capture ─────────────────────────────────────────────────────

  Future<void> addTextCapture(String text) async {
    if (text.trim().isEmpty) return;

    final capture = OverlayCapture(
      id:         const Uuid().v4(),
      type:       CaptureType.text,
      content:    text.trim(),
      capturedAt: DateTime.now(),
    );

    await _repo.saveCapture(capture);
    state = state.copyWith(
      captures: [...state.captures, capture],
    );
  }

  // ── Screenshot Capture ────────────────────────────────────────────────────

  Future<void> captureScreen() async {
    final path = await _screenshotService.captureScreen();
    if (path == null) return;

    final capture = OverlayCapture(
      id:         const Uuid().v4(),
      type:       CaptureType.screenshot,
      content:    path,
      capturedAt: DateTime.now(),
    );

    await _repo.saveCapture(capture);
    state = state.copyWith(
      captures: [...state.captures, capture],
    );
  }

  // ── AI Summary ────────────────────────────────────────────────────────────

  Future<void> summarizeCapture(String id) async {
    state = state.copyWith(isSummarizing: true);

    // AI summarization will be wired here in a later session
    // using the Claude API. For now it's a placeholder.
    await Future.delayed(const Duration(seconds: 1));

    state = state.copyWith(isSummarizing: false);
  }

  Future<void> updateSummary(String id, String summary) async {
    final updated = state.captures
        .firstWhere((c) => c.id == id)
        .copyWith(summary: summary);

    await _repo.updateCapture(updated);

    state = state.copyWith(
      captures: state.captures
          .map((c) => c.id == id ? updated : c)
          .toList(),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteCapture(String id) async {
    await _repo.deleteCapture(id);
    state = state.copyWith(
      captures: state.captures.where((c) => c.id != id).toList(),
    );
  }

  // ── Launch Main App ───────────────────────────────────────────────────────

  Future<void> goToDashboard() async {
    await _overlayService.launchMainApp();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final overlayRepositoryProvider = Provider<OverlayRepository>(
  (_) => OverlayRepository(),
);

final overlayServiceProvider = Provider<OverlayService>(
  (_) => OverlayService(),
);

final screenshotServiceProvider = Provider<ScreenshotService>(
  (_) => ScreenshotService(),
);

final overlayViewModelProvider =
    StateNotifierProvider<OverlayViewModel, OverlayState>((ref) {
  return OverlayViewModel(
    ref.read(overlayRepositoryProvider),
    ref.read(overlayServiceProvider),
    ref.read(screenshotServiceProvider),
  );
});
