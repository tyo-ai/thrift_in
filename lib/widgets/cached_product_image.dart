import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CachedProductImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const CachedProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl.trim();
    final child = trimmedUrl.startsWith('http')
        ? CachedNetworkImage(
            imageUrl: trimmedUrl,
            fit: fit,
            width: width,
            height: height,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            fadeInDuration: const Duration(milliseconds: 120),
            placeholder: (_, _) => _placeholder(),
            errorWidget: (_, _, _) => _placeholder(),
          )
        : Image.file(
            File(trimmedUrl),
            fit: fit,
            width: width,
            height: height,
            cacheWidth: memCacheWidth,
            cacheHeight: memCacheHeight,
            errorBuilder: (_, _, _) => _placeholder(),
          );

    if (borderRadius == null) return child;

    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.grey100,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, size: 34, color: AppColors.grey300),
    );
  }
}
