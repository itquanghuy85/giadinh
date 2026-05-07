import 'package:flutter/material.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.success,
    required this.warning,
    required this.info,
    required this.subtleSurface,
  });

  final Color success;
  final Color warning;
  final Color info;
  final Color subtleSurface;

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? subtleSurface,
  }) {
    return AppThemeExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      subtleSurface: subtleSurface ?? this.subtleSurface,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }

    return AppThemeExtension(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
      subtleSurface: Color.lerp(subtleSurface, other.subtleSurface, t) ?? subtleSurface,
    );
  }
}
