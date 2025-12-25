import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rentmate/constants.dart';
import 'package:rentmate/screens/category_items_screen.dart';

class CategoryList extends StatefulWidget {
  const CategoryList({super.key});

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  List<dynamic> categories = [];
  bool isLoading = true;

  // Minimal color palette for rent app
  static const Color _darkColor = Color(0xFF1E293B);

  // Category icons and colors (minimal, professional look)
  final Map<String, IconData> _categoryIcons = {
    'electronics': Icons.devices_outlined,
    'furniture': Icons.chair_outlined,
    'vehicles': Icons.directions_car_outlined,
    'tools': Icons.build_outlined,
    'sports': Icons.sports_basketball_outlined,
    'clothing': Icons.checkroom_outlined,
    'books': Icons.menu_book_outlined,
    'cameras': Icons.camera_alt_outlined,
    'music': Icons.music_note_outlined,
    'gaming': Icons.games_outlined,
    'home': Icons.home_outlined,
    'outdoor': Icons.park_outlined,
  };

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/category/fetch-all'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            categories = data['data'];
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching categories: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  IconData _getIconForCategory(String name) {
    final lowerName = name.toLowerCase();
    for (final key in _categoryIcons.keys) {
      if (lowerName.contains(key)) {
        return _categoryIcons[key]!;
      }
    }
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }

    if (categories.isEmpty) {
      return const SizedBox();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final category = categories[index];
        final name = category['categoryName'] ?? 'Unknown';
        final imageUrl = category['image'] ?? '';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryItemsScreen(
                  categoryId: category['_id'],
                  categoryName: name,
                ),
              ),
            );
          },
          child: SizedBox(
            width: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Icon Container
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              _getIconForCategory(name),
                              color: _darkColor,
                              size: 28,
                            ),
                          ),
                        )
                      : Icon(
                          _getIconForCategory(name),
                          color: _darkColor,
                          size: 28,
                        ),
                ),
                const SizedBox(height: 8),
                // Category Name
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _darkColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
