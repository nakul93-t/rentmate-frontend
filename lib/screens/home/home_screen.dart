import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rentmate/constants.dart';
import 'package:rentmate/item_details_screen.dart';
import 'package:rentmate/screens/home/widgets/category_list.dart';
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

  // Color scheme
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _darkSlate = Color(0xFF1E293B);
  static const Color _lightGrey = Color(0xFFF1F5F9);
  static const Color _mediumGrey = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
      // Load all items when search is cleared
      _loadItems(showLoading: false);
      return;
    }

    // Call backend API with search parameter
    _searchItems(query);
  }

  Future<void> _searchItems(String query) async {
    setState(() => isLoadingItems = true);
    try {
      final response = await http.get(
        Uri.parse(
          '$kBaseUrl/item/fetch-all?search=${Uri.encodeComponent(query)}',
        ),
      );
      if (response.statusCode == 200) {
        final formatted = json.decode(response.body);
        if (mounted) {
          setState(() {
            filteredItems = formatted['items'] ?? [];
            isLoadingItems = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoadingItems = false);
      }
    } catch (e) {
      print('Error searching items: $e');
      if (mounted) setState(() => isLoadingItems = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      body: RefreshIndicator(
        onRefresh: () => _loadItems(showLoading: false),
        color: _primaryBlue,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              floating: true,
              titleSpacing: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: 70,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/app logo.png',
                      width: 90,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    // Location Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _primaryBlue.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: _primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Azhikode',
                            style: TextStyle(
                              color: _darkSlate,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Notification
                    Container(
                      decoration: BoxDecoration(
                        color: _lightGrey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: _darkSlate,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NotificationScreen(),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    color: _lightGrey,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterItems,
                    style: TextStyle(color: _darkSlate, fontSize: 15),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: _primaryBlue),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: _mediumGrey),
                              onPressed: () {
                                _searchController.clear();
                                _filterItems('');
                              },
                            )
                          : null,
                      hintText: "Search items, categories...",
                      hintStyle: TextStyle(
                        color: _mediumGrey.withOpacity(0.7),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Hero Banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _darkSlate,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rent Anything',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Save money, reduce waste',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'List an Item',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.handshake_outlined,
                      color: Colors.white24,
                      size: 64,
                    ),
                  ],
                ),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8,
                      ),
                      child: Text(
                        "Categories",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkSlate,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 105, child: CategoryList()),
                  ],
                ),
              ),
            ),

            // Nearby Items Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Nearby Items",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _darkSlate,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: _primaryBlue,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text(
                        'See all',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: isLoadingItems
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: _primaryBlue),
                        ),
                      ),
                    )
                  : filteredItems.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: _mediumGrey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No items found",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _darkSlate,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Try a different search term",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _mediumGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ItemCard(
                            item: filteredItems[index],
                            currentUserId: storedUserId,
                          );
                        },
                        childCount: filteredItems.length,
                      ),
                    ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// Premium Item Card
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.currentUserId,
  });

  final Map<String, dynamic> item;
  final String? currentUserId;

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _darkSlate = Color(0xFF1E293B);
  static const Color _mediumGrey = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final isAvailable = item['isActive'] ?? true;
    final createdBy = item['createdBy'];
    final ownerName = createdBy is Map ? (createdBy['name'] ?? 'User') : 'User';

    // Handle itemId - could be String or Map with $oid
    String itemId;
    if (item['_id'] is String) {
      itemId = item['_id'];
    } else if (item['_id'] is Map && item['_id']['\$oid'] != null) {
      itemId = item['_id']['\$oid'];
    } else {
      itemId = item['_id'].toString();
    }

    return GestureDetector(
      onTap: () {
        if (currentUserId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(
                itemId: itemId,
                currentUserId: currentUserId!,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryBlue.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Main Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                      ),
                      child: Image.network(
                        item['images'] != null && item['images'].isNotEmpty
                            ? item['images'][0]
                            : 'https://via.placeholder.com/150',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.grey.shade300,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Top badges row
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? _darkSlate
                                : Colors.red.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAvailable ? '● Available' : '● Rented',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        // Favorite button
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.favorite_border_rounded,
                            size: 18,
                            color: _darkSlate,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price overlay at bottom of image
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            item['basePrice'] != null
                                ? '₹${item['basePrice']}'
                                : '₹--',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '/day',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      item['itemName'] ?? 'Unnamed Item',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _darkSlate,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Owner + Rating row
                    Row(
                      children: [
                        // Owner avatar
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _primaryBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              ownerName[0].toUpperCase(),
                              style: TextStyle(
                                color: _primaryBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ownerName,
                            style: TextStyle(
                              fontSize: 11,
                              color: _mediumGrey,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Rating
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.amber.shade600,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '4.8',
                          style: TextStyle(
                            fontSize: 11,
                            color: _darkSlate,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
