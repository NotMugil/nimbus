import 'package:flutter/material.dart';
import 'package:nimbus/theme/colors.dart';

class AppTextTheme {
  AppTextTheme._();

  static TextTheme build() {
    final TextTheme base = ThemeData.dark().textTheme;
    final TextTheme satoshi = base.apply(fontFamily: 'Satoshi');

    return satoshi.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
  }
}
