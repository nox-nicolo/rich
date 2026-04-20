import 'dart:convert';

/// Controls how the app lock behaves.
/// NOTE:
/// - PIN itself is NOT stored here (store it securely)
/// - This only stores settings/flags
class AppLockSettings {
  final bool isEnabled;
  final bool biometricsEnabled;
  final bool lockOnBackground;
  final int autoLockMinutes;
  final bool pinSet;
  final DateTime updatedAt;

  const AppLockSettings({
    required this.isEnabled,
    required this.biometricsEnabled,
    required this.lockOnBackground,
    required this.autoLockMinutes,
    required this.pinSet,
    required this.updatedAt,
  });

  /// Default state (no lock enabled)
  factory AppLockSettings.initial() {
    return AppLockSettings(
      isEnabled: false,
      biometricsEnabled: false,
      lockOnBackground: true,
      autoLockMinutes: 0, // 0 = immediate lock
      pinSet: false,
      updatedAt: DateTime.now(),
    );
  }

  AppLockSettings copyWith({
    bool? isEnabled,
    bool? biometricsEnabled,
    bool? lockOnBackground,
    int? autoLockMinutes,
    bool? pinSet,
    DateTime? updatedAt,
  }) {
    return AppLockSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      lockOnBackground: lockOnBackground ?? this.lockOnBackground,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      pinSet: pinSet ?? this.pinSet,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Helper getters

  bool get shouldLockImmediately =>
      lockOnBackground && autoLockMinutes == 0;

  bool get hasSecurity =>
      isEnabled && pinSet;

  /// Convert to Map (for Hive)

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'biometricsEnabled': biometricsEnabled,
      'lockOnBackground': lockOnBackground,
      'autoLockMinutes': autoLockMinutes,
      'pinSet': pinSet,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppLockSettings.fromMap(Map<String, dynamic> map) {
    return AppLockSettings(
      isEnabled: map['isEnabled'] ?? false,
      biometricsEnabled: map['biometricsEnabled'] ?? false,
      lockOnBackground: map['lockOnBackground'] ?? true,
      autoLockMinutes: map['autoLockMinutes'] ?? 0,
      pinSet: map['pinSet'] ?? false,
      updatedAt:
          DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// JSON helpers

  String toJson() => jsonEncode(toMap());

  factory AppLockSettings.fromJson(String source) =>
      AppLockSettings.fromMap(jsonDecode(source));

  @override
  String toString() {
    return '''
AppLockSettings(
  isEnabled: $isEnabled,
  biometricsEnabled: $biometricsEnabled,
  lockOnBackground: $lockOnBackground,
  autoLockMinutes: $autoLockMinutes,
  pinSet: $pinSet,
  updatedAt: $updatedAt
)
''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppLockSettings &&
        other.isEnabled == isEnabled &&
        other.biometricsEnabled == biometricsEnabled &&
        other.lockOnBackground == lockOnBackground &&
        other.autoLockMinutes == autoLockMinutes &&
        other.pinSet == pinSet;
  }

  @override
  int get hashCode {
    return isEnabled.hashCode ^
        biometricsEnabled.hashCode ^
        lockOnBackground.hashCode ^
        autoLockMinutes.hashCode ^
        pinSet.hashCode;
  }
}