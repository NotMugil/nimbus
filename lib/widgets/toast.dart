import 'package:flutter/material.dart';

class AppToast {
  AppToast._();

  static const Color _background = Color(0xFFF2D6DE);
  static const Color _textColor = Color(0xFF2A1A21);

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _background,
        elevation: 0,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _textColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
