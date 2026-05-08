// lib/feature/trading/view/widget/journal_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../model/trading_models.dart';
import '../../viewmodel/trading_viewmodel.dart';

// ── Entry point ──────────────────────────────────────────────────────────────

class JournalTab extends ConsumerWidget {
  const JournalTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(tradingViewModelProvider).todayJournal;
    final vm      = ref.read(tradingViewModelProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text("TODAY'S LOG", style: AppTypography.label),
              const Spacer(),
              _AddButton(onTap: () => _showTypePicker(context, vm)),
            ],
          ),
        ),
        if (entries.isEmpty)
          Expanded(child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_outlined,
                    color: AppColors.textMuted, size: 28),
                const SizedBox(height: 10),
                Text('No journal entries yet', style: AppTypography.body),
                const SizedBox(height: 4),
                Text('Tap ADD to log a trade, rule break or lesson',
                    style: AppTypography.caption),
              ],
            ),
          ))
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              physics: const BouncingScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _JournalTile(
                entry: entries[i],
                vm:    vm,
              ),
            ),
          ),
      ],
    );
  }

  void _showTypePicker(BuildContext context, TradingViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 3,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('NEW ENTRY', style: AppTypography.label),
            const SizedBox(height: 12),
            _TypeOption(
              icon:  Icons.show_chart,
              title: 'Trade',
              sub:   'Log a trade (pre + post)',
              onTap: () { Navigator.pop(ctx); _openTradeSheet(context, vm); },
            ),
            _TypeOption(
              icon:  Icons.warning_amber_outlined,
              title: 'Rule Break',
              sub:   'Document a broken rule',
              onTap: () { Navigator.pop(ctx); _openRuleBreakSheet(context, vm); },
            ),
            _TypeOption(
              icon:  Icons.assignment_turned_in_outlined,
              title: 'Session Review',
              sub:   'Wrap up today\'s session',
              onTap: () { Navigator.pop(ctx); _openSessionReviewSheet(context, vm); },
            ),
            _TypeOption(
              icon:  Icons.lightbulb_outline,
              title: 'Lesson Learned',
              sub:   'Insight or reflection',
              onTap: () { Navigator.pop(ctx); _openLessonSheet(context, vm); },
            ),
          ],
        ),
      ),
    );
  }

  void _openTradeSheet(BuildContext context, TradingViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _TradeEntrySheet(vm: vm),
    );
  }

  void _openRuleBreakSheet(BuildContext context, TradingViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RuleBreakSheet(vm: vm),
    );
  }

  void _openSessionReviewSheet(BuildContext context, TradingViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SessionReviewSheet(vm: vm),
    );
  }

  void _openLessonSheet(BuildContext context, TradingViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LessonSheet(vm: vm),
    );
  }
}

// ── Trade entry sheet (pre + close + lesson) ────────────────────────────────

class _TradeEntrySheet extends StatefulWidget {
  final TradingViewModel vm;
  final JournalEntry? existing;  // if set → closing an existing trade
  const _TradeEntrySheet({required this.vm, this.existing});

  @override
  State<_TradeEntrySheet> createState() => _TradeEntrySheetState();
}

class _TradeEntrySheetState extends State<_TradeEntrySheet> {
  late final TextEditingController instrumentCtrl;
  late final TextEditingController lotCtrl;
  late final TextEditingController entryCtrl;
  late final TextEditingController slCtrl;
  late final TextEditingController tpCtrl;
  late final TextEditingController setupCtrl;
  late final TextEditingController preNotesCtrl;

  late final TextEditingController exitCtrl;
  late final TextEditingController pnlCtrl;
  late final TextEditingController postNotesCtrl;
  late final TextEditingController lessonCtrl;

  late TradeDirection direction;
  late TradeOutcome   outcome;
  late bool           closeMode;  // show post-trade fields

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    instrumentCtrl = TextEditingController(text: e?.instrument ?? '');
    lotCtrl        = TextEditingController(text: e?.lotSize?.toString() ?? '');
    entryCtrl      = TextEditingController(text: e?.entry?.toString() ?? '');
    slCtrl         = TextEditingController(text: e?.stopLoss?.toString() ?? '');
    tpCtrl         = TextEditingController(text: e?.takeProfit?.toString() ?? '');
    setupCtrl      = TextEditingController(text: e?.setup ?? '');
    preNotesCtrl   = TextEditingController(text: e?.preNotes ?? '');

    exitCtrl       = TextEditingController(text: e?.exit?.toString() ?? '');
    pnlCtrl        = TextEditingController(text: e?.pnl?.toString() ?? '');
    postNotesCtrl  = TextEditingController(text: e?.postNotes ?? '');
    lessonCtrl     = TextEditingController(text: e?.lessonLearned ?? '');

    direction = e?.direction ?? TradeDirection.long;
    outcome   = e?.outcome ?? TradeOutcome.pending;
    // If editing any existing trade (open or closed), show close-mode fields
    closeMode = e != null;
  }

  @override
  void dispose() {
    instrumentCtrl.dispose();
    lotCtrl.dispose();
    entryCtrl.dispose();
    slCtrl.dispose();
    tpCtrl.dispose();
    setupCtrl.dispose();
    preNotesCtrl.dispose();
    exitCtrl.dispose();
    pnlCtrl.dispose();
    postNotesCtrl.dispose();
    lessonCtrl.dispose();
    super.dispose();
  }

  double? _riskReward() {
    final ent = double.tryParse(entryCtrl.text);
    final sl  = double.tryParse(slCtrl.text);
    final tp  = double.tryParse(tpCtrl.text);
    if (ent == null || sl == null || tp == null) return null;
    final risk   = (ent - sl).abs();
    final reward = (tp - ent).abs();
    if (risk == 0) return null;
    return reward / risk;
  }

  Future<void> _save() async {
    final instrument = instrumentCtrl.text.trim();
    final lot   = double.tryParse(lotCtrl.text.trim());
    final entry = double.tryParse(entryCtrl.text.trim());
    final sl    = double.tryParse(slCtrl.text.trim());
    final tp    = double.tryParse(tpCtrl.text.trim());
    if (instrument.isEmpty || lot == null || entry == null ||
        sl == null || tp == null) {
      return;
    }

    if (widget.existing == null) {
      // New pre-trade entry
      await widget.vm.createTradeEntry(
        instrument: instrument,
        direction:  direction,
        lotSize:    lot,
        entry:      entry,
        stopLoss:   sl,
        takeProfit: tp,
        setup:      setupCtrl.text.trim().isEmpty ? null : setupCtrl.text.trim(),
        preNotes:   preNotesCtrl.text.trim().isEmpty ? null : preNotesCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
      return;
    }

    // Editing existing — update all fields and optionally close
    final e = widget.existing!;
    final updated = e.copyWith(
      instrument: instrument,
      direction:  direction,
      lotSize:    lot,
      entry:      entry,
      stopLoss:   sl,
      takeProfit: tp,
      setup:      setupCtrl.text.trim().isEmpty ? null : setupCtrl.text.trim(),
      preNotes:   preNotesCtrl.text.trim().isEmpty ? null : preNotesCtrl.text.trim(),
      exit:       double.tryParse(exitCtrl.text.trim()),
      pnl:        double.tryParse(pnlCtrl.text.trim()),
      outcome:    outcome,
      postNotes:  postNotesCtrl.text.trim().isEmpty ? null : postNotesCtrl.text.trim(),
      lessonLearned: lessonCtrl.text.trim().isEmpty ? null : lessonCtrl.text.trim(),
    );
    await widget.vm.saveJournalEntry(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final rr = _riskReward();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 3,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(widget.existing == null ? 'NEW TRADE' : 'TRADE ENTRY',
                    style: AppTypography.label),
                const Spacer(),
                if (rr != null)
                  Text('R:R  1:${rr.toStringAsFixed(2)}',
                      style: AppTypography.chip.copyWith(
                          color: rr >= 2 ? AppColors.success : AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 14),

            // ── Pre-trade section ──────────────────────────────────────────
            _SectionLabel('PRE-TRADE'),
            _Field(ctrl: instrumentCtrl, hint: 'Instrument (e.g. EURUSD, XAUUSD)'),
            const SizedBox(height: 8),
            // Direction picker
            Row(
              children: TradeDirection.values
                  .where((d) => d != TradeDirection.none)
                  .map((d) {
                final sel = d == direction;
                final color = d == TradeDirection.long
                    ? AppColors.success : AppColors.warning;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setState(() => direction = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? color.withValues(alpha: 0.15)
                              : AppColors.surfaceVar,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: sel ? color : AppColors.border,
                              width: 0.5),
                        ),
                        child: Center(
                          child: Text(d.name.toUpperCase(),
                              style: AppTypography.chip.copyWith(
                                  color: sel ? color : AppColors.textMuted)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _Field(ctrl: lotCtrl, hint: 'Lot size',
                    inputType: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 8),
                Expanded(child: _Field(ctrl: entryCtrl, hint: 'Entry price',
                    inputType: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _Field(ctrl: slCtrl, hint: 'Stop loss',
                    inputType: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 8),
                Expanded(child: _Field(ctrl: tpCtrl, hint: 'Take profit',
                    inputType: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            const SizedBox(height: 8),
            _Field(ctrl: setupCtrl,    hint: 'Setup (e.g. BOS + FVG retest)'),
            const SizedBox(height: 8),
            _Field(ctrl: preNotesCtrl, hint: 'Reasoning / bias', maxLines: 3),

            // ── Close mode toggle ──────────────────────────────────────────
            if (widget.existing != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Switch(
                    value: closeMode,
                    onChanged: (v) => setState(() => closeMode = v),
                    activeThumbColor: AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  Text('Close this trade', style: AppTypography.caption),
                ],
              ),
            ],

            // ── Post-trade section ─────────────────────────────────────────
            if (closeMode && widget.existing != null) ...[
              const SizedBox(height: 14),
              _SectionLabel('POST-TRADE'),
              // Outcome picker
              Row(
                children: [
                  TradeOutcome.win, TradeOutcome.loss,
                  TradeOutcome.breakeven, TradeOutcome.cancelled,
                ].map((o) {
                  final sel = o == outcome;
                  Color c;
                  switch (o) {
                    case TradeOutcome.win:       c = AppColors.success; break;
                    case TradeOutcome.loss:      c = AppColors.warning; break;
                    case TradeOutcome.breakeven: c = AppColors.accent;  break;
                    default:                     c = AppColors.textMuted;
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: GestureDetector(
                        onTap: () => setState(() => outcome = o),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? c.withValues(alpha: 0.15)
                                : AppColors.surfaceVar,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: sel ? c : AppColors.border, width: 0.5),
                          ),
                          child: Center(
                            child: Text(o.label,
                                style: AppTypography.chip.copyWith(
                                    color: sel ? c : AppColors.textMuted,
                                    fontSize: 9)),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _Field(ctrl: exitCtrl, hint: 'Exit price',
                      inputType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 8),
                  Expanded(child: _Field(ctrl: pnlCtrl, hint: 'P&L (\$)',
                      inputType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true))),
                ],
              ),
              const SizedBox(height: 8),
              _Field(ctrl: postNotesCtrl, hint: 'Review (what happened?)',
                  maxLines: 3),
              const SizedBox(height: 10),
              _SectionLabel('LESSON LEARNED'),
              _Field(ctrl: lessonCtrl,
                  hint: 'What will you do differently next time?',
                  maxLines: 3),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  widget.existing == null
                      ? 'LOG TRADE'
                      : closeMode ? 'SAVE & CLOSE' : 'UPDATE',
                  style: AppTypography.h3.copyWith(
                      color: AppColors.background, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rule break sheet ─────────────────────────────────────────────────────────

class _RuleBreakSheet extends StatefulWidget {
  final TradingViewModel vm;
  final JournalEntry? existing;
  const _RuleBreakSheet({required this.vm, this.existing});

  @override
  State<_RuleBreakSheet> createState() => _RuleBreakSheetState();
}

class _RuleBreakSheetState extends State<_RuleBreakSheet> {
  late final TextEditingController titleCtrl;
  late final TextEditingController brokeCtrl;
  late final TextEditingController consequenceCtrl;
  late final TextEditingController emotionCtrl;
  late final TextEditingController lessonCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    titleCtrl       = TextEditingController(text: e?.ruleTitle ?? '');
    brokeCtrl       = TextEditingController(text: e?.ruleBroken ?? '');
    consequenceCtrl = TextEditingController(text: e?.consequence ?? '');
    emotionCtrl     = TextEditingController(text: e?.emotionalState ?? '');
    lessonCtrl      = TextEditingController(text: e?.lessonLearned ?? '');
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    brokeCtrl.dispose();
    consequenceCtrl.dispose();
    emotionCtrl.dispose();
    lessonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (titleCtrl.text.trim().isEmpty && brokeCtrl.text.trim().isEmpty) return;

    final entry = (widget.existing ?? JournalEntry(
      id:        const Uuid().v4(),
      type:      JournalEntryType.ruleBreak,
      createdAt: DateTime.now(),
    )).copyWith(
      ruleTitle:      titleCtrl.text.trim(),
      ruleBroken:     brokeCtrl.text.trim(),
      consequence:    consequenceCtrl.text.trim().isEmpty ? null : consequenceCtrl.text.trim(),
      emotionalState: emotionCtrl.text.trim().isEmpty ? null : emotionCtrl.text.trim(),
      lessonLearned:  lessonCtrl.text.trim().isEmpty ? null : lessonCtrl.text.trim(),
      ruleFollowed:   false,
    );
    await widget.vm.saveJournalEntry(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 3,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('RULE BREAK', style: AppTypography.label.copyWith(
                color: AppColors.warning)),
            const SizedBox(height: 14),
            _Field(ctrl: titleCtrl, hint: 'Which rule? (e.g. Max 2 trades)'),
            const SizedBox(height: 8),
            _Field(ctrl: brokeCtrl, hint: 'What did you do?', maxLines: 3),
            const SizedBox(height: 8),
            _Field(ctrl: consequenceCtrl,
                hint: 'Consequence / impact', maxLines: 2),
            const SizedBox(height: 8),
            _Field(ctrl: emotionCtrl,
                hint: 'Emotional state (e.g. revenge, greed, FOMO)'),
            const SizedBox(height: 10),
            _SectionLabel('LESSON LEARNED'),
            _Field(ctrl: lessonCtrl,
                hint: 'How will you prevent this next time?',
                maxLines: 3),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('SAVE', style: AppTypography.h3.copyWith(
                    color: AppColors.background, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Session review sheet (no lesson field) ──────────────────────────────────

class _SessionReviewSheet extends StatefulWidget {
  final TradingViewModel vm;
  final JournalEntry? existing;
  const _SessionReviewSheet({required this.vm, this.existing});

  @override
  State<_SessionReviewSheet> createState() => _SessionReviewSheetState();
}

class _SessionReviewSheetState extends State<_SessionReviewSheet> {
  late final TextEditingController tradesCtrl;
  late final TextEditingController winsCtrl;
  late final TextEditingController lossesCtrl;
  late final TextEditingController netCtrl;
  late final TextEditingController moodCtrl;
  late final TextEditingController mistakeCtrl;
  late final TextEditingController workedCtrl;
  late final TextEditingController notesCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    tradesCtrl  = TextEditingController(text: e?.tradesTaken?.toString() ?? '');
    winsCtrl    = TextEditingController(text: e?.wins?.toString() ?? '');
    lossesCtrl  = TextEditingController(text: e?.losses?.toString() ?? '');
    netCtrl     = TextEditingController(text: e?.netPnl?.toString() ?? '');
    moodCtrl    = TextEditingController(text: e?.mood ?? '');
    mistakeCtrl = TextEditingController(text: e?.biggestMistake ?? '');
    workedCtrl  = TextEditingController(text: e?.whatWorked ?? '');
    notesCtrl   = TextEditingController(text: e?.sessionNotes ?? '');
  }

  @override
  void dispose() {
    tradesCtrl.dispose();
    winsCtrl.dispose();
    lossesCtrl.dispose();
    netCtrl.dispose();
    moodCtrl.dispose();
    mistakeCtrl.dispose();
    workedCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final entry = (widget.existing ?? JournalEntry(
      id:        const Uuid().v4(),
      type:      JournalEntryType.sessionReview,
      createdAt: DateTime.now(),
    )).copyWith(
      tradesTaken:    int.tryParse(tradesCtrl.text.trim()),
      wins:           int.tryParse(winsCtrl.text.trim()),
      losses:         int.tryParse(lossesCtrl.text.trim()),
      netPnl:         double.tryParse(netCtrl.text.trim()),
      mood:           moodCtrl.text.trim().isEmpty ? null : moodCtrl.text.trim(),
      biggestMistake: mistakeCtrl.text.trim().isEmpty ? null : mistakeCtrl.text.trim(),
      whatWorked:     workedCtrl.text.trim().isEmpty ? null : workedCtrl.text.trim(),
      sessionNotes:   notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );
    await widget.vm.saveJournalEntry(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 3,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('SESSION REVIEW', style: AppTypography.label),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _Field(ctrl: tradesCtrl, hint: 'Trades',
                    inputType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: _Field(ctrl: winsCtrl, hint: 'Wins',
                    inputType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: _Field(ctrl: lossesCtrl, hint: 'Losses',
                    inputType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 8),
            _Field(ctrl: netCtrl, hint: 'Net P&L (\$)',
                inputType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true)),
            const SizedBox(height: 8),
            _Field(ctrl: moodCtrl,    hint: 'Mood / energy level'),
            const SizedBox(height: 8),
            _Field(ctrl: mistakeCtrl, hint: 'Biggest mistake today',
                maxLines: 2),
            const SizedBox(height: 8),
            _Field(ctrl: workedCtrl,  hint: 'What worked well',
                maxLines: 2),
            const SizedBox(height: 8),
            _Field(ctrl: notesCtrl,   hint: 'Other notes', maxLines: 2),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('SAVE', style: AppTypography.h3.copyWith(
                    color: AppColors.background, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lesson sheet ─────────────────────────────────────────────────────────────

class _LessonSheet extends StatefulWidget {
  final TradingViewModel vm;
  final JournalEntry? existing;
  const _LessonSheet({required this.vm, this.existing});

  @override
  State<_LessonSheet> createState() => _LessonSheetState();
}

class _LessonSheetState extends State<_LessonSheet> {
  late final TextEditingController contextCtrl;
  late final TextEditingController lessonCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    contextCtrl = TextEditingController(text: e?.content ?? '');
    lessonCtrl  = TextEditingController(text: e?.lessonLearned ?? '');
  }

  @override
  void dispose() {
    contextCtrl.dispose();
    lessonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (lessonCtrl.text.trim().isEmpty) return;

    final entry = (widget.existing ?? JournalEntry(
      id:        const Uuid().v4(),
      type:      JournalEntryType.lessonLearned,
      createdAt: DateTime.now(),
    )).copyWith(
      content:       contextCtrl.text.trim(),
      lessonLearned: lessonCtrl.text.trim(),
    );
    await widget.vm.saveJournalEntry(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 3,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('LESSON LEARNED', style: AppTypography.label),
          const SizedBox(height: 14),
          _Field(ctrl: contextCtrl,
              hint: 'Context (what triggered this lesson?)', maxLines: 3),
          const SizedBox(height: 8),
          _Field(ctrl: lessonCtrl, hint: 'The lesson', maxLines: 3),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('SAVE', style: AppTypography.h3.copyWith(
                  color: AppColors.background, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Journal tile (display + edit on tap) ─────────────────────────────────────

class _JournalTile extends StatelessWidget {
  final JournalEntry entry;
  final TradingViewModel vm;
  const _JournalTile({required this.entry, required this.vm});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openEditor(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _borderColor(),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                _typeBadge(),
                const SizedBox(width: 6),
                if (entry.type == JournalEntryType.trade && entry.instrument != null)
                  Text(entry.instrument!.toUpperCase(),
                      style: AppTypography.h3.copyWith(fontSize: 12)),
                const Spacer(),
                Text(_timeStr(), style: AppTypography.caption),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => vm.deleteJournalEntry(entry.id),
                  child: const Icon(Icons.close,
                      size: 14, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _body(context),
          ],
        ),
      ),
    );
  }

  Color _borderColor() {
    if (entry.type == JournalEntryType.ruleBreak) {
      return AppColors.warning.withValues(alpha: 0.3);
    }
    if (entry.type == JournalEntryType.trade) {
      switch (entry.outcome) {
        case TradeOutcome.win:       return AppColors.success.withValues(alpha: 0.3);
        case TradeOutcome.loss:      return AppColors.warning.withValues(alpha: 0.3);
        case TradeOutcome.pending:   return AppColors.accent.withValues(alpha: 0.3);
        default: break;
      }
    }
    return AppColors.border;
  }

  Widget _typeBadge() {
    Color c;
    String label;
    switch (entry.type) {
      case JournalEntryType.trade:
        c = entry.outcome == TradeOutcome.pending
            ? AppColors.accent
            : entry.outcome == TradeOutcome.win
                ? AppColors.success
                : entry.outcome == TradeOutcome.loss
                    ? AppColors.warning
                    : AppColors.textMuted;
        label = entry.outcome == TradeOutcome.pending
            ? 'OPEN' : entry.outcome.label;
        break;
      case JournalEntryType.ruleBreak:
        c = AppColors.warning; label = 'RULE BREAK'; break;
      case JournalEntryType.sessionReview:
        c = AppColors.accent; label = 'SESSION'; break;
      case JournalEntryType.lessonLearned:
        c = AppColors.textSecondary; label = 'LESSON'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: AppTypography.chip.copyWith(
          color: c, fontSize: 9)),
    );
  }

  String _timeStr() =>
      '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';

  Widget _body(BuildContext context) {
    switch (entry.type) {
      case JournalEntryType.trade:         return _tradeBody();
      case JournalEntryType.ruleBreak:     return _ruleBreakBody();
      case JournalEntryType.sessionReview: return _sessionBody();
      case JournalEntryType.lessonLearned: return _lessonBody();
    }
  }

  Widget _tradeBody() {
    final dirColor = entry.direction == TradeDirection.long
        ? AppColors.success
        : entry.direction == TradeDirection.short
            ? AppColors.warning
            : AppColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (entry.direction != TradeDirection.none)
              Text(entry.direction.name.toUpperCase(),
                  style: AppTypography.chip.copyWith(color: dirColor)),
            if (entry.lotSize != null) ...[
              const SizedBox(width: 8),
              Text('${entry.lotSize} lot', style: AppTypography.caption),
            ],
            if (entry.riskReward != null) ...[
              const SizedBox(width: 8),
              Text('R:R 1:${entry.riskReward!.toStringAsFixed(1)}',
                  style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted)),
            ],
            if (entry.pnl != null) ...[
              const Spacer(),
              Text('${entry.pnl! >= 0 ? '+' : ''}\$${entry.pnl!.toStringAsFixed(2)}',
                  style: AppTypography.chip.copyWith(
                      color: entry.pnl! >= 0
                          ? AppColors.success : AppColors.warning)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _kv('ENTRY', entry.entry?.toString() ?? '-'),
            const SizedBox(width: 12),
            _kv('SL', entry.stopLoss?.toString() ?? '-'),
            const SizedBox(width: 12),
            _kv('TP', entry.takeProfit?.toString() ?? '-'),
            if (entry.exit != null) ...[
              const SizedBox(width: 12),
              _kv('EXIT', entry.exit!.toString()),
            ],
          ],
        ),
        if (entry.setup != null && entry.setup!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Setup: ${entry.setup}', style: AppTypography.caption),
        ],
        if (entry.preNotes != null && entry.preNotes!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(entry.preNotes!, style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary)),
        ],
        if (entry.postNotes != null && entry.postNotes!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVar,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(entry.postNotes!, style: AppTypography.caption),
          ),
        ],
        if (entry.lessonLearned != null && entry.lessonLearned!.isNotEmpty)
          _lessonFooter(entry.lessonLearned!),
      ],
    );
  }

  Widget _ruleBreakBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.ruleTitle != null && entry.ruleTitle!.isNotEmpty)
          Text('Rule: ${entry.ruleTitle}',
              style: AppTypography.body.copyWith(color: AppColors.warning)),
        if (entry.ruleBroken != null && entry.ruleBroken!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(entry.ruleBroken!, style: AppTypography.caption),
        ],
        if (entry.consequence != null && entry.consequence!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('→ ${entry.consequence}',
              style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted)),
        ],
        if (entry.emotionalState != null && entry.emotionalState!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Emotion: ${entry.emotionalState}',
              style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted)),
        ],
        if (entry.lessonLearned != null && entry.lessonLearned!.isNotEmpty)
          _lessonFooter(entry.lessonLearned!),
      ],
    );
  }

  Widget _sessionBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (entry.tradesTaken != null)
              _kv('TRADES', '${entry.tradesTaken}'),
            if (entry.wins != null) ...[
              const SizedBox(width: 12),
              _kv('W', '${entry.wins}'),
            ],
            if (entry.losses != null) ...[
              const SizedBox(width: 12),
              _kv('L', '${entry.losses}'),
            ],
            const Spacer(),
            if (entry.netPnl != null)
              Text('${entry.netPnl! >= 0 ? '+' : ''}\$${entry.netPnl!.toStringAsFixed(2)}',
                  style: AppTypography.chip.copyWith(
                      color: entry.netPnl! >= 0
                          ? AppColors.success : AppColors.warning)),
          ],
        ),
        if (entry.mood != null && entry.mood!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Mood: ${entry.mood}', style: AppTypography.caption),
        ],
        if (entry.biggestMistake != null && entry.biggestMistake!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Mistake: ${entry.biggestMistake}',
              style: AppTypography.caption.copyWith(color: AppColors.warning)),
        ],
        if (entry.whatWorked != null && entry.whatWorked!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Worked: ${entry.whatWorked}',
              style: AppTypography.caption.copyWith(color: AppColors.success)),
        ],
        if (entry.sessionNotes != null && entry.sessionNotes!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(entry.sessionNotes!, style: AppTypography.caption),
        ],
      ],
    );
  }

  Widget _lessonBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.content.isNotEmpty)
          Text(entry.content, style: AppTypography.caption.copyWith(
              color: AppColors.textMuted)),
        if (entry.lessonLearned != null && entry.lessonLearned!.isNotEmpty)
          _lessonFooter(entry.lessonLearned!),
      ],
    );
  }

  Widget _lessonFooter(String text) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline,
              size: 12, color: AppColors.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: AppTypography.caption.copyWith(
                color: AppColors.accent)),
          ),
        ],
      ),
    ),
  );

  Widget _kv(String k, String v) => Row(
    children: [
      Text('$k ', style: AppTypography.chip.copyWith(
          color: AppColors.textMuted, fontSize: 9)),
      Text(v, style: AppTypography.mono.copyWith(fontSize: 11)),
    ],
  );

  void _openEditor(BuildContext context) {
    switch (entry.type) {
      case JournalEntryType.trade:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _TradeEntrySheet(vm: vm, existing: entry),
        );
        break;
      case JournalEntryType.ruleBreak:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _RuleBreakSheet(vm: vm, existing: entry),
        );
        break;
      case JournalEntryType.sessionReview:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _SessionReviewSheet(vm: vm, existing: entry),
        );
        break;
      case JournalEntryType.lessonLearned:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _LessonSheet(vm: vm, existing: entry),
        );
        break;
    }
  }
}

// ── Small helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(text, style: AppTypography.chip.copyWith(
        color: AppColors.textMuted, letterSpacing: 1.5)),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType inputType;
  final int maxLines;
  const _Field({
    required this.ctrl,
    required this.hint,
    this.inputType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller:   ctrl,
    keyboardType: inputType,
    maxLines:     maxLines,
    style: AppTypography.body.copyWith(color: AppColors.textPrimary),
    decoration: InputDecoration(hintText: hint),
  );
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVar,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text('ADD', style: AppTypography.chip),
        ],
      ),
    ),
  );
}

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _TypeOption({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVar,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.body),
                Text(sub, style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
        ],
      ),
    ),
  );
}
