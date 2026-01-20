import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rentmate/constants.dart';
import 'package:rentmate/item_details_screen.dart';
import 'package:rentmate/screens/home/widgets/category_list.dart';
import 'package:rentmate/screens/notifications/notification_screen.dart';
import 'package:rentmate/theme/app_colors.dart';
import 'package:rentmate/widgets/ui_components.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentmate/services/location_service.dart';

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

  String _location = 'Azhikode';
  final LocationService _locationService = LocationService();

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

  Future<void> _loadStoredLocation() async {
    final saved = await _locationService.getSavedLocation();
    if (saved != null && mounted) {
      setState(() => _location = saved);
    }
  }

  Future<void> _getCurrentLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fetching location...')),
    );

    final pos = await _locationService.getCurrentPosition();
    if (pos != null) {
      final place = await _locationService.getPlaceName(
        pos.latitude,
        pos.longitude,
      );
      if (place != null && mounted) {
        await _locationService.saveLocation(place);
        setState(() => _location = place);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location updated to $place')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location. Check permissions.')),
        );
      }
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Location',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.my_location, color: AppColors.primaryTeal),
              title: Text('Use Current Location'),
              onTap: () {
                Navigator.pop(context);
                _getCurrentLocation();
              },
            ),
            ListTile(
              leading: Icon(Icons.search, color: Colors.grey),
              title: Text('Enter Manually'),
              onTap: () {
                Navigator.pop(context);
                _showManualLocationDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showManualLocationDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Location'),
        backgroundColor: Colors.white,
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'City, Area, etc.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _locationService.saveLocation(controller.text);
                setState(() => _location = controller.text);
                Navigator.pop(context);
              }
            },
            child: Text('Save', style: TextStyle(color: AppColors.primaryTeal)),
          ),
        ],
      ),
    );
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    storedUserId = prefs.getString('user_id');
    _loadItems();
    _loadStoredLocation();
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
      _loadItems(showLoading: false);
      return;
    }
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
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => _loadItems(showLoading: false),
        color: AppColors.primaryTeal,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar with glass effect
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              floating: true,
              titleSpacing: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: 70,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
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
                    // Location Pill with teal
                    GestureDetector(
                      onTap: _showLocationPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryTeal.withOpacity(0.1),
                              AppColors.primaryTealLight.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryTeal.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: AppColors.primaryTeal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _location,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Notification with glass effect
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar with pill style
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: PillSearchBar(
                  controller: _searchController,
                  onChanged: _filterItems,
                  hintText: 'Search items, categories...',
                  onClear: () {
                    _searchController.clear();
                    _filterItems('');
                  },
                ),
              ),
            ),

            // Categories Section
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 50, child: CategoryList()),
                  ],
                ),
              ),
            ),

            // Featured Banner Card with Image
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image
                      Image.network(
                        'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=800',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primaryTeal.withOpacity(0.3),
                          child: Icon(
                            Icons.store_outlined,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Title
                            Text(
                              'Rent Anything, Anytime',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Location Row
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Azhikode, Kannur',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                // Rating
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '4.6 (121)',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Wishlist Button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.favorite_border_rounded,
                            color: AppColors.textPrimary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Nearby Items Title with See All
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Nearby Items",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "See All",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryTeal,
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
                          child: CircularProgressIndicator(
                            color: AppColors.primaryTeal,
                          ),
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
                                color: AppColors.textLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No items found",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Try a different search term",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
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

// Premium Item Card with enhanced styling
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.currentUserId,
  });

  final Map<String, dynamic> item;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final isAvailable = item['isActive'] ?? true;

    // Handle itemId - could be String or Map with $oid
    String itemId;
    if (item['_id'] is String) {
      itemId = item['_id'];
    } else if (item['_id'] is Map && item['_id']['\$oid'] != null) {
      itemId = item['_id']['\$oid'];
    } else {
      itemId = item['_id'].toString();
    }

    final basePrice = item['basePrice'] ?? 0;
    final discountedPrice = (basePrice * 0.8)
        .round(); // 20% discount for display

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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Main Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      color: AppColors.backgroundLight,
                      child: Image.network(
                        item['images'] != null && item['images'].isNotEmpty
                            ? item['images'][0]
                            : 'https://via.placeholder.com/150',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: AppColors.textLight,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Discount Badge
                  if (isAvailable)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-20%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
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
                    // Title + Rating Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item['itemName'] ?? 'Unnamed Item',
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
                        const SizedBox(width: 4),
                        // Rating
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '4.7',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Price Row
                    Row(
                      children: [
                        // Original Price (strikethrough)
                        Text(
                          '₹$basePrice',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Discounted Price
                        Text(
                          '₹$discountedPrice',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTeal,
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
