import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../models/item_model.dart';
import '../../../theme/app_colors.dart';
import '../../../item_details_screen.dart';
import '../../../screens/login_screen.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final String? currentUserId;
  final double? rating;
  final int? reviewCount;

  const ItemCard({
    super.key,
    required this.item,
    required this.currentUserId,
    this.rating,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasReviews = reviewCount != null && reviewCount! > 0;

    return GestureDetector(
      onTap: () {
        if (currentUserId == null) {
          // User not logged in - navigate to login
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please log in to view item details'),
              action: SnackBarAction(
                label: 'Login',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
              ),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(
              itemId: item.id,
              currentUserId: currentUserId!,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  color: AppColors.backgroundLight,
                  child: item.hasImage
                      ? CachedNetworkImage(
                          imageUrl: item.firstImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryTeal,
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.textLight,
                              size: 40,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: AppColors.textLight,
                            size: 40,
                          ),
                        ),
                ),
              ),
            ),

            // Details Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title + Rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.itemName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasReviews) ...[
                          const SizedBox(width: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating!.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    // Location
                    if (item.hasLocation)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                item.displayLocation!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Price
                    Text(
                      '₹${item.basePrice}/${item.priceUnit}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
