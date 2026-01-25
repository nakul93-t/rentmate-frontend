import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../constants.dart';
import '../../../models/review_model.dart';

class ReviewProvider extends ChangeNotifier {
  // State
  Map<String, double> _itemRatings = {};
  Map<String, int> _itemReviewCounts = {};
  bool _isLoading = false;

  // Getters
  bool get isLoading => _isLoading;

  double? getRating(String itemId) => _itemRatings[itemId];
  int? getReviewCount(String itemId) => _itemReviewCounts[itemId];

  bool hasReviews(String itemId) =>
      _itemRatings.containsKey(itemId) && _itemReviewCounts[itemId]! > 0;

  double get overallRating {
    if (_itemRatings.isEmpty) return 0;
    final total = _itemRatings.values.reduce((a, b) => a + b);
    return total / _itemRatings.length;
  }

  int get totalReviews {
    return _itemReviewCounts.values.fold(0, (sum, count) => sum + count);
  }

  // Load all reviews
  Future<void> loadReviews() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/review/fetch-all'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final reviewsJson = data['data'] as List;

        final reviews = reviewsJson
            .map((json) => ReviewModel.fromJson(json))
            .toList();

        _calculateRatings(reviews);
      }
    } catch (e) {
      print('Error loading reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate average ratings per item
  void _calculateRatings(List<ReviewModel> reviews) {
    final Map<String, List<int>> reviewsByItem = {};

    for (var review in reviews) {
      if (!reviewsByItem.containsKey(review.itemId)) {
        reviewsByItem[review.itemId] = [];
      }
      reviewsByItem[review.itemId]!.add(review.rating);
    }

    _itemRatings.clear();
    _itemReviewCounts.clear();

    reviewsByItem.forEach((itemId, ratings) {
      final avg = ratings.reduce((a, b) => a + b) / ratings.length;
      _itemRatings[itemId] = avg;
      _itemReviewCounts[itemId] = ratings.length;
    });
  }
}
