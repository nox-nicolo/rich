// lib/features/betting/view/widgets/slip_review_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/rich_section_header.dart';
import '../../model/bet_model.dart';
import '../../model/betting_rule_model.dart';
import '../../viewmodel/betting_viewmodel.dart';

class SlipReviewWidget extends ConsumerStatefulWidget {
  const SlipReviewWidget({super.key});

  @override
  ConsumerState<SlipReviewWidget> createState() =>
      _SlipReviewWidgetState();
}

class _SlipReviewWidgetState
    extends ConsumerState<SlipReviewWidget> {
  final _descCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  double _stake = 0;
  double _odds = 1.5;
  BetType _type = BetType.single;
  bool _ruleChecked = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bettingViewModelProvider);
    final vm = ref.read(bettingViewModelProvider.notifier);
    final bankroll = state.bankroll;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RichSectionHeader(title: 'SLIP REVIEW'),

        // ── Description ───────────────────────────────────────────
        TextField(
          controller: _descCtrl,
          style: AppTypography.body
              .copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(
              hintText: 'What are you betting on?'),
          onChanged: (_) => setState(() => _errorMessage = null),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Type ──────────────────────────────────────────────────
        Row(
          children: BetType.values.map((t) {
            final isSelected = t == _type;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs),
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm),
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
                    child: Center(
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
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Stake + Odds ──────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STAKE', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    keyboardType: TextInputType.number,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText:
                          'Max TZS ${bankroll.maxStakeAmount.toStringAsFixed(0)}',
                      prefixText: 'TZS ',
                    ),
                    onChanged: (v) => setState(
                        () => _stake = double.tryParse(v) ?? 0),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ODDS', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    keyboardType: TextInputType.number,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                        hintText: 'e.g. 2.10'),
                    onChanged: (v) => setState(
                        () => _odds = double.tryParse(v) ?? 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Potential return ──────────────────────────────────────
        if (_stake > 0)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVar,
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Text('Potential return:',
                    style: AppTypography.body),
                const Spacer(),
                Text(
                  'TZS ${(_stake * _odds).toStringAsFixed(0)}',
                  style: AppTypography.mono
                      .copyWith(color: AppColors.success),
                ),
              ],
            ),
          ),

        const SizedBox(height: AppSpacing.md),

        // ── Reasoning ─────────────────────────────────────────────
        Text('WHY THIS BET?', style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _reasonCtrl,
          maxLines: 3,
          style: AppTypography.body
              .copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(
              hintText: 'State your edge clearly...'),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Rule checklist ────────────────────────────────────────
        const RichSectionHeader(title: 'RULE CHECK'),
        ...state.rules
            .where((r) => r.isHardRule)
            .map((rule) => _RuleCheckTile(rule: rule)),

        const SizedBox(height: AppSpacing.md),

        // ── Confirm ───────────────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _ruleChecked = !_ruleChecked),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _ruleChecked
                      ? AppColors.success.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: _ruleChecked
                        ? AppColors.success
                        : AppColors.border,
                    width: 1,
                  ),
                ),
                child: _ruleChecked
                    ? const Icon(Icons.check,
                        size: 12, color: AppColors.success)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'I confirm this bet follows all my rules',
                  style: AppTypography.body,
                ),
              ),
            ],
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _errorMessage!,
            style: AppTypography.caption
                .copyWith(color: AppColors.warning),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.isLocked
                ? null
                : () => _submit(context, vm, bankroll),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.isLocked
                  ? AppColors.locked
                  : AppColors.accent,
            ),
            child: Text(
              state.isLocked ? 'LOCKED' : 'PLACE BET',
              style: AppTypography.h3.copyWith(
                color: state.isLocked
                    ? AppColors.textDisabled
                    : AppColors.background,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit(
    BuildContext context,
    BettingViewModel vm,
    bankroll,
  ) async {
    if (_descCtrl.text.trim().isEmpty) {
      setState(
          () => _errorMessage = 'Please describe the bet.');
      return;
    }
    if (_stake <= 0) {
      setState(() => _errorMessage = 'Enter a valid stake.');
      return;
    }
    if (_stake > bankroll.maxStakeAmount) {
      setState(() => _errorMessage =
          'Stake exceeds max allowed (TZS ${bankroll.maxStakeAmount.toStringAsFixed(0)}).');
      return;
    }
    if (!_ruleChecked) {
      setState(() =>
          _errorMessage = 'Confirm all rules are followed.');
      return;
    }

    final success = await vm.placeBet(
      description: _descCtrl.text.trim(),
      stake: _stake,
      odds: _odds,
      type: _type,
      reasoning: _reasonCtrl.text.trim(),
      ruleChecked: _ruleChecked,
    );

    if (success) {
      _descCtrl.clear();
      _reasonCtrl.clear();
      setState(() {
        _stake = 0;
        _odds = 1.5;
        _ruleChecked = false;
        _errorMessage = null;
      });
    }
  }
}

class _RuleCheckTile extends StatelessWidget {
  final BettingRuleModel rule;

  const _RuleCheckTile({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: AppSpacing.xs + 2),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined,
              size: 12, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(rule.title,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
