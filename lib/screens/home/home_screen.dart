import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rentmate/constants.dart';
import 'package:rentmate/item_details_screen.dart';
import 'package:rentmate/screens/home/widgets/category_list.dart';
import 'package:rentmate/screens/home/widgets/favorite_button.dart';
import 'package:rentmate/screens/notifications/notification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? storedUserId;
  List<dynamic> items = [];
  List<dynamic> filteredItems = [];
  bool isLoadingItems = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    storedUserId = prefs.getString('user_id');
    _loadItems();
  }

  Future<void> _loadItems({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => isLoadingItems = true);
    }
    try {
      final response = await http.get(Uri.parse('$kBaseUrl/item/fetch-all'));
      if (response.statusCode == 200) {
        final formatted = json.decode(response.body);
        if (mounted) {
          setState(() {
            items = formatted['items'];
            filteredItems = items;
            if (_searchController.text.isNotEmpty) {
              _filterItems(_searchController.text);
            }
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

  void _filterItems(String query) {
    if (query.isEmpty) {
      setState(() => filteredItems = items);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredItems = items.where((item) {
        final name = item['itemName']?.toString().toLowerCase() ?? '';

        String categoryName = '';
        final category = item['category'];
        if (category is Map) {
          categoryName =
              category['name']?.toString().toLowerCase() ??
              category['categoryName']?.toString().toLowerCase() ??
              '';
        } else if (category is String) {
          categoryName = category.toLowerCase();
        }

        return name.contains(lowerQuery) || categoryName.contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () => _loadItems(showLoading: false),
        color: Colors.indigo,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Custom App Bar Area
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              floating: true,
              titleSpacing: 0, // Reduces default left padding
              automaticallyImplyLeading: false,
              toolbarHeight: 70,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    // Logo with reduced margin as requested
                    Image.asset(
                      'assets/images/app logo.png',
                      width: 90,
                      fit: BoxFit.contain,
                    ),
                    Spacer(),
                    // Location Pill
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.indigo,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Azhikode',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    // Notification Icon
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[100],
                      child: IconButton(
                        icon: Icon(
                          Icons.notifications_none,
                          color: Colors.black87,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterItems,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.indigo),
                      hintText: "What are you looking for?",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Categories Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8,
                      ),
                      child: Text(
                        "Explore Categories",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      height: 105,
                      child: CategoryList(),
                    ),
                  ],
                ),
              ),
            ),

            // Recommendation Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recommended for you",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Grid
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: isLoadingItems
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  : filteredItems.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Text(
                            "No items found",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    )
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.70, // Adjust for card height
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ItemWidget(
                            item: filteredItems[index],
                            currentUserId: storedUserId,
                          );
                        },
                        childCount: filteredItems.length,
                      ),
                    ),
            ),

            // Bottom Padding
            SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class ItemWidget extends StatelessWidget {
  const ItemWidget({
    super.key,
    required this.item,
    required this.currentUserId,
  });

  final Map<String, dynamic> item;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ItemDetailScreen(
              itemId: item['_id'],
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            SizedBox(
              height: 140,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: Image.network(
                        item['images'] != null && item['images'].isNotEmpty
                            ? item['images'][0]
                            : 'https://via.placeholder.com/150',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, // Semi-transparent white
                        shape: BoxShape.circle,
                      ),
                      child: FavoriteButton(),
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['itemName'] ?? 'Unnamed Item',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        item['basePrice'] != null
                            ? '₹${item['basePrice']}'
                            : '₹--',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.indigo,
                        ),
                      ),
                      Text(
                        ' / day',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
