import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Uygulama genelindeki yuvarlak köşeli bildirim çubuğu.
void showAppSnack(
  BuildContext context,
  String message, {
  bool error = false,
  double bottom = 20,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: error ? AppColors.accent : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        margin: EdgeInsets.only(bottom: bottom, left: 20, right: 20),
      ),
    );
}
