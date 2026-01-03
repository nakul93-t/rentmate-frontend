import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:rentmate/constants.dart';
import 'package:rentmate/screens/rental_details_screen.dart';

class MyRentalsScreen extends StatefulWidget {
  final String currentUserId;

  const MyRentalsScreen({Key? key, required this.currentUserId})
    : super(key: key);

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  final String baseUrl = kBaseUrl;

  // Color scheme
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _darkSlate = Color(0xFF1E293B);
  static const Color _lightGrey = Color(0xFFF1F5F9);
  static const Color _mediumGrey = Color(0xFF64748B);

  List<Map<String, dynamic>> _rentals = [];
  List<Map<String, dynamic>> _filteredRentals = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchRentals();
  }

  Future<void> _fetchRentals() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/rent-request/user/${widget.currentUserId}?role=customer',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _rentals = data.cast<Map<String, dynamic>>();
          _filteredRentals = _rentals;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showMessage('Failed to load rentals');
      }
    } catch (e) {
      print('Error fetching rentals: $e');
      setState(() => _isLoading = false);
      _showMessage('Network error');
    }
  }

  void _filterRentals(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredRentals = _rentals;
      } else {
        _filteredRentals = _rentals.where((rental) {
          final itemName =
              rental['itemId']?['itemName']?.toString().toLowerCase() ?? '';
          final status = rental['status']?.toString().toLowerCase() ?? '';
          return itemName.contains(query.toLowerCase()) ||
              status.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupByStatus() {
    final Map<String, List<Map<String, dynamic>>> grouped = {
      'active': [],
      'accepted': [],
      'pending': [],
      'returned': [],
      'completed': [],
      'cancelled': [],
      'rejected': [],
    };

    for (var rental in _filteredRentals) {
      final status = rental['status']?.toString().toLowerCase() ?? 'pending';
      if (grouped.containsKey(status)) {
        grouped[status]!.add(rental);
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: Text('My Rentals'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRentals,
        color: _primaryBlue,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _primaryBlue))
            : Column(
                children: [
                  // Search bar
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.white,
                    child: TextField(
                      onChanged: _filterRentals,
                      decoration: InputDecoration(
                        hintText: 'Search rentals...',
                        prefixIcon: Icon(Icons.search, color: _mediumGrey),
                        filled: true,
                        fillColor: _lightGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  // Rentals list
                  Expanded(
                    child: _filteredRentals.isEmpty
                        ? _buildEmptyState()
                        : _buildRentalsList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: _mediumGrey.withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No rentals yet' : 'No rentals found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _mediumGrey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Items you rent from others will appear here'
                : 'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: _mediumGrey.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRentalsList() {
    final grouped = _groupByStatus();

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        if (grouped['active']!.isNotEmpty) ...[
          _buildSectionHeader(
            'Active',
            grouped['active']!.length,
            Colors.green,
          ),
          ...grouped['active']!.map((rental) => _buildRentalCard(rental)),
          SizedBox(height: 16),
        ],
        if (grouped['accepted']!.isNotEmpty) ...[
          _buildSectionHeader(
            'Accepted',
            grouped['accepted']!.length,
            Colors.blue,
          ),
          ...grouped['accepted']!.map((rental) => _buildRentalCard(rental)),
          SizedBox(height: 16),
        ],
        if (grouped['pending']!.isNotEmpty) ...[
          _buildSectionHeader(
            'Pending',
            grouped['pending']!.length,
            Colors.orange,
          ),
          ...grouped['pending']!.map((rental) => _buildRentalCard(rental)),
          SizedBox(height: 16),
        ],
        if (grouped['returned']!.isNotEmpty) ...[
          _buildSectionHeader(
            'Returned',
            grouped['returned']!.length,
            Colors.purple,
          ),
          ...grouped['returned']!.map((rental) => _buildRentalCard(rental)),
          SizedBox(height: 16),
        ],
        if (grouped['completed']!.isNotEmpty) ...[
          _buildSectionHeader(
            'Completed',
            grouped['completed']!.length,
            Colors.teal,
          ),
          ...grouped['completed']!.map((rental) => _buildRentalCard(rental)),
          SizedBox(height: 16),
        ],
        if (grouped['cancelled']!.isNotEmpty) ...[
          _buildSectionHeader(
            'Cancelled',
            grouped['cancelled']!.length,
            Colors.grey,
          ),
          ...grouped['cancelled']!.map((rental) => _buildRentalCard(rental)),
          SizedBox(height: 16),
        ],
        if (grouped['rejected']!.isNotEmpty) ...[
          _buildSectionHeader(
            'Rejected',
            grouped['rejected']!.length,
            Colors.red,
          ),
          ...grouped['rejected']!.map((rental) => _buildRentalCard(rental)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _darkSlate,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(Map<String, dynamic> rental) {
    final item = rental['itemId'];
    final images = item?['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty ? images[0] : null;
    final itemName = item?['itemName'] ?? 'Item';
    final status = rental['status'] ?? 'pending';
    final startDate = rental['startDate'] != null
        ? DateTime.parse(rental['startDate'])
        : null;
    final endDate = rental['endDate'] != null
        ? DateTime.parse(rental['endDate'])
        : null;
    final totalAmount = rental['totalAmount'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RentalDetailsScreen(
                rentalId: rental['_id'],
                currentUserId: widget.currentUserId,
              ),
            ),
          ).then((_) => _fetchRentals());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Item image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                    : Icon(Icons.image, color: Colors.grey),
              ),
              SizedBox(width: 12),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _darkSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    if (startDate != null && endDate != null)
                      Text(
                        '${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _mediumGrey,
                        ),
                      ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        _buildStatusBadge(status),
                        Spacer(),
                        Text(
                          '₹$totalAmount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _primaryBlue,
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
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        label = 'Active';
        break;
      case 'accepted':
        color = Colors.blue;
        label = 'Accepted';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'returned':
        color = Colors.purple;
        label = 'Returned';
        break;
      case 'completed':
        color = Colors.teal;
        label = 'Completed';
        break;
      case 'cancelled':
        color = Colors.grey;
        label = 'Cancelled';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = _mediumGrey;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}
