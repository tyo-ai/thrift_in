import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? photoPath;
  final double radius;

  const UserAvatar({
    super.key,
    required this.name,
    this.photoPath,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final image = _imageProvider();
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE8EEF4),
      backgroundImage: image,
      child: image == null
          ? Text(
              _initials,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: radius * 0.58,
              ),
            )
          : null,
    );
  }

  ImageProvider? _imageProvider() {
    final path = photoPath?.trim();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return CachedNetworkImageProvider(path);
    final file = File(path);
    if (file.existsSync()) return FileImage(file);
    return null;
  }

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'T';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
