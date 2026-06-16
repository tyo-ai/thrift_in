import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_colors.dart';

class SkeletonLoaders {
  SkeletonLoaders._();

  static Widget productGrid({
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16),
    int itemCount = 6,
    double childAspectRatio = 0.79,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    bool shrinkWrap = true,
  }) {
    return Skeletonizer(
      enabled: true,
      child: GridView.builder(
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (_, _) => _productCard(),
      ),
    );
  }

  static Widget list({
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    int itemCount = 5,
    double imageSize = 72,
  }) {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => _listTile(imageSize),
      ),
    );
  }

  static Widget notificationList() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => _listTile(46),
      ),
    );
  }

  static Widget _productCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 125,
            decoration: const BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(words: 2),
                SizedBox(height: 8),
                Bone.text(width: 82),
                SizedBox(height: 8),
                Bone.text(width: 110),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _listTile(double imageSize) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Bone.circle(size: imageSize),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(words: 3),
                SizedBox(height: 8),
                Bone.text(width: 130),
                SizedBox(height: 8),
                Bone.text(width: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
