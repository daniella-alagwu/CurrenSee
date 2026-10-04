import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textDark,
      content: Text(message, style: const TextStyle(color: AppColors.white)),
    ));
}