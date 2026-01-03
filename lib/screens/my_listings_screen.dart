import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rentmate/constants.dart';
import 'package:rentmate/item_details_screen.dart';
import 'package:rentmate/screens/create_ad_screen.dart';

class MyListingsScreen extends StatefulWidget {
  final String currentUserId;

  const MyListingsScreen({Key? key, required this.currentUserId})
    : super(key: key);

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final String baseUrl = kBaseUrl;

  // Color scheme
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _darkSlate = Color(0xFF1E293B);
  static const Color _lightGrey = Color(0xFFF1F5F9);
  static const Color _mediumGrey = Color(0xFF64748B);

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/item/user/${widget.currentUserId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _items = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showMessage('Failed to load listings');
      }
    } catch (e) {
      print('Error fetching items: $e');
      setState(() => _isLoading = false);
      _showMessage('Network error');
    }
  }

  Future<void> _deleteItem(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Listing'),
        content: Text(
          'Are you sure you want to delete this listing? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/item/$itemId'),
      );

      if (response.statusCode == 200) {
        _showMessage('Listing deleted', isError: false);
        _fetchItems();
      } else {
        _showMessage('Failed to delete listing');
      }
    } catch (e) {
      _showMessage('Error deleting listing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: Text('My Listings'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchItems,
        color: _primaryBlue,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _primaryBlue))
            : _items.isEmpty
            ? _buildEmptyState()
            : _buildItemsList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CreateAdScreen(currentUserId: widget.currentUserId),
            ),
          );
          if (result == true) _fetchItems();
        },
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('New Listing'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 50,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No listings yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _darkSlate,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Post your first item to start earning!',
            style: TextStyle(
              fontSize: 14,
              color: _mediumGrey,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreateAdScreen(currentUserId: widget.currentUserId),
                ),
              );
              if (result == true) _fetchItems();
            },
            icon: Icon(Icons.add),
            label: Text('Create Listing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) => _buildItemCard(_items[index]),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final images = item['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty ? images[0] : null;
    final isActive = item['isActive'] ?? false;
    final itemName = item['itemName'] ?? 'Item';
    final basePrice = item['basePrice'] ?? 0;
    final priceUnit = item['priceUnit'] ?? 'day';

    String itemId;
    if (item['_id'] is String) {
      itemId = item['_id'];
    } else if (item['_id'] is Map && item['_id']['\$oid'] != null) {
      itemId = item['_id']['\$oid'];
    } else {
      itemId = item['_id']?.toString() ?? '';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(
                itemId: itemId,
                currentUserId: widget.currentUserId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Item image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              Icon(Icons.image, color: Colors.grey, size: 32),
                        ),
                      )
                    : Icon(Icons.image, color: Colors.grey, size: 32),
              ),
              SizedBox(width: 14),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _darkSlate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '₹$basePrice / $priceUnit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryBlue,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildStatusBadge(isActive),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: _mediumGrey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: _darkSlate),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'edit') {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateAdScreen(
                          currentUserId: widget.currentUserId,
                          itemId: itemId,
                        ),
                      ),
                    );
                    if (result == true) _fetchItems();
                  } else if (value == 'delete') {
                    _deleteItem(itemId);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}
