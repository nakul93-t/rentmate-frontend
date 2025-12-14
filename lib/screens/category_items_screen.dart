import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rentmate/constants.dart';
import 'package:rentmate/screens/home/home_screen.dart'; // using ItemWidget
import 'package:shared_preferences/shared_preferences.dart';

class CategoryItemsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryItemsScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  List<dynamic> items = [];
  List<dynamic> subCategories = [];
  String? selectedSubCategoryId;
  bool isLoadingItems = true;
  bool isLoadingSubCats = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('user_id');

    // Load subcategories and items in parallel
    await Future.wait([
      _loadSubCategories(),
      _loadItems(),
    ]);
  }

  Future<void> _loadSubCategories() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$kBaseUrl/sub-category/fetch-all?categoryId=${widget.categoryId}',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            subCategories = data['data'] ?? [];
            isLoadingSubCats = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoadingSubCats = false);
      }
    } catch (e) {
      print('Error loading subcategories: $e');
      if (mounted) setState(() => isLoadingSubCats = false);
    }
  }

  Future<void> _loadItems() async {
    if (mounted) setState(() => isLoadingItems = true);

    try {
      String url = '$kBaseUrl/item/fetch-all?categoryId=${widget.categoryId}';
      if (selectedSubCategoryId != null) {
        url += '&subCategoryId=$selectedSubCategoryId';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            items = data['items'] ?? [];
            isLoadingItems = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoadingItems = false);
      }
    } catch (e) {
      print('Error loading items: $e');
      if (mounted) setState(() => isLoadingItems = false);
    }
  }

  void _onSubCategorySelected(String? subCatId) {
    if (selectedSubCategoryId == subCatId) {
      // Deselect if already selected
      setState(() => selectedSubCategoryId = null);
    } else {
      setState(() => selectedSubCategoryId = subCatId);
    }
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Subcategories Horizontal List
          if (!isLoadingSubCats && subCategories.isNotEmpty)
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(vertical: 10),
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: subCategories.length + 1, // +1 for "All" option
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSelected = selectedSubCategoryId == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text('All'),
                        selected: isSelected,
                        onSelected: (_) => _onSubCategorySelected(null),
                        backgroundColor: Colors.grey[100],
                        selectedColor: Colors.black,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? Colors.black : Colors.grey[300]!,
                        ),
                      ),
                    );
                  }

                  final subCat = subCategories[index - 1];
                  final isSelected = selectedSubCategoryId == subCat['_id'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(subCat['subCategoryName'] ?? 'Unknown'),
                      selected: isSelected,
                      onSelected: (_) => _onSubCategorySelected(subCat['_id']),
                      backgroundColor: Colors.grey[100],
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? Colors.black : Colors.grey[300]!,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Items Grid
          Expanded(
            child: isLoadingItems
                ? Center(child: CircularProgressIndicator())
                : items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No items found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.70,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return ItemWidget(
                        item: items[index],
                        currentUserId: currentUserId,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
