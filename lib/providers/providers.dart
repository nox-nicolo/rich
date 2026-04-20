// lib/providers/providers.dart
//
// Master barrel — import this single file anywhere in the app
// to access all providers.
//
// Usage:
//   import 'package:rich/providers/providers.dart';
//
// Then use any provider:
//   ref.watch(ruleContextProvider)
//   ref.watch(isFeatureLockedProvider(RichFeature.trading))
//   ref.watch(latestNewsProvider)
//   etc.

// ── Rule Engine ───────────────────────────────────────────────────────────────
export 'rule_context_provider.dart';
export 'rule_engine_provider.dart';

// ── Features ──────────────────────────────────────────────────────────────────
export 'locked_features_provider.dart';
export 'user_mode_provider.dart';
export 'news_provider.dart';
export 'dashboard_provider.dart';
export 'overlay_provider.dart';

// ── Re-exports for convenience ────────────────────────────────────────────────
// These are the most commonly used types — exported here so callers
// only need one import instead of reaching into feature folders.

export '../feature/rules_engine/model/rich_feature.dart';
export '../feature/rules_engine/model/user_mode.dart';
export '../feature/rules_engine/model/rule_context.dart';
export '../feature/rules_engine/model/rule_result.dart';
export '../feature/rules_engine/service/rule_engine_service.dart';

export '../feature/trading/model/news_event.dart';

export '../feature/dashboard/model/dashboard_state_model.dart';
export '../feature/overlay/model/overlay_state_model.dart';
