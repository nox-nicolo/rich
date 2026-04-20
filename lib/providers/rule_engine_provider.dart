// lib/providers/rule_engine_provider.dart
//
// Wires the RuleEngineService to the live RuleContext.
// activeRuleResultsProvider re-evaluates automatically
// whenever RuleContext changes anywhere in the app.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feature/rules_engine/service/rule_engine_service.dart';
import '../feature/rules_engine/model/rule_result.dart';
import 'rule_context_provider.dart';

/// Singleton rule engine service.
/// Stateless — safe to share across the whole app.
final ruleEngineServiceProvider = Provider<RuleEngineService>(
  (_) => RuleEngineService(),
);

/// Derived provider — re-runs every time ruleContext changes.
/// Returns only triggered rule results.
final activeRuleResultsProvider = Provider<List<RuleResult>>(
  (ref) {
    final engine = ref.read(ruleEngineServiceProvider);
    final context = ref.watch(ruleContextProvider);
    return engine.evaluate(context);
  },
);

/// Derived provider — applies all triggered results back to
/// context and returns the mutated context.
/// Use this if you want the fully resolved context after rules run.
final resolvedContextProvider = Provider(
  (ref) {
    final engine = ref.read(ruleEngineServiceProvider);
    final context = ref.watch(ruleContextProvider);
    final results = engine.evaluate(context);
    return engine.applyResults(context, results);
  },
);
