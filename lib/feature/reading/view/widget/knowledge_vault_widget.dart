// lib/features/reading/view/widgets/knowledge_vault_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/knowledge_note_model.dart';
import '../../viewmodel/reading_viewmodel.dart';

class KnowledgeVaultWidget extends ConsumerWidget {
  const KnowledgeVaultWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readingViewModelProvider);
    final vm = ref.read(readingViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichSectionHeader(
          title: 'KNOWLEDGE VAULT',
          trailing: GestureDetector(
            onTap: () => _showAddNoteSheet(context, vm, state),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceVar,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                    color: AppColors.border, width: 0.5),
              ),
              child: const Icon(Icons.add,
                  size: 14, color: AppColors.textSecondary),
            ),
          ),
        ),

        // ── Pinned ────────────────────────────────────────────────
        if (state.pinnedNotes.isNotEmpty) ...[
          Text('PINNED', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          ...state.pinnedNotes.map(
            (note) => Padding(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _NoteTile(
                note: note,
                onPin: () => vm.togglePinNote(note.id),
                onDelete: () => vm.deleteNote(note.id),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── All notes ─────────────────────────────────────────────
        if (state.allNotes.where((n) => !n.pinned).isNotEmpty) ...[
          Text('ALL NOTES', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          ...state.allNotes.where((n) => !n.pinned).map(
                (note) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _NoteTile(
                    note: note,
                    onPin: () => vm.togglePinNote(note.id),
                    onDelete: () => vm.deleteNote(note.id),
                  ),
                ),
              ),
        ],

        if (state.allNotes.isEmpty) _EmptyVault(),
      ],
    );
  }

  void _showAddNoteSheet(
    BuildContext context,
    ReadingViewModel vm,
    ReadingState state,
  ) {
    final contentCtrl = TextEditingController();
    KnowledgeNoteType type = KnowledgeNoteType.lesson;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('ADD TO VAULT', style: AppTypography.label),
              const SizedBox(height: AppSpacing.xs),
              Text(
                type.prompt,
                style: AppTypography.body
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: KnowledgeNoteType.values.map((t) {
                    final isSelected = t == type;
                    return Padding(
                      padding: const EdgeInsets.only(
                          right: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () => setState(() => type = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent.withValues(alpha: 0.1)
                                : AppColors.surfaceVar,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            t.label,
                            style: AppTypography.chip.copyWith(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: contentCtrl,
                maxLines: 5,
                autofocus: true,
                style: AppTypography.body
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: type.prompt,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (contentCtrl.text.trim().isNotEmpty) {
                      vm.addKnowledgeNote(
                        bookId: state.activeBook?.id,
                        bookTitle: state.activeBook?.title,
                        content: contentCtrl.text.trim(),
                        type: type,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(
                    'SAVE TO VAULT',
                    style: AppTypography.h3.copyWith(
                        color: AppColors.background, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Note tile in the vault — shows the captured idea plus (optionally) the
/// user's own reflection below it. Tapping "MY VIEW" opens a sheet to add
/// or edit a free-form reflection separate from the original quoted idea.
class _NoteTile extends ConsumerWidget {
  final KnowledgeNoteModel note;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _NoteTile({
    required this.note,
    required this.onPin,
    required this.onDelete,
  });

  void _showReflectionSheet(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: note.reflection ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('MY VIEW ON THIS IDEA', style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'What do you think about this? How does it apply to you?',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            // Quote the original idea so the user can see what they're
            // responding to without scrolling.
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceVar,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                border: Border(
                  left: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.5),
                      width: 2),
                ),
              ),
              child: Text(
                note.content,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 6,
              style:
                  AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  hintText: 'Your take, counter-arguments, examples…'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (note.reflection != null &&
                    note.reflection!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.border, width: 0.5),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref
                            .read(readingViewModelProvider.notifier)
                            .updateNoteReflection(note.id, '');
                      },
                      child: Text('CLEAR',
                          style: AppTypography.label
                              .copyWith(color: AppColors.textMuted)),
                    ),
                  ),
                if (note.reflection != null &&
                    note.reflection!.isNotEmpty)
                  const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ref
                          .read(readingViewModelProvider.notifier)
                          .updateNoteReflection(note.id, ctrl.text);
                    },
                    child: Text(
                      'SAVE REFLECTION',
                      style: AppTypography.h3.copyWith(
                          color: AppColors.background, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasReflection =
        note.reflection != null && note.reflection!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: note.pinned
              ? AppColors.accent.withValues(alpha: 0.2)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs + 2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVar,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  note.type.label,
                  style: AppTypography.chip.copyWith(fontSize: 9),
                ),
              ),
              if (note.bookTitle != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    note.bookTitle!,
                    style: AppTypography.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
              GestureDetector(
                onTap: onPin,
                child: Icon(
                  note.pinned
                      ? Icons.push_pin
                      : Icons.push_pin_outlined,
                  size: 14,
                  color: note.pinned
                      ? AppColors.accent
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close,
                    size: 14, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            note.content,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),

          // ── Personal reflection block ─────────────────────────────
          if (hasReflection) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.06),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                border: Border(
                  left: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.6),
                      width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MY VIEW',
                      style: AppTypography.label
                          .copyWith(color: AppColors.accent)),
                  const SizedBox(height: 2),
                  Text(
                    note.reflection!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                RichDateUtils.formatShort(note.createdAt),
                style: AppTypography.caption,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showReflectionSheet(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                        color:
                            AppColors.accent.withValues(alpha: 0.3),
                        width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasReflection
                            ? Icons.edit_outlined
                            : Icons.add_comment_outlined,
                        size: 11,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasReflection ? 'EDIT MY VIEW' : 'ADD MY VIEW',
                        style: AppTypography.chip.copyWith(
                          color: AppColors.accent,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: AppSpacing.x3l),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.library_books_outlined,
                color: AppColors.textMuted, size: 28),
            const SizedBox(height: AppSpacing.md),
            Text('Knowledge vault is empty',
                style: AppTypography.body),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add lessons, applications, and insights',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}
