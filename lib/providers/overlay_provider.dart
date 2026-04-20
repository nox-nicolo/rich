// lib/providers/overlay_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feature/overlay/model/overlay_state_model.dart';
import '../feature/overlay/repository/overlay_repository.dart';
import '../feature/overlay/service/overlay_service.dart';

class OverlayNotifier extends StateNotifier<OverlayState> {
  final OverlayRepository _repo;
  final OverlayService    _service;

  OverlayNotifier(this._repo, this._service)
      : super(OverlayState.initial()) {
    _load();
  }

  void _load() {
    final captures = _repo.loadAllCaptures();
    final x        = _repo.loadPositionX();
    final y        = _repo.loadPositionY();

    state = state.copyWith(
      captures:  captures,
      positionX: x,
      positionY: y,
    );

    // Check permission on load
    _service.hasPermission().then((granted) {
      state = state.copyWith(hasPermission: granted);
    });
  }

  // ── Visibility ────────────────────────────────────────────────────────────

  Future<void> show() async {
    if (!state.hasPermission) {
      final granted = await _service.requestPermission();
      state = state.copyWith(hasPermission: granted);
      if (!granted) return;
    }
    await _service.showOverlay();
    state = state.copyWith(isVisible: true);
  }

  Future<void> hide() async {
    await _service.hideOverlay();
    state = state.copyWith(isVisible: false, isExpanded: false);
  }

  // ── Expand / Collapse ─────────────────────────────────────────────────────

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
    await _service.updatePosition(x, y);
  }

  // ── Captures ──────────────────────────────────────────────────────────────

  Future<void> addCapture(OverlayCapture capture) async {
    await _repo.saveCapture(capture);
    state = state.copyWith(
      captures: [...state.captures, capture],
    );
  }

  Future<void> updateCaptureSummary(
      String id, String summary) async {
    final updated = state.captures
        .map((c) => c.id == id ? c.copyWith(summary: summary) : c)
        .toList();
    final capture = updated.firstWhere((c) => c.id == id);
    await _repo.updateCapture(capture);
    state = state.copyWith(captures: updated);
  }

  Future<void> deleteCapture(String id) async {
    await _repo.deleteCapture(id);
    state = state.copyWith(
      captures: state.captures.where((c) => c.id != id).toList(),
    );
  }

  // ── Summarizing ───────────────────────────────────────────────────────────

  void setSummarizing(bool value) {
    state = state.copyWith(isSummarizing: value);
  }
}

final _overlayRepositoryProvider = Provider<OverlayRepository>(
  (_) => OverlayRepository(),
);

final _overlayServiceProvider = Provider<OverlayService>(
  (_) => OverlayService(),
);

final overlayProvider =
    StateNotifierProvider<OverlayNotifier, OverlayState>(
  (ref) => OverlayNotifier(
    ref.read(_overlayRepositoryProvider),
    ref.read(_overlayServiceProvider),
  ),
);
