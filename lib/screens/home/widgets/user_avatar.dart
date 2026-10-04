import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.avatar,
    this.radius = 22,
    this.background = AppColors.emeraldGlow,
  });

  final String? avatar;
  final double radius;
  final Color background;

  static final Map<String, MemoryImage> _cache = {};

  ImageProvider? _image() {
    final a = avatar;
    if (a == null || a.isEmpty) return null;
    final cached = _cache[a];
    if (cached != null) return cached;
    try {
      final img = MemoryImage(base64Decode(a.contains(',') ? a.split(',').last : a));
      if (_cache.length > 4) _cache.clear();
      return _cache[a] = img;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _image();
    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      backgroundImage: img,
      child: img != null
          ? null
          : Icon(Icons.person_rounded, color: AppColors.white, size: radius * 1.1),
    );
  }
}