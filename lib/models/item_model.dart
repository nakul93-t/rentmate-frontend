class ItemModel {
  final String id;
  final String itemName;
  final String description;
  final int basePrice;
  final String priceUnit;
  final List<String> images;
  final bool isActive;

  // Optional fields
  final CategoryInfo? category;
  final SubCategoryInfo? subCategory;

  ItemModel({
    required this.id,
    required this.itemName,
    required this.description,
    required this.basePrice,
    required this.priceUnit,
    required this.images,
    required this.isActive,
    this.category,
    this.subCategory,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    // Handle MongoDB ObjectId format
    String itemId;
    if (json['_id'] is String) {
      itemId = json['_id'];
    } else if (json['_id'] is Map && json['_id']['\$oid'] != null) {
      itemId = json['_id']['\$oid'];
    } else {
      itemId = json['_id'].toString();
    }

    return ItemModel(
      id: itemId,
      itemName: json['itemName'] ?? 'Unnamed Item',
      description: json['description'] ?? '',
      basePrice: json['basePrice'] ?? 0,
      priceUnit: json['priceUnit'] ?? 'day',
      images: List<String>.from(json['images'] ?? []),
      isActive: json['isActive'] ?? true,
      category: json['categoryId'] != null
          ? CategoryInfo.fromJson(json['categoryId'])
          : null,
      subCategory: json['subCategoryId'] != null
          ? SubCategoryInfo.fromJson(json['subCategoryId'])
          : null,
    );
  }

  String get firstImage => images.isNotEmpty ? images[0] : '';
  bool get hasImage => images.isNotEmpty;
}

class CategoryInfo {
  final String id;
  final String name;

  CategoryInfo({required this.id, required this.name});

  factory CategoryInfo.fromJson(dynamic json) {
    if (json is Map) {
      return CategoryInfo(
        id: json['_id']?.toString() ?? '',
        name: json['categoryName']?.toString() ?? '',
      );
    }
    return CategoryInfo(id: '', name: '');
  }
}

class SubCategoryInfo {
  final String id;
  final String name;

  SubCategoryInfo({required this.id, required this.name});

  factory SubCategoryInfo.fromJson(dynamic json) {
    if (json is Map) {
      return SubCategoryInfo(
        id: json['_id']?.toString() ?? '',
        name: json['subCategoryName']?.toString() ?? '',
      );
    }
    return SubCategoryInfo(id: '', name: '');
  }
}
