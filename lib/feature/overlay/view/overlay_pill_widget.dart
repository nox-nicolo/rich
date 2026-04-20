// lib/features/overlay/view/overlay_pill_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../viewmodel/overlay_viewmodel.dart';

class OverlayPillWidget extends ConsumerStatefulWidget {
  const OverlayPillWidget({super.key});

  @override
  ConsumerState<OverlayPillWidget> createState() =>
      _OverlayPillWidgetState();
}

class _OverlayPillWidgetState
    extends ConsumerState<OverlayPillWidget>
    with SingleTickerProviderStateMixin {

  late AnimationController _animCtrl;
  late Animation<double>   _expandAnim;

  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onToggle() {
    final vm = ref.read(overlayViewModelProvider.notifier);
    vm.toggleExpanded();
    if (!ref.read(overlayViewModelProvider).isExpanded) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(overlayViewModelProvider);
    final vm    = ref.read(overlayViewModelProvider.notifier);

    // Sync animation with state
    if (state.isExpanded && _animCtrl.status == AnimationStatus.dismissed) {
      _animCtrl.forward();
    } else if (!state.isExpanded && _animCtrl.status == AnimationStatus.completed) {
      _animCtrl.reverse();
    }

    return Positioned(
      left: state.positionX,
      top:  state.positionY,
      child: GestureDetector(
        onPanUpdate: (details) {
          vm.updatePosition(
            state.positionX + details.delta.dx,
            state.positionY + details.delta.dy,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Pill ─────────────────────────────────────────────────────
            _RichPill(
              expanded:     state.isExpanded,
              captureCount: state.todayCaptures.length,
              onTap:        _onToggle,
            ),

            // ── Action Buttons (animated expand) ─────────────────────────
            SizeTransition(
              sizeFactor:    _expandAnim,
              axisAlignment: -1,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: _ActionButtons(
                  isSummarizing: state.isSummarizing,
                  onNote:        () => _showNoteSheet(context, vm),
                  onCapture:     () => vm.captureScreen(),
                  onDashboard:   () => vm.goToDashboard(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteSheet(
      BuildContext context, OverlayViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => _QuickNoteSheet(
        controller: _noteCtrl,
        onSave: (text) {
          vm.addTextCapture(text);
          Navigator.of(context).pop();
          _noteCtrl.clear();
        },
      ),
    );
  }
}


// ── Pill ──────────────────────────────────────────────────────────────────────

class _RichPill extends StatelessWidget {
  final bool expanded;
  final int captureCount;
  final VoidCallback onTap;

  const _RichPill({
    required this.expanded,
    required this.captureCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.93),
          borderRadius:
              BorderRadius.circular(AppSpacing.radiusFull),
          border:
              Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color:  Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live dot
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'RICH',
              style: AppTypography.label.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 2,
              ),
            ),
            if (captureCount > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVar,
                  borderRadius: BorderRadius.circular(
                      AppSpacing.radiusFull),
                ),
                child: Text(
                  '$captureCount',
                  style: AppTypography.mono
                      .copyWith(fontSize: 9),
                ),
              ),
            ],
            const SizedBox(width: AppSpacing.xs + 2),
            AnimatedRotation(
              turns:    expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Action Buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final bool isSummarizing;
  final VoidCallback onNote;
  final VoidCallback onCapture;
  final VoidCallback onDashboard;

  const _ActionButtons({
    required this.isSummarizing,
    required this.onNote,
    required this.onCapture,
    required this.onDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.93),
        borderRadius:
            BorderRadius.circular(AppSpacing.radiusXl),
        border:
            Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color:  Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionBtn(
            icon:  Icons.edit_note_outlined,
            label: 'Note',
            onTap: onNote,
          ),
          const SizedBox(height: AppSpacing.xs),
          _ActionBtn(
            icon:  Icons.screenshot_monitor_outlined,
            label: 'Capture',
            onTap: onCapture,
            loading: isSummarizing,
          ),
          const SizedBox(height: AppSpacing.xs),
          _ActionBtn(
            icon:      Icons.space_dashboard_outlined,
            label:     'Command',
            onTap:     onDashboard,
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;
  final bool loading;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
    this.loading   = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.accent : AppColors.textSecondary;

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.accent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(AppSpacing.radiusMd),
          border: highlight
              ? Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  width: 0.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: color,
                    ),
                  )
                : Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.chip.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Quick Note Sheet ──────────────────────────────────────────────────────────

class _QuickNoteSheet extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>  onSave;

  const _QuickNoteSheet({
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Handle
          Center(
            child: Container(
              width: 36, height: 3,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(
                    AppSpacing.radiusFull),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          Text('QUICK NOTE', style: AppTypography.label),
          const SizedBox(height: AppSpacing.md),

          // Input
          TextField(
            controller: controller,
            autofocus:  true,
            maxLines:   4,
            style: AppTypography.body
                .copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Capture your thought...',
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) onSave(text);
              },
              child: Text(
                'SAVE',
                style: AppTypography.h3.copyWith(
                  color: AppColors.background,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
