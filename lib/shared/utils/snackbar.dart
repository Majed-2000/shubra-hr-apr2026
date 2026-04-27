import 'package:flutter/material.dart';

import '../../theme.dart';

/// Centralised snackbar helpers so every screen surfaces feedback in the
/// same shape. Each call is a no-op if [context] no longer has a Scaffold
/// (e.g. the screen has been popped).
class SnackbarHelpers {
  SnackbarHelpers._();

  static void show(BuildContext context, String message, {Color? color}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  static void showError(BuildContext context, String message) =>
      show(context, message, color: AppColors.danger);

  static void showSuccess(BuildContext context, String message) =>
      show(context, message, color: AppColors.success);

  static void showInfo(BuildContext context, String message) =>
      show(context, message);
}
