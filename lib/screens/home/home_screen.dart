import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentmate/services/location_service.dart';
import 'package:rentmate/theme/app_colors.dart';
import 'package:rentmate/widgets/ui_components.dart';
import 'package:rentmate/screens/home/widgets/category_list.dart';
import 'package:rentmate/screens/home/providers/home_provider.dart';
import 'package:rentmate/screens/home/providers/review_provider.dart';
import 'package:rentmate/screens/home/widgets/item_card.dart';
import 'package:rentmate/screens/home/widgets/featured_banner.dart';
import 'package:rentmate/screens/home/widgets/home_app_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rentmate/constants.dart';
import 'package:intl/intl.dart';
import 'package:rentmate/screens/my_listings_rentals_screen.dart';
import 'package:rentmate/screens/rental_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? currentUserId;
  final int unreadNotificationCount;
  final VoidCallback? onNotificationViewed;

  const HomeScreen({
    super.key,
    this.currentUserId,
    this.unreadNotificationCount = 0,
    this.onNotificationViewed,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? storedUserId;
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  String _location = 'Azhikode';
  List<Map<String, dynamic>> _incomingRequests = [];
  bool _isLoadingRequests = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    storedUserId = prefs.getString('user_id');

    // Load data using providers
    if (mounted) {
      await Future.wait([
        context.read<HomeProvider>().loadItems(),
        context.read<ReviewProvider>().loadReviews(),
      ]);
    }

    final savedLocation = await _locationService.getSavedLocation();
    if (savedLocation != null && mounted) {
      setState(() => _location = savedLocation);
    }

    // Fetch incoming requests
    if (storedUserId != null) {
      _fetchIncomingRequests(storedUserId!);
    }
  }

  Future<void> _fetchIncomingRequests(String userId) async {
    setState(() => _isLoadingRequests = true);
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/rent-request/user/$userId?role=renter'),
      );
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _incomingRequests = data
              .where(
                (r) => r['status'] == 'pending' || r['status'] == 'inquiry',
              )
              .take(10)
              .toList()
              .cast<Map<String, dynamic>>();
          _isLoadingRequests = false;
        });
      }
    } catch (e) {
      print('Error fetching requests: $e');
      if (mounted) setState(() => _isLoadingRequests = false);
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
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<HomeProvider>().refreshItems(),
            context.read<ReviewProvider>().loadReviews(),
            if (storedUserId != null) _fetchIncomingRequests(storedUserId!),
          ]);
        },
        color: AppColors.primaryTeal,
        child: CustomScrollView(
          slivers: [
            // App Bar with glass effect
            HomeAppBar(
              location: _location,
              onLocationTap: _showLocationPicker,
              unreadNotificationCount: widget.unreadNotificationCount,
              currentUserId: widget.currentUserId ?? storedUserId ?? '',
              onNotificationViewed: widget.onNotificationViewed,
            ),

            // Search Bar with pill style
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: PillSearchBar(
                  controller: _searchController,
                  onChanged: (query) {
                    context.read<HomeProvider>().searchItems(query);
                  },
                  hintText: 'Search items, categories...',
                  onClear: () {
                    _searchController.clear();
                    context.read<HomeProvider>().clearSearch();
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
              child: Consumer<ReviewProvider>(
                builder: (context, reviewProvider, _) {
                  return FeaturedBanner(
                    location: _location,
                    overallRating: reviewProvider.overallRating,
                    totalReviews: reviewProvider.totalReviews,
                  );
                },
              ),
            ),

            // Incoming Requests Section
            if (_isLoadingRequests)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              )
            else if (_incomingRequests.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Incoming Requests",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MyListingsRentalsScreen(
                                currentUserId:
                                    widget.currentUserId ?? storedUserId ?? '',
                              ),
                            ),
                          ).then((_) {
                            if (storedUserId != null)
                              _fetchIncomingRequests(storedUserId!);
                          });
                        },
                        child: Text(
                          "See All",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 100,
                  margin: EdgeInsets.only(bottom: 24),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _incomingRequests.length,
                    itemBuilder: (context, index) {
                      final req = _incomingRequests[index];
                      return _buildRequestCard(req);
                    },
                  ),
                ),
              ),
            ],

            // Update main home screen to use providers and extracted widgets
            // Empty State with Action
            SliverToBoxAdapter(
              child: Consumer<HomeProvider>(
                builder: (context, homeProvider, _) {
                  if (homeProvider.errorMessage != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Failed to load items",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              homeProvider.errorMessage!,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => homeProvider.refreshItems(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(Icons.refresh, color: Colors.white),
                              label: Text(
                                'Retry',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
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
                    GestureDetector(
                      onTap: () {
                        // Clear any filters and show all items
                        _searchController.clear();
                        context.read<HomeProvider>().clearSearch();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Showing all items'),
                            duration: Duration(milliseconds: 1500),
                          ),
                        );
                      },
                      child: Text(
                        "See All",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Grid
            Consumer2<HomeProvider, ReviewProvider>(
              builder: (context, homeProvider, reviewProvider, _) {
                if (homeProvider.isLoading) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                  );
                }

                if (!homeProvider.hasItems) {
                  return SliverToBoxAdapter(
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
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = homeProvider.items[index];
                        return ItemCard(
                          item: item,
                          currentUserId: storedUserId,
                          rating: reviewProvider.getRating(item.id),
                          reviewCount: reviewProvider.getReviewCount(item.id),
                        );
                      },
                      childCount: homeProvider.items.length,
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final item = req['itemId'];
    final customer = req['customerId'];
    final itemName = item?['itemName'] ?? 'Item';
    final customerName = customer?['name'] ?? 'Customer';
    final images = item?['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty ? images[0] : null;
    final status = req['status'] ?? 'pending';
    final date = req['requestedDate'] != null
        ? DateFormat('dd MMM').format(DateTime.parse(req['requestedDate']))
        : '';

    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RentalDetailsScreen(
                  rentalId: req['_id'],
                  currentUserId: widget.currentUserId ?? storedUserId ?? '',
                ),
              ),
            ).then((_) {
              if (storedUserId != null) _fetchIncomingRequests(storedUserId!);
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[100],
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                Icon(Icons.image, color: Colors.grey),
                          )
                        : Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customerName,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'pending'
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: status == 'pending'
                                    ? Colors.orange
                                    : Colors.blue,
                              ),
                            ),
                          ),
                          Spacer(),
                          if (date.isNotEmpty)
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textLight,
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
        ),
      ),
    );
  }
}
