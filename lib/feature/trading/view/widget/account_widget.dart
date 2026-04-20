// lib/feature/trading/view/widget/account_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../model/trading_account_model.dart';
import '../../viewmodel/trading_viewmodel.dart';

/// Account tab — connect a broker account (currently MetaApi) and see
/// live positions + recent history mirrored from the trading platform.
class AccountTab extends ConsumerWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradingViewModelProvider);
    final vm    = ref.read(tradingViewModelProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConnectionCard(
            config:    state.accountConfig,
            info:      state.brokerInfo,
            syncing:   state.accountSyncing,
            error:     state.accountError,
            onConnect: () => _showConnectSheet(context, vm),
            onSync:    vm.syncAccount,
            onDisconnect: () => _confirmDisconnect(context, vm),
          ),
          const SizedBox(height: 20),
          if (state.accountConfig != null) ...[
            Text('POSITIONS & HISTORY', style: AppTypography.label),
            const SizedBox(height: 10),
            if (state.brokerTrades.isEmpty)
              _EmptyState(
                syncing: state.accountSyncing,
                hasError: state.accountError != null,
              )
            else
              ...state.brokerTrades.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _BrokerTradeTile(trade: t),
                  )),
          ] else ...[
            Text(
              'Connect a broker account to mirror your trades into the app. '
              'Currently supported: MetaApi (MT4 / MT5 cloud bridge). '
              'The app only READS from the account — it never places orders.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showConnectSheet(BuildContext context, TradingViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ConnectSheet(vm: vm),
    );
  }

  Future<void> _confirmDisconnect(
      BuildContext context, TradingViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Disconnect account?', style: AppTypography.h3),
        content: Text(
          'Stored credentials and cached trades will be removed from this device.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('CANCEL',
                  style: AppTypography.chip.copyWith(color: AppColors.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('DISCONNECT',
                  style: AppTypography.chip.copyWith(color: AppColors.warning))),
        ],
      ),
    );
    if (confirmed == true) await vm.disconnectAccount();
  }
}

// ── Connection Card ──────────────────────────────────────────────────────────

class _ConnectionCard extends StatelessWidget {
  final TradingAccountConfig? config;
  final BrokerAccountInfo? info;
  final bool syncing;
  final String? error;
  final VoidCallback onConnect;
  final VoidCallback onSync;
  final VoidCallback onDisconnect;

  const _ConnectionCard({
    required this.config,
    required this.info,
    required this.syncing,
    required this.error,
    required this.onConnect,
    required this.onSync,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final connected = config != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: connected
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                connected ? Icons.link : Icons.link_off,
                size: 16,
                color: connected ? AppColors.success : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                connected ? 'ACCOUNT CONNECTED' : 'NO ACCOUNT',
                style: AppTypography.label.copyWith(
                  color: connected ? AppColors.success : AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (connected)
                GestureDetector(
                  onTap: syncing ? null : onSync,
                  child: syncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: AppColors.accent),
                        )
                      : const Icon(Icons.refresh,
                          size: 16, color: AppColors.accent),
                )
              else
                GestureDetector(
                  onTap: onConnect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.accent, width: 0.5),
                    ),
                    child: Text('CONNECT',
                        style: AppTypography.chip
                            .copyWith(color: AppColors.accent)),
                  ),
                ),
            ],
          ),
          if (connected) ...[
            const SizedBox(height: 14),
            Text(
              config!.nickname?.isNotEmpty == true
                  ? config!.nickname!
                  : '${config!.platform.label} · ${config!.login}',
              style: AppTypography.h3,
            ),
            if (config!.server.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                    '${config!.platform.label} · ${config!.server}',
                    style: AppTypography.caption),
              ),
            const SizedBox(height: 14),
            if (info != null) _InfoGrid(info: info!),
            if (error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                      width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(error!,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.warning)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onDisconnect,
              child: Text('DISCONNECT ACCOUNT',
                  style: AppTypography.chip.copyWith(
                      color: AppColors.warning, letterSpacing: 2)),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final BrokerAccountInfo info;
  const _InfoGrid({required this.info});

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption),
            const SizedBox(height: 2),
            Text(value,
                style: AppTypography.h3.copyWith(fontSize: 14)),
          ],
        );
    String fmt(double v) => '${v.toStringAsFixed(2)} ${info.currency}';

    return Row(
      children: [
        Expanded(child: cell('BALANCE', fmt(info.balance))),
        Expanded(child: cell('EQUITY',  fmt(info.equity))),
        Expanded(child: cell('FREE',    fmt(info.freeMargin))),
      ],
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool syncing;
  final bool hasError;
  const _EmptyState({required this.syncing, required this.hasError});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            syncing
                ? Icons.sync
                : hasError
                    ? Icons.error_outline
                    : Icons.inbox_outlined,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              syncing
                  ? 'Syncing…'
                  : hasError
                      ? 'Could not load trades. Check credentials or retry.'
                      : 'No trades in the last 7 days.',
              style: AppTypography.body
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Broker Trade Tile ────────────────────────────────────────────────────────

class _BrokerTradeTile extends StatelessWidget {
  final BrokerTrade trade;
  const _BrokerTradeTile({required this.trade});

  @override
  Widget build(BuildContext context) {
    final pnl = trade.profit ?? 0;
    final pnlColor = trade.isOpen
        ? AppColors.textMuted
        : (pnl >= 0 ? AppColors.success : AppColors.warning);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: trade.isOpen
              ? AppColors.accent.withValues(alpha: 0.3)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SideBadge(side: trade.side),
              const SizedBox(width: 8),
              Text(trade.symbol, style: AppTypography.h3.copyWith(fontSize: 14)),
              const SizedBox(width: 6),
              Text('${trade.volume} lot',
                  style: AppTypography.caption),
              const Spacer(),
              Text(
                trade.isOpen ? 'OPEN' : '${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(2)}',
                style: AppTypography.h3.copyWith(
                    color: pnlColor, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _kv('ENTRY', trade.openPrice.toStringAsFixed(5)),
              const SizedBox(width: 14),
              if (trade.closePrice != null)
                _kv('EXIT', trade.closePrice!.toStringAsFixed(5)),
              if (trade.stopLoss != null) ...[
                const SizedBox(width: 14),
                _kv('SL', trade.stopLoss!.toStringAsFixed(5)),
              ],
              if (trade.takeProfit != null) ...[
                const SizedBox(width: 14),
                _kv('TP', trade.takeProfit!.toStringAsFixed(5)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(trade.openTime) +
                (trade.closeTime != null
                    ? ' → ${_formatTime(trade.closeTime!)}'
                    : ''),
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: AppTypography.caption),
          Text(v,
              style: AppTypography.body
                  .copyWith(color: AppColors.textPrimary, fontSize: 12)),
        ],
      );

  String _formatTime(DateTime t) {
    final l = t.toLocal();
    final d = '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
    final h = '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    return '$d $h';
  }
}

class _SideBadge extends StatelessWidget {
  final BrokerTradeSide side;
  const _SideBadge({required this.side});

  @override
  Widget build(BuildContext context) {
    final buy = side == BrokerTradeSide.buy;
    final c = buy ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(side.label,
          style: AppTypography.chip.copyWith(color: c, fontSize: 9)),
    );
  }
}

// ── Connect Sheet ────────────────────────────────────────────────────────────

class _ConnectSheet extends StatefulWidget {
  final TradingViewModel vm;
  const _ConnectSheet({required this.vm});

  @override
  State<_ConnectSheet> createState() => _ConnectSheetState();
}

class _ConnectSheetState extends State<_ConnectSheet> {
  final nicknameCtrl = TextEditingController();
  final loginCtrl    = TextEditingController();
  final passwordCtrl = TextEditingController();
  final serverCtrl   = TextEditingController();
  final tokenCtrl    = TextEditingController();
  MtPlatform platform = MtPlatform.mt5;
  bool saving = false;

  @override
  void dispose() {
    nicknameCtrl.dispose();
    loginCtrl.dispose();
    passwordCtrl.dispose();
    serverCtrl.dispose();
    tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (loginCtrl.text.trim().isEmpty ||
        passwordCtrl.text.isEmpty ||
        serverCtrl.text.trim().isEmpty ||
        tokenCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() => saving = true);
    final cfg = TradingAccountConfig(
      provider:    AccountProvider.metaApi,
      platform:    platform,
      login:       loginCtrl.text.trim(),
      password:    passwordCtrl.text,
      server:      serverCtrl.text.trim(),
      accountId:   '', // will be filled after provisioning
      token:       tokenCtrl.text.trim(),
      nickname:    nicknameCtrl.text.trim().isEmpty
          ? null
          : nicknameCtrl.text.trim(),
      connectedAt: DateTime.now(),
    );
    await widget.vm.connectAccount(cfg);
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
            Center(
              child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('CONNECT TRADING ACCOUNT', style: AppTypography.label),
            const SizedBox(height: 6),
            Text(
              'Enter your MetaTrader credentials. The app bridges through '
              'metaapi.cloud for read-only access — no orders are placed.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 16),

            // Platform selector
            Text('PLATFORM',
                style: AppTypography.chip
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Row(
              children: MtPlatform.values.map((p) {
                final sel = p == platform;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => platform = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : AppColors.surfaceVar,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel ? AppColors.accent : AppColors.border,
                          width: 0.5,
                        ),
                      ),
                      child: Text(p.label,
                          style: AppTypography.chip.copyWith(
                              color: sel
                                  ? AppColors.accent
                                  : AppColors.textMuted)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            _field(nicknameCtrl, 'Nickname (optional)'),
            const SizedBox(height: 10),
            _field(loginCtrl, 'MT login number *',
                inputType: TextInputType.number),
            const SizedBox(height: 10),
            _field(passwordCtrl, 'MT investor password *', obscure: true),
            const SizedBox(height: 10),
            _field(serverCtrl, 'MT server (e.g. ICMarkets-Live20) *'),
            const SizedBox(height: 10),
            _field(tokenCtrl, 'MetaApi auth token *', obscure: true),
            const SizedBox(height: 6),
            Text(
              'Get the auth token from metaapi.cloud → Dashboard → Tokens',
              style: AppTypography.caption.copyWith(fontSize: 10),
            ),

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.background),
                      )
                    : Text('CONNECT',
                        style: AppTypography.h3.copyWith(
                            color: AppColors.background, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool obscure = false, TextInputType? inputType}) {
    return TextField(
      controller:   ctrl,
      obscureText:  obscure,
      keyboardType: inputType,
      style: AppTypography.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            AppTypography.caption.copyWith(color: AppColors.textMuted),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
