import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'cached_product_image.dart';

class ProductCard extends StatefulWidget {
  final int? id;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String name;
  final String storeName;
  final String location;
  final String price;
  final bool isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;

  const ProductCard({
    super.key,
    this.id,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.name,
    required this.storeName,
    required this.location,
    required this.price,
    this.isFavorite = false,
    this.onFavoriteChanged,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with favorite button
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CachedProductImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 420,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _isFavorite = !_isFavorite);
                    if (widget.onFavoriteChanged != null) {
                      widget.onFavoriteChanged!(_isFavorite);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: _isFavorite ? AppColors.error : AppColors.grey500,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.ratingStar),
                    const SizedBox(width: 3),
                    Text(
                      widget.rating.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '(${widget.reviewCount})',
                      style: TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Product name
                Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Store + location
                Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 12,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${widget.storeName} - ${widget.location}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Price
                Text(
                  widget.price,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
