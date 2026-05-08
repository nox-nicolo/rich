// lib/feature/settings/view/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/router/route_names.dart';

// 🔐 SECURITY
import '../../security/viewmodel/app_lock_viewmodel.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: AppSpacing.iconSm, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'SETTINGS',
          style: AppTypography.label.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 3,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [

          /// ── CAPITAL ─────────────────────────────
          _SectionHeader(label: 'CAPITAL'),
          const SizedBox(height: AppSpacing.sm),

          _SettingTile(
            icon: Icons.sports_soccer_outlined,
            title: 'Betting Starting Capital',
            subtitle: 'Set initial bankroll',
            onTap: () => _showBettingCapitalSheet(context),
          ),

          const SizedBox(height: AppSpacing.sm),

          _SettingTile(
            icon: Icons.show_chart_outlined,
            title: 'Trading Starting Capital',
            subtitle: 'Set trading capital',
            onTap: () => _showTradingCapitalSheet(context),
          ),

          /// ── BETTING ─────────────────────────────
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(label: 'BETTING'),
          const SizedBox(height: AppSpacing.sm),

          _SettingTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Bankroll Rules',
            subtitle: 'Limits & targets',
            onTap: () => _showBankrollRulesSheet(context),
          ),

          /// ── SECURITY ─────────────────────────────
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(label: 'SECURITY'),
          const SizedBox(height: AppSpacing.sm),

          _SwitchTile(
            icon: Icons.lock_outline,
            title: 'App Lock',
            subtitle: 'Require PIN to open app',
            value: lockState.settings.isEnabled,
            onChanged: (value) async {
              final vm = ref.read(appLockViewModelProvider.notifier);

              if (value) {
                _showSetPinSheet(context);
              } else {
                await vm.disableLock();
              }
            },
          ),

          const SizedBox(height: AppSpacing.sm),

          _SwitchTile(
            icon: Icons.fingerprint,
            title: 'Biometric Unlock',
            subtitle: 'Use fingerprint',
            value: lockState.settings.biometricsEnabled,
            onChanged: (value) async {
              await ref.read(appLockViewModelProvider.notifier)
                  .setBiometricsEnabled(value);
            },
          ),

          const SizedBox(height: AppSpacing.sm),

          _SettingTile(
            icon: Icons.timer_outlined,
            title: 'Auto Lock',
            subtitle: 'Set inactivity timeout',
            onTap: () => _showAutoLockSheet(context),
          ),

          const SizedBox(height: AppSpacing.sm),

          _SettingTile(
            icon: Icons.password_outlined,
            title: 'Change PIN',
            subtitle: 'Update security PIN',
            onTap: () => _showChangePinSheet(context),
          ),

          /// ── TRACKING ─────────────────────────────
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(label: 'TRACKING'),
          const SizedBox(height: AppSpacing.sm),

          _SettingTile(
            icon: Icons.insights_outlined,
            title: 'Reports',
            subtitle: 'Last 35 days + monthly summaries',
            onTap: () => context.push(RouteNames.reports),
          ),

          /// ── APP ─────────────────────────────
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(label: 'APP'),
          const SizedBox(height: AppSpacing.sm),

          _SettingTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: 'RICH v1.0.0',
            onTap: null,
          ),
        ],
      ),
    );
  }

  // ── SECURITY SHEETS ─────────────────────────────

  void _showSetPinSheet(BuildContext context) {
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SET PIN', style: AppTypography.label),
            const SizedBox(height: 12),

            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'Enter PIN',
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                final pin = ctrl.text.trim();
                if (pin.length < 4) return;

                await ref.read(appLockViewModelProvider.notifier)
                    .enableLockWithPin(pin: pin);

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('ENABLE LOCK'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAutoLockSheet(BuildContext context) {
    final vm = ref.read(appLockViewModelProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text('Immediately'), onTap: () {
            vm.setAutoLockMinutes(0);
            Navigator.pop(context);
          }),
          ListTile(title: const Text('1 minute'), onTap: () {
            vm.setAutoLockMinutes(1);
            Navigator.pop(context);
          }),
          ListTile(title: const Text('5 minutes'), onTap: () {
            vm.setAutoLockMinutes(5);
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  void _showChangePinSheet(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('CHANGE PIN', style: AppTypography.label),
            const SizedBox(height: 12),

            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Old PIN'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'New PIN'),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                await ref.read(appLockViewModelProvider.notifier)
                    .changePin(
                  oldPin: oldCtrl.text.trim(),
                  newPin: newCtrl.text.trim(),
                );

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('UPDATE PIN'),
            ),
          ],
        ),
      ),
    );
  }

  // ── EXISTING SHEETS (UNCHANGED) ─────────────────────────────

  void _showBettingCapitalSheet(BuildContext context) {}
  void _showTradingCapitalSheet(BuildContext context) {}
  void _showBankrollRulesSheet(BuildContext context) {}
}

// ── HELPERS ─────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppTypography.chip.copyWith(color: AppColors.textMuted));
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.body
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textPrimary)),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
