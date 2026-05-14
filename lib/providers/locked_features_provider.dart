// lib/providers/locked_features_provider.dart
//
// Derives the locked feature set directly from the live rule context.
// Any widget or router redirect that needs to know if a feature
// is locked reads from here — never from raw rule context directly.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feature/rules_engine/model/rich_feature.dart';
import 'rule_context_provider.dart';
import 'rule_engine_provider.dart';

/// The full set of currently locked features.
/// Updates reactively whenever the rule context changes.
final lockedFeaturesProvider = Provider<Set<RichFeature>>((ref) {
  final context = ref.watch(ruleContextProvider);
  final engine = ref.read(ruleEngineServiceProvider);
  // Preserve persisted escalation locks, then layer live rules on top.
  final fresh = context.copyWith(lockedFeatures: context.lockedFeatures);
  final results = engine.evaluate(fresh);
  final resolved = engine.applyResults(fresh, results);
  return resolved.lockedFeatures;
});

/// Check if a single feature is locked.
/// Usage: ref.watch(isFeatureLockedProvider(RichFeature.trading))
final isFeatureLockedProvider = Provider.family<bool, RichFeature>((
  ref,
  feature,
) {
  return ref.watch(lockedFeaturesProvider).contains(feature);
});

/// Human-readable lock reason for a feature.
/// Usage in the LockedScreen or any lock badge.
final lockReasonProvider = Provider.family<String, RichFeature>((ref, feature) {
  final engine = ref.read(ruleEngineServiceProvider);
  final context = ref.read(ruleContextProvider);
  return engine.lockReason(feature, context);
});

/// Unlock instruction for a feature.
final unlockInstructionProvider = Provider.family<String, RichFeature>((
  ref,
  feature,
) {
  final engine = ref.read(ruleEngineServiceProvider);
  final context = ref.read(ruleContextProvider);
  return engine.unlockInstruction(feature, context);
});
