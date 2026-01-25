class ReviewModel {
  final String id;
  final String userId;
  final String itemId;
  final String? description;
  final int rating;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.itemId,
    this.description,
    required this.rating,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Handle MongoDB ObjectId for itemId
    String itemId;
    if (json['itemId'] is String) {
      itemId = json['itemId'];
    } else if (json['itemId'] is Map && json['itemId']['\$oid'] != null) {
      itemId = json['itemId']['\$oid'];
    } else {
      itemId = json['itemId'].toString();
    }

    return ReviewModel(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      itemId: itemId,
      description: json['description'],
      rating: json['rating'] ?? 0,
    );
  }
}
