import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/user.dart';

/// Profil fotoğrafı; yoksa adın baş harfleri.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 64});

  final AppUser user;
  final double size;

  String get _initials {
    final parts = user.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = user.avatar;
    if (avatar != null && avatar.startsWith('data:image')) {
      return ClipOval(
        child: Image.memory(
          base64Decode(avatar.substring(avatar.indexOf(',') + 1)),
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
