import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:rentmate/constants.dart';
import 'package:rentmate/screens/chats/chat_screen.dart';
import 'package:rentmate/item_details_screen.dart';
import 'package:rentmate/screens/create_ad_screen.dart';
import 'package:rentmate/screens/rental_acceptance_form.dart';
import 'package:rentmate/screens/return_item_form.dart';

class MyAddsListPage extends StatefulWidget {
  final String currentUserId;

  const MyAddsListPage({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<MyAddsListPage> createState() => _MyAddsListPageState();
}

class _MyAddsListPageState extends State<MyAddsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String baseUrl = kBaseUrl;

  List<dynamic> myItems = [];
  List<dynamic> requestsForMyItems = []; // Pending requests as owner
  List<dynamic> rentedItems = []; // Accepted/active rentals as owner

  bool isLoadingItems = true;
  bool isLoadingRequests = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMyItems(),
      _loadMyRentRequests(),
    ]);
  }

  Future<void> _loadMyItems() async {
    setState(() => isLoadingItems = true);
    print('_loadmy items');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/item/user/${widget.currentUserId}'),
      );

      print('response =  ${response.body}');

      if (response.statusCode == 200) {
        print('status is 200');
        setState(() {
          myItems = json.decode(response.body);
          isLoadingItems = false;
        });
      }
      print('ouside if ${response.body}');
    } catch (e) {
      print('Error loading items: $e');
      setState(() => isLoadingItems = false);
    }
  }

  Future<void> _loadMyRentRequests() async {
    setState(() => isLoadingRequests = true);
    try {
      // Get requests for my items (as owner/renter)
      final renterResponse = await http.get(
        Uri.parse(
          '$baseUrl/rent-request/user/${widget.currentUserId}?role=renter',
        ),
      );

      if (renterResponse.statusCode == 200) {
        final allRequests = json.decode(renterResponse.body) as List;

        // Separate pending requests from accepted/active rentals
        setState(() {
          requestsForMyItems = allRequests
              .where((r) => ['pending', 'inquiry'].contains(r['status']))
              .toList();
          rentedItems = allRequests
              .where(
                (r) => [
                  'accepted',
                  'active',
                  'confirmed',
                  'in_transit',
                ].contains(r['status']),
              )
              .toList();
          isLoadingRequests = false;
        });
      }
    } catch (e) {
      print('Error loading requests: $e');
      setState(() => isLoadingRequests = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Ads'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'My Items'),
            Tab(text: 'Requests'),
            Tab(text: 'Rented'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyItemsTab(),
          _buildRequestsTab(),
          _buildRentedTab(),
        ],
      ),
    );
  }

  // TAB 1: Items I Posted
  Widget _buildMyItemsTab() {
    if (isLoadingItems) {
      return Center(child: CircularProgressIndicator());
    }

    if (myItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No items posted yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Post your first item to start renting',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyItems,
      child: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: myItems.length,
        itemBuilder: (context, index) {
          final item = myItems[index];
          return _buildMyItemCard(item);
        },
      ),
    );
  }

  Widget _buildMyItemCard(Map<String, dynamic> item) {
    final bool isActive = item['isActive'] ?? false;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: item['images'] != null && item['images'].isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['images'][0],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.image, color: Colors.grey);
                    },
                  ),
                )
              : Icon(Icons.image, color: Colors.grey),
        ),
        title: Text(
          item['itemName'] ?? 'Unknown Item',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('₹${item['basePrice']}/day'),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.green[700] : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
              value: 'edit',
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
              value: 'delete',
            ),
          ],
          onSelected: (value) async {
            // Helper to extract ID string
            String getIdStr(dynamic id) {
              if (id is String) return id;
              if (id is Map && id['\$oid'] != null) return id['\$oid'];
              return id?.toString() ?? '';
            }

            final itemId = getIdStr(item['_id']);

            if (value == 'edit') {
              // Navigate to edit screen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateAdScreen(
                    currentUserId: widget.currentUserId,
                    itemId: itemId,
                  ),
                ),
              );
              // Reload items if edit was successful
              if (result == true) {
                _loadMyItems();
              }
            } else if (value == 'delete') {
              _deleteItem(itemId);
            }
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(
                itemId: item['_id'],
                currentUserId: widget.currentUserId,
              ),
            ),
          );
        },
      ),
    );
  }

  // TAB 2: Requests (Split into two sections)
  Widget _buildRequestsTab() {
    if (isLoadingRequests) {
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadMyRentRequests,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Requests for My Items (as owner/renter)
            _buildSectionHeader(
              'Requests for My Items',
              requestsForMyItems.length,
              Icons.notification_important,
            ),
            SizedBox(height: 8),
            if (requestsForMyItems.isEmpty)
              _buildEmptyState('No requests yet', 'Requests will appear here')
            else
              ...requestsForMyItems
                  .map((request) => _buildRenterRequestCard(request))
                  .toList(),
          ],
        ),
      ),
    );
  }

  // TAB 3: Rented Items (Accepted/Active rentals)
  Widget _buildRentedTab() {
    if (isLoadingRequests) {
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadMyRentRequests,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Currently Rented Out',
              rentedItems.length,
              Icons.check_circle,
            ),
            SizedBox(height: 8),
            if (rentedItems.isEmpty)
              _buildEmptyState(
                'No active rentals',
                'Accepted rentals will appear here',
              )
            else
              ...rentedItems
                  .map((request) => _buildRentedItemCard(request))
                  .toList(),
          ],
        ),
      ),
    );
  }

  // Card for rented items
  Widget _buildRentedItemCard(Map<String, dynamic> request) {
    if (request['itemId'] == null) return SizedBox();

    final item = request['itemId'];
    final customer = request['customerId'];
    final status = request['status'];
    final rentalDetails = request['rentalDetails'];

    if (customer == null) return SizedBox();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Item image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: item['images'] != null && item['images'].isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['images'][0],
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                Icon(Icons.image, color: Colors.grey),
                          ),
                        )
                      : Icon(Icons.inventory_2, color: Colors.grey),
                ),
                SizedBox(width: 12),
                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['itemName'] ?? 'Item',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Rented to: ${customer['name'] ?? 'Customer'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      if (rentalDetails != null &&
                          rentalDetails['customerMobile'] != null)
                        Text(
                          'Mobile: ${rentalDetails['customerMobile']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            SizedBox(height: 12),
            // Rental details
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rental Period',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        '${_formatDate(request['startDate'])} - ${_formatDate(request['endDate'])}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        '₹${request['totalAmount'] ?? 0}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openChat(
                      request['_id'],
                      customer['name'] ?? 'Customer',
                      item['itemName'] ?? 'Item',
                    ),
                    icon: Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openReturnItemForm(request),
                    icon: Icon(Icons.assignment_return, size: 18),
                    label: Text('Mark Returned'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Card for requests on my items (I am the owner/renter)
  Widget _buildRenterRequestCard(Map<String, dynamic> request) {
    if (request['itemId'] == null) return SizedBox();

    final item = request['itemId'];
    final customer = request['customerId'];
    final status = request['status'];

    if (customer == null) return SizedBox();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(customer['name'][0].toUpperCase()),
            ),
            title: Text(
              '${customer['name']} wants to rent',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('Your ${item['itemName']}'),
                if (request['startDate'] != null)
                  Text(
                    '${_formatDate(request['startDate'])} - ${_formatDate(request['endDate'])}',
                    style: TextStyle(fontSize: 12),
                  ),
                SizedBox(height: 4),
                _buildStatusChip(status),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline, color: Colors.blue),
                  onPressed: () => _openChat(
                    request['_id'],
                    customer['name'] ?? 'User',
                    item['itemName'] ?? 'Item',
                  ),
                  tooltip: 'Chat',
                ),
                Text(
                  '₹${request['totalAmount'] ?? 0}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            onTap: () => _openChat(
              request['_id'],
              customer['name'] ?? 'User',
              item['itemName'] ?? 'Item',
            ),
          ),
          if (status == 'pending')
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _updateRequestStatus(request['_id'], 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: Text('Reject'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _openRentalAcceptanceForm(request),
                      child: Text('Accept'),
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _openChat(String requestId, String otherUserName, String itemName) {
    print('🔷 [MyAds] Opening chat for request: $requestId');
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

  void _openRentalAcceptanceForm(Map<String, dynamic> request) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RentalAcceptanceForm(
          request: request,
          currentUserId: widget.currentUserId,
        ),
      ),
    );

    if (result == true) {
      _loadMyRentRequests();
    }
  }

  void _openReturnItemForm(Map<String, dynamic> request) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReturnItemForm(
          request: request,
          currentUserId: widget.currentUserId,
        ),
      ),
    );

    if (result == true) {
      _loadMyRentRequests();
    }
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    try {
      // Use the correct endpoint based on status
      String endpoint = '$baseUrl/rent-request/$requestId/status';
      Map<String, dynamic> body = {'status': status};

      // For returned status, use the dedicated /return endpoint
      if (status == 'returned') {
        endpoint = '$baseUrl/rent-request/$requestId/return';
        body = {'actualReturnDate': DateTime.now().toIso8601String()};
      }

      final response = await http.put(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request ${status}!')),
        );
        _loadMyRentRequests();
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? 'Failed to update')),
        );
      }
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update request')),
      );
    }
  }

  Future<void> _deleteItem(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item'),
        content: Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('$baseUrl/item/delete/$itemId'),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Item deleted')),
          );
          _loadMyItems();
        } else {
          log('Failed to delete item: ${response.body}');
        }
      } catch (e) {
        log('Error deleting item: $e');
      }
    }
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
