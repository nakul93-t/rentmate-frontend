import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:rentmate/constants.dart';
import 'package:rentmate/screens/chats/chat_screen.dart';
import 'package:rentmate/item_details_screen.dart';

class MyRentingScreen extends StatefulWidget {
  final String currentUserId;

  const MyRentingScreen({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<MyRentingScreen> createState() => _MyRentingScreenState();
}

class _MyRentingScreenState extends State<MyRentingScreen> {
  final String baseUrl = kBaseUrl;
  List<dynamic> itemsImRenting = [];
  bool isLoading = true;

  // Color scheme
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _darkSlate = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _loadMyRentals();
  }

  Future<void> _loadMyRentals() async {
    setState(() => isLoading = true);
    try {
      // Get items I'm renting (as customer)
      final response = await http.get(
        Uri.parse(
          '$baseUrl/rent-request/user/${widget.currentUserId}?role=customer',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          itemsImRenting = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading rentals: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: _darkSlate,
        foregroundColor: Colors.white,
        title: Text('My Renting'),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryBlue))
          : itemsImRenting.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadMyRentals,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: itemsImRenting.length,
                itemBuilder: (context, index) {
                  return _buildRentalCard(itemsImRenting[index]);
                },
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
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'No active rentals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Items you rent will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(Map<String, dynamic> request) {
    if (request['itemId'] == null) return SizedBox();

    final item = request['itemId'];
    final owner = request['renterId'];
    final status = request['status'];

    if (owner == null) return SizedBox();

    final String? itemImage =
        item['images'] != null && item['images'].isNotEmpty
        ? item['images'][0]
        : null;

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
      child: Column(
        children: [
          // Item Info Row
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Item Image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: itemImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            itemImage,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Icon(
                              Icons.image,
                              color: Colors.grey[400],
                            ),
                          ),
                        )
                      : Icon(Icons.image, color: Colors.grey[400]),
                ),
                SizedBox(width: 12),
                // Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['itemName'] ?? 'Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _darkSlate,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'From: ${owner['name'] ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (request['startDate'] != null) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${_formatDate(request['startDate'])} - ${_formatDate(request['endDate'])}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${request['totalAmount'] ?? 0}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryBlue,
                      ),
                    ),
                    SizedBox(height: 4),
                    _buildStatusChip(status),
                  ],
                ),
              ],
            ),
          ),
          // Action Buttons
          Container(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to item details
                      String itemId = '';
                      if (item['_id'] is String) {
                        itemId = item['_id'];
                      } else if (item['_id'] is Map &&
                          item['_id']['\$oid'] != null) {
                        itemId = item['_id']['\$oid'];
                      } else {
                        itemId = item['_id']?.toString() ?? '';
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailScreen(
                            itemId: itemId,
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.visibility_outlined, size: 18),
                    label: Text('View Item'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _darkSlate,
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openChat(
                      request['_id'],
                      owner['name'] ?? 'User',
                      item['itemName'] ?? 'Item',
                    ),
                    icon: Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
      case 'inquiry':
        color = Colors.orange;
        label = status == 'inquiry' ? 'Inquiry' : 'Pending';
        break;
      case 'accepted':
      case 'confirmed':
        color = Colors.green;
        label = 'Accepted';
        break;
      case 'rejected':
      case 'cancelled':
        color = Colors.red;
        label = status == 'rejected' ? 'Rejected' : 'Cancelled';
        break;
      case 'active':
        color = Colors.blue;
        label = 'Active';
        break;
      case 'completed':
        color = Colors.grey;
        label = 'Completed';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _openChat(String requestId, String otherUserName, String itemName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          requestId: requestId,
          currentUserId: widget.currentUserId,
          otherUserName: otherUserName,
          itemName: itemName,
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
