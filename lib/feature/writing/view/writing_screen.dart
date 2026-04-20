// lib/feature/writing/view/writing_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../model/writing_session_model.dart';
import '../viewmodel/writing_viewmodel.dart';

class WritingScreen extends ConsumerWidget {
  const WritingScreen({super.key});

  static const _tabs = ['WRITE', 'LOG', 'STATS'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(writingViewModelProvider);
    final vm    = ref.read(writingViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('WRITING', style: AppTypography.label.copyWith(
          color: AppColors.textPrimary, letterSpacing: 3,
        )),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: _TodayWordCountBadge(count: state.todayWordCount),
          ),
        ],
      ),
      body: Column(
        children: [
          _RichTabBar(
            tabs:     _tabs,
            selected: state.activeTab,
            onSelect: vm.setTab,
          ),
          Expanded(
            child: state.activeTab == 'WRITE'
                ? _WriteTab(
                    vm: vm,
                    // Re-key the write tab on the editing id so its
                    // internal controllers are rebuilt from scratch
                    // whenever the user switches between "new entry" and
                    // "continue session X" — avoids stale text carrying
                    // over into an unrelated edit.
                    key: ValueKey(
                        'write-${state.editingSessionId ?? 'new'}'),
                  )
                : state.activeTab == 'LOG'
                    ? _LogTab(sessions: state.allSessions)
                    : _StatsTab(state: state),
          ),
        ],
      ),
    );
  }
}


// ── Today badge ───────────────────────────────────────────────────────────────

class _TodayWordCountBadge extends StatelessWidget {
  final int count;
  const _TodayWordCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text('$count w', style: AppTypography.chip.copyWith(
        color: AppColors.accent,
      )),
    );
  }
}


// ── Tab bar ───────────────────────────────────────────────────────────────────

class _RichTabBar extends StatelessWidget {
  final List<String> tabs;
  final String selected;
  final ValueChanged<String> onSelect;

  const _RichTabBar({required this.tabs, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: tabs.map((tab) {
          final sel = tab == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => onSelect(tab),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tab, style: AppTypography.label.copyWith(
                    color: sel ? AppColors.textPrimary : AppColors.textMuted,
                  )),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 1, width: 20,
                    color: sel ? AppColors.accent : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


// ── Write Tab ─────────────────────────────────────────────────────────────────

class _WriteTab extends ConsumerStatefulWidget {
  final WritingViewModel vm;
  const _WriteTab({required this.vm, super.key});

  @override
  ConsumerState<_WriteTab> createState() => _WriteTabState();
}

class _WriteTabState extends ConsumerState<_WriteTab> {
  final _contentCtrl    = TextEditingController();
  final _titleCtrl      = TextEditingController();
  final _purposeCtrl    = TextEditingController();
  final _reflectionCtrl = TextEditingController();

  WritingCategory _category  = WritingCategory.journaling;
  int _moodBefore = 3;
  int _moodAfter  = 3;
  int _wordCount  = 0;
  bool _saving    = false;

  /// Captured once in initState from the viewmodel's editing handle. We
  /// don't watch this via ref because the widget is rebuilt (via ValueKey
  /// in the parent) whenever the editing session changes — so a single
  /// read is enough and avoids rebuilding the text field on every keystroke.
  String? _editingId;

  @override
  void initState() {
    super.initState();

    // Prefill from the session the user chose to continue, if any.
    final editing =
        ref.read(writingViewModelProvider).editingSession;
    if (editing != null) {
      _editingId             = editing.id;
      _contentCtrl.text      = editing.content;
      _titleCtrl.text        = editing.title ?? '';
      _purposeCtrl.text      = editing.purpose ?? '';
      _reflectionCtrl.text   = editing.reflection ?? '';
      _category              = editing.category;
      _moodBefore            = editing.moodBefore;
      _moodAfter             = editing.moodAfter;
      _wordCount             = _countWords(editing.content);
    }

    widget.vm.beginWriting();
    _contentCtrl.addListener(() {
      final wc = _countWords(_contentCtrl.text);
      if (wc != _wordCount) setState(() => _wordCount = wc);
    });
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _titleCtrl.dispose();
    _purposeCtrl.dispose();
    _reflectionCtrl.dispose();
    super.dispose();
  }

  int _countWords(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  bool get _isEditing => _editingId != null;

  Future<void> _save() async {
    if (_contentCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final title      = _titleCtrl.text.trim().isEmpty
        ? null : _titleCtrl.text.trim();
    final purpose    = _purposeCtrl.text.trim().isEmpty
        ? null : _purposeCtrl.text.trim();
    final reflection = _reflectionCtrl.text.trim().isEmpty
        ? null : _reflectionCtrl.text.trim();

    if (_isEditing) {
      await widget.vm.updateSession(
        id:         _editingId!,
        content:    _contentCtrl.text,
        category:   _category,
        moodBefore: _moodBefore,
        moodAfter:  _moodAfter,
        title:      title,
        purpose:    purpose,
        reflection: reflection,
      );
    } else {
      await widget.vm.saveSession(
        content:    _contentCtrl.text,
        category:   _category,
        moodBefore: _moodBefore,
        moodAfter:  _moodAfter,
        title:      title,
        purpose:    purpose,
        reflection: reflection,
      );
    }

    if (!mounted) return;
    final wasEditing = _isEditing;
    _contentCtrl.clear();
    _titleCtrl.clear();
    _purposeCtrl.clear();
    _reflectionCtrl.clear();
    setState(() {
      _saving     = false;
      _wordCount  = 0;
      _moodBefore = 3;
      _moodAfter  = 3;
      _editingId  = null;
    });
    widget.vm.beginWriting();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasEditing
            ? 'Session updated.'
            : 'Session saved.'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surface,
      ),
    );
  }

  void _discardEdit() {
    widget.vm.cancelEditing();
    // The parent ValueKey will rebuild this tab fresh — no manual reset
    // needed here.
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [

        // ── Continue-writing banner ────────────────────────────────────────
        // Shown whenever the user is editing an existing session so the
        // state of the screen is unambiguous (otherwise a pre-filled
        // editor looks identical to a fresh one with recovered text).
        if (_isEditing) ...[
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_note_outlined,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Continuing a previous session',
                    style: AppTypography.chip
                        .copyWith(color: AppColors.accent),
                  ),
                ),
                GestureDetector(
                  onTap: _discardEdit,
                  child: Text('NEW ENTRY',
                      style: AppTypography.chip.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Word count live indicator
        Row(
          children: [
            Text('$_wordCount words', style: AppTypography.caption.copyWith(
              color: _wordCount > 0 ? AppColors.accent : AppColors.textMuted,
            )),
            const Spacer(),
            // Category selector
            GestureDetector(
              onTap: _showCategoryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVar,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Text(_category.label, style: AppTypography.chip),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Optional title
        TextField(
          controller: _titleCtrl,
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Title (optional)',
            hintStyle: AppTypography.h2.copyWith(color: AppColors.textMuted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Main content area
        TextField(
          controller: _contentCtrl,
          maxLines: null,
          autofocus: true,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
            fontSize: 15,
            height: 1.75,
          ),
          decoration: InputDecoration(
            hintText: 'Begin writing...',
            hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
        ),

        const SizedBox(height: AppSpacing.x3l),
        const Divider(color: AppColors.divider, thickness: 0.5),
        const SizedBox(height: AppSpacing.lg),

        // Mood before
        _MoodRow(
          label:    'MOOD BEFORE',
          value:    _moodBefore,
          onChange: (v) => setState(() => _moodBefore = v),
        ),
        const SizedBox(height: AppSpacing.md),
        _MoodRow(
          label:    'MOOD AFTER',
          value:    _moodAfter,
          onChange: (v) => setState(() => _moodAfter = v),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Optional purpose
        TextField(
          controller: _purposeCtrl,
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Purpose of this writing (optional)',
            hintStyle: AppTypography.caption.copyWith(color: AppColors.textMuted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),

        // Optional reflection
        TextField(
          controller: _reflectionCtrl,
          maxLines: 3,
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'What should improve next time? (optional)',
            hintStyle: AppTypography.caption.copyWith(color: AppColors.textMuted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),

        const SizedBox(height: AppSpacing.x3l),

        // Save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _saving
                  ? 'SAVING...'
                  : (_isEditing ? 'UPDATE SESSION' : 'SAVE SESSION'),
              style: AppTypography.label.copyWith(color: AppColors.background),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.x3l),
      ],
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Center(child: Container(
            width: 36, height: 3,
            decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),
          ...WritingCategory.values.map((c) => ListTile(
            title: Text(c.label, style: AppTypography.body),
            trailing: _category == c
                ? const Icon(Icons.check, color: AppColors.accent, size: 18)
                : null,
            onTap: () {
              setState(() => _category = c);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


// ── Mood row ──────────────────────────────────────────────────────────────────

class _MoodRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChange;

  const _MoodRow({required this.label, required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTypography.label.copyWith(fontSize: 10)),
        const Spacer(),
        Row(
          children: List.generate(5, (i) {
            final v = i + 1;
            final selected = v <= value;
            return GestureDetector(
              onTap: () => onChange(v),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  selected ? Icons.circle : Icons.circle_outlined,
                  size: 14,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}


// ── Log Tab ───────────────────────────────────────────────────────────────────

class _LogTab extends StatelessWidget {
  final List<WritingSession> sessions;
  const _LogTab({required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_note_outlined,
                color: AppColors.textMuted, size: 32),
            const SizedBox(height: 12),
            Text('No sessions yet', style: AppTypography.body),
            const SizedBox(height: 4),
            Text('Write and save a session to see it here',
                style: AppTypography.caption),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _SessionTile(session: sessions[i]),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  final WritingSession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mins = (session.durationSeconds / 60).round();
    return GestureDetector(
      onTap: () => _showDetail(context, ref),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVar,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(session.category.label,
                      style: AppTypography.chip.copyWith(fontSize: 9)),
                ),
                const SizedBox(width: 8),
                Text('${session.wordCount} words',
                    style: AppTypography.chip.copyWith(color: AppColors.accent)),
                const Spacer(),
                Text(
                  _formatDate(session.createdAt),
                  style: AppTypography.caption,
                ),
              ],
            ),
            if (session.title != null) ...[
              const SizedBox(height: 8),
              Text(session.title!,
                  style: AppTypography.h3.copyWith(fontSize: 13)),
            ],
            const SizedBox(height: 6),
            Text(
              session.content.length > 120
                  ? '${session.content.substring(0, 120)}...'
                  : session.content,
              style: AppTypography.caption.copyWith(height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (mins > 0) ...[
              const SizedBox(height: 8),
              Text('$mins min session',
                  style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Center(child: Container(
              width: 36, height: 3,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),
            if (session.title != null)
              Text(session.title!, style: AppTypography.h2),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(session.category.label, style: AppTypography.caption),
                const SizedBox(width: 12),
                Text('${session.wordCount} words',
                    style: AppTypography.caption.copyWith(color: AppColors.accent)),
                const Spacer(),
                Text(_formatDate(session.createdAt), style: AppTypography.caption),
              ],
            ),
            if (session.updatedAt != null) ...[
              const SizedBox(height: 4),
              Text('edited ${_formatDate(session.updatedAt!)}',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textMuted, fontSize: 10)),
            ],
            const SizedBox(height: 20),
            Text(session.content, style: AppTypography.body.copyWith(
              color: AppColors.textPrimary, height: 1.75,
            )),
            if (session.reflection != null) ...[
              const SizedBox(height: 20),
              const Divider(color: AppColors.divider, thickness: 0.5),
              const SizedBox(height: 12),
              Text('REFLECTION', style: AppTypography.label),
              const SizedBox(height: 6),
              Text(session.reflection!, style: AppTypography.body.copyWith(
                color: AppColors.textSecondary, height: 1.5,
              )),
            ],

            const SizedBox(height: 24),

            // ── Actions: continue & delete ─────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      ref
                          .read(writingViewModelProvider.notifier)
                          .startEditingSession(session.id);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text('CONTINUE WRITING',
                        style: AppTypography.label.copyWith(
                            color: AppColors.background, fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppColors.warning.withValues(alpha: 0.4),
                          width: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        _confirmDelete(context, sheetCtx, ref),
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: AppColors.warning),
                    label: Text('DELETE',
                        style: AppTypography.label.copyWith(
                            color: AppColors.warning, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, BuildContext sheetCtx, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete session?', style: AppTypography.h3),
        content: Text(
          'This will permanently remove ${session.wordCount} words from your log.',
          style: AppTypography.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text('CANCEL',
                style: AppTypography.label
                    .copyWith(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text('DELETE',
                style: AppTypography.label
                    .copyWith(color: AppColors.warning)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(writingViewModelProvider.notifier)
          .deleteSession(session.id);
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
    }
  }
}


// ── Stats Tab ─────────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final WritingState state;
  const _StatsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      children: [
        // Streak
        _StatCard(
          label: 'WRITING STREAK',
          value: '${state.streak}',
          sub:   'consecutive days',
          icon:  Icons.local_fire_department_outlined,
          color: AppColors.warning,
        ),
        const SizedBox(height: 10),

        // Word counts
        Row(
          children: [
            Expanded(child: _StatCard(
              label: 'TODAY',
              value: '${state.todayWordCount}',
              sub:   'words',
              icon:  Icons.today_outlined,
              color: AppColors.accent,
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(
              label: 'THIS WEEK',
              value: '${state.weeklyWordCount}',
              sub:   'words',
              icon:  Icons.calendar_view_week_outlined,
              color: AppColors.success,
            )),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(child: _StatCard(
              label: 'THIS MONTH',
              value: '${state.monthlyWordCount}',
              sub:   'words',
              icon:  Icons.calendar_month_outlined,
              color: AppColors.textSecondary,
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(
              label: 'TOTAL SESSIONS',
              value: '${state.totalSessions}',
              sub:   'sessions',
              icon:  Icons.layers_outlined,
              color: AppColors.textMuted,
            )),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(child: _StatCard(
              label: 'BEST DAY',
              value: '${state.bestDayWordCount}',
              sub:   'words',
              icon:  Icons.emoji_events_outlined,
              color: AppColors.warning,
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(
              label: 'AVG / SESSION',
              value: state.avgWordsPerSession.toStringAsFixed(0),
              sub:   'words',
              icon:  Icons.bar_chart_outlined,
              color: AppColors.accent,
            )),
          ],
        ),

        // Category breakdown
        if (state.allSessions.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('CATEGORY BREAKDOWN', style: AppTypography.label),
          const SizedBox(height: 12),
          ..._categoryBreakdown(state.allSessions).entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CategoryBar(
                label: e.key,
                count: e.value,
                total: state.totalSessions,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Map<String, int> _categoryBreakdown(List<WritingSession> sessions) {
    final map = <String, int>{};
    for (final s in sessions) {
      map[s.category.label] = (map[s.category.label] ?? 0) + 1;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label, required this.value, required this.sub,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(value, style: AppTypography.h2.copyWith(fontSize: 22)),
          Text(sub,   style: AppTypography.caption),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.label.copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final int count, total;

  const _CategoryBar({required this.label, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTypography.caption),
            const Spacer(),
            Text('$count', style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 3,
            backgroundColor: AppColors.surfaceVar,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
      ],
    );
  }
}
