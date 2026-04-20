// lib/providers/user_mode_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../feature/rules_engine/model/user_mode.dart';

class UserModeNotifier extends StateNotifier<UserMode> {
  UserModeNotifier() : super(UserMode.idle);

  void setMode(UserMode mode) => state = mode;

  void reset() => state = UserMode.idle;
}

final userModeProvider =
    StateNotifierProvider<UserModeNotifier, UserMode>(
  (ref) => UserModeNotifier(),
);
