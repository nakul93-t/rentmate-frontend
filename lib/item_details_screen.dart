import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rentmate/constants.dart';
import 'package:rentmate/screens/chats/chat_screen.dart';
import 'dart:convert';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;
  final String currentUserId;

  const ItemDetailScreen({
    required this.itemId,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  Map<String, dynamic>? itemData;
  bool isLoading = true;
  DateTime? startDate;
  DateTime? endDate;
  int quantity = 1;
  String? selectedVariantId;
  bool isRequesting = false;

  @override
  void initState() {
    super.initState();
    _loadItemDetails();
  }

  Future<void> _loadItemDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/item/${widget.itemId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          itemData = json.decode(response.body);
          if (itemData!['variants'] != null &&
              itemData!['variants'].isNotEmpty) {
            selectedVariantId = itemData!['variants'][0]['_id'];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading item: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _requestToRent() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select rental dates')),
      );
      return;
    }

    setState(() => isRequesting = true);

    try {
      // Calculate rental price
      final days = endDate!.difference(startDate!).inDays + 1;
      final basePrice = double.parse(itemData!['basePrice'].toString());
      final rentalPrice = basePrice * days;

      // Create rent request
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/rent-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'itemId': widget.itemId,
          'customerId': widget.currentUserId,
          'renterId': itemData!['createdBy'],
          'selectedVariantId': selectedVariantId,
          'startDate': startDate!.toIso8601String(),
          'endDate': endDate!.toIso8601String(),
          'quantity': quantity,
          'rentalPrice': rentalPrice,
          'totalAmount': rentalPrice,
          'deliveryType': 'pickup', // You can make this selectable
          'status': 'pending',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final rentRequest = json.decode(response.body);
        final requestId = rentRequest['_id'];

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rent request sent!')),
        );

        // Navigate to chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              requestId: requestId,
              currentUserId: widget.currentUserId,
              otherUserName: itemData!['createdBy']['name'] ?? 'Owner',
              itemName: itemData!['itemName'],
            ),
          ),
        );
      } else {
        throw Exception('Failed to create request');
      }
    } catch (e) {
      print('Error creating request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request')),
      );
    } finally {
      setState(() => isRequesting = false);
    }
  }

  // Chat with owner directly (even without rent request)
  Future<void> _chatWithOwner() async {
    // Option 1: Require a rent request first
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please request to rent first to start chatting'),
      ),
    );

    // Option 2: Create a "inquiry" rent request
    // Uncomment below to allow direct chat
    /*
    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/rent-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'itemId': widget.itemId,
          'customerId': widget.currentUserId,
          'renterId': itemData!['createdBy'],
          'status': 'inquiry', // New status for just chatting
          'deliveryType': 'pickup',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final rentRequest = json.decode(response.body);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              requestId: rentRequest['_id'],
              currentUserId: widget.currentUserId,
              otherUserName: itemData!['createdBy']['name'] ?? 'Owner',
              itemName: itemData!['itemName'],
            ),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (itemData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(child: Text('Failed to load item')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(itemData!['itemName']),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[300],
              child:
                  itemData!['images'] != null && itemData!['images'].isNotEmpty
                  ? Image.network(
                      itemData!['images'][0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image, size: 100);
                      },
                    )
                  : Icon(Icons.image, size: 100),
            ),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Name & Price
                  Text(
                    itemData!['itemName'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '₹${itemData!['basePrice']}/day',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Owner Info
                  Row(
                    children: [
                      CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Posted by',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            itemData!['createdBy']['name'] ?? 'Owner',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(itemData!['description']),
                  SizedBox(height: 16),

                  // Variants
                  if (itemData!['variants'] != null &&
                      itemData!['variants'].isNotEmpty) ...[
                    Text(
                      'Available Variants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ...itemData!['variants'].map<Widget>((variant) {
                      return RadioListTile(
                        title: Text(variant['label'] ?? variant['brand']),
                        subtitle: Text(
                          'Stock: ${variant['stock']} • +₹${variant['priceModifier'] ?? 0}',
                        ),
                        value: variant['_id'],
                        groupValue: selectedVariantId,
                        onChanged: (value) {
                          setState(() => selectedVariantId = value);
                        },
                      );
                    }).toList(),
                    SizedBox(height: 16),
                  ],

                  // Date Selection
                  Text(
                    'Select Rental Period',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(true),
                          icon: Icon(Icons.calendar_today),
                          label: Text(
                            startDate != null
                                ? '${startDate!.day}/${startDate!.month}'
                                : 'Start Date',
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(false),
                          icon: Icon(Icons.calendar_today),
                          label: Text(
                            endDate != null
                                ? '${endDate!.day}/${endDate!.month}'
                                : 'End Date',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Quantity
                  Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() => quantity--);
                          }
                        },
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        quantity.toString(),
                        style: TextStyle(fontSize: 18),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => quantity++);
                        },
                        icon: Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Total Price
                  if (startDate != null && endDate != null) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total (${endDate!.difference(startDate!).inDays + 1} days)',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '₹${_calculateTotal()}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isRequesting ? null : _requestToRent,
                          icon: isRequesting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(Icons.shopping_bag),
                          label: Text('Request to Rent'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _chatWithOwner,
                          icon: Icon(Icons.chat),
                          label: Text('Chat with Owner'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
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

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          if (endDate != null && endDate!.isBefore(startDate!)) {
            endDate = null;
          }
        } else {
          if (startDate != null && picked.isAfter(startDate!)) {
            endDate = picked;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('End date must be after start date')),
            );
          }
        }
      });
    }
  }

  double _calculateTotal() {
    if (startDate == null || endDate == null) return 0;
    final days = endDate!.difference(startDate!).inDays + 1;
    final basePrice = double.parse(itemData!['basePrice'].toString());
    return basePrice * days * quantity;
  }
}
