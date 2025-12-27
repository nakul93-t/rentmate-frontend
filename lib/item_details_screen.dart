import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rentmate/constants.dart';
import 'package:rentmate/screens/chats/chat_screen.dart';
import 'package:rentmate/screens/create_ad_screen.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

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
  bool isLoading = false;
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

  bool get isOwner {
    if (itemData == null || itemData!['createdBy'] == null) return false;
    // Handle both object populate and raw ID cases if API varies,
    // but typically it's populated based on previous code.
    final creatorId = itemData!['createdBy'] is Map
        ? itemData!['createdBy']['_id']
        : itemData!['createdBy'];
    return widget.currentUserId.toString().trim() ==
        creatorId.toString().trim();
  }

  Future<void> _loadItemDetails() async {
    try {
      setState(() => isLoading = true);
      final response = await http.get(
        Uri.parse('$kBaseUrl/item/${widget.itemId}'),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          itemData = json.decode(response.body);
          if (itemData!['variants'] != null &&
              itemData!['variants'].isNotEmpty) {
            // Handle variant _id - could be String or Map
            final variantId = itemData!['variants'][0]['_id'];
            if (variantId is String) {
              selectedVariantId = variantId;
            } else if (variantId is Map && variantId['\$oid'] != null) {
              selectedVariantId = variantId['\$oid'];
            } else {
              selectedVariantId = variantId?.toString();
            }
          }
          final creatorId = itemData!['createdBy'] is Map
              ? itemData!['createdBy']['_id']
              : itemData!['createdBy'];
          print(
            'DEBUG: currentUserId=${widget.currentUserId}, creatorId=$creatorId, isOwner=$isOwner',
          );
          isLoading = false;
        });
      } else {
        print('Failed to load item details: ${response.body}');
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading item: $e');
      if (mounted) setState(() => isLoading = false);
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
      final days = endDate!.difference(startDate!).inDays + 1;
      final basePrice =
          double.tryParse(itemData!['basePrice'].toString()) ?? 0.0;

      // Calculate variant price modifier if any
      double variantPrice = 0;
      if (selectedVariantId != null) {
        final variant = (itemData!['variants'] as List).firstWhere(
          (v) => v['_id'] == selectedVariantId,
          orElse: () => {},
        );
        variantPrice =
            double.tryParse(variant['priceModifier']?.toString() ?? '0') ?? 0.0;
      }

      final finalPricePerDay = basePrice + variantPrice;
      final rentalPrice = finalPricePerDay * days * quantity;

      // Validate renter info
      final renterData = itemData!['createdBy'];
      final String? renterId = renterData is Map
          ? renterData['_id']
          : renterData;

      print(
        'DEBUG: Requesting Rent - Item: ${widget.itemId}, Customer: ${widget.currentUserId}, Renter: $renterId',
      );
      print('DEBUG: Renter Data Raw: $renterData');

      if (renterId == null) {
        _showErrorSnackBar('Cannot rent: Item owner information is missing');
        setState(() => isRequesting = false);
        return;
      }

      final response = await http.post(
        Uri.parse('$kBaseUrl/rent-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'itemId': widget.itemId,
          'customerId': widget.currentUserId,
          'renterId': renterId,
          'selectedVariantId': selectedVariantId,
          'startDate': startDate!.toIso8601String(),
          'endDate': endDate!.toIso8601String(),
          'quantity': quantity,
          'rentalPrice': rentalPrice,
          'totalAmount': rentalPrice,
          'deliveryType': 'pickup',
          'status': 'pending',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final rentRequest = json.decode(response.body);
        final requestId = rentRequest['_id'];

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        final ownerName = itemData!['createdBy'] is Map
            ? (itemData!['createdBy']['name'] ?? 'Owner')
            : 'Owner';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              requestId: requestId,
              currentUserId: widget.currentUserId,
              otherUserName: ownerName,
              itemName: itemData!['itemName'],
            ),
          ),
        );
      } else {
        print('Failed to create rent request: ${response.body}');
        String errorMsg = 'Failed to send request. ';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMsg += errorData['message'];
          } else if (errorData['error'] != null) {
            errorMsg += errorData['error'];
          }
        } catch (_) {}
        _showErrorSnackBar(errorMsg);
      }
    } catch (e) {
      print('Error creating request: $e');
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => isRequesting = false);
    }
  }

  Future<void> _chatWithOwner() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please request to rent first to start chatting'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (itemData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Not Found')),
        body: Center(child: Text('Item not found or deleted')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOwner)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This is your item. You cannot rent it.',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildHeader(),
                  SizedBox(height: 24),
                  _buildOwnerInfo(),
                  SizedBox(height: 24),
                  _buildDescription(),
                  if (itemData!['variants'] != null &&
                      itemData!['variants'].isNotEmpty) ...[
                    SizedBox(height: 24),
                    _buildVariants(),
                  ],
                  if (!isOwner) ...[
                    SizedBox(height: 24),
                    Divider(),
                    SizedBox(height: 24),
                    _buildDateSelection(),
                    SizedBox(height: 24),
                    _buildQuantitySelector(),
                  ],
                  // Add bottom padding for the fixed button or scrolling
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: !isOwner ? _buildBottomBar() : null,
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateAdScreen(
                      currentUserId: widget.currentUserId,
                      itemId: widget.itemId,
                    ),
                  ),
                );
                // Reload item data if edit was successful
                if (result == true) {
                  _loadItemDetails();
                }
              },
              label: Text('Edit Item'),
              icon: Icon(Icons.edit),
              backgroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildSliverAppBar() {
    final images = itemData!['images'] as List?;
    final hasImages = images != null && images.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 400.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(color: Colors.white),
            if (hasImages)
              PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            backgroundColor: Colors.black,
                            appBar: AppBar(
                              backgroundColor: Colors.black,
                              iconTheme: IconThemeData(color: Colors.white),
                            ),
                            body: Center(
                              child: InteractiveViewer(
                                child: Image.network(images[index]),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Image.network(
                      images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                itemData!['itemName'] ?? 'Unnamed Item',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  fontFamily: 'Roboto', // Default but explicit
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '₹${itemData!['basePrice']}/day',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (itemData!['brand'] != null) ...[
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  itemData!['brand'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildOwnerInfo() {
    final owner = itemData!['createdBy'];
    final ownerName = owner is Map ? (owner['name'] ?? 'Owner') : 'Owner';

    // location is a Map with addressName
    String ownerLocation = 'Unknown Location';
    if (owner is Map && owner['location'] != null) {
      final loc = owner['location'];
      if (loc is Map) {
        ownerLocation = loc['addressName'] ?? 'Unknown Location';
      } else if (loc is String) {
        ownerLocation = loc;
      }
    }

    final String? profileImage = owner is Map ? owner['profileImage'] : null;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
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
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[100],
                  backgroundImage:
                      profileImage != null && profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : null,
                  child: profileImage == null || profileImage.isEmpty
                      ? Text(
                          ownerName.isNotEmpty
                              ? ownerName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          ownerName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (owner != null) ...[
                          SizedBox(width: 8),
                          Icon(Icons.verified, size: 16, color: Colors.blue),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          ownerLocation,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (owner != null && !isOwner)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.chat_bubble_outline),
                    color: Colors.black,
                    onPressed: _chatWithOwner,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 12),
        Text(
          itemData!['description'] ?? 'No description provided.',
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildVariants() {
    // Helper to extract ID as string
    String getIdString(dynamic id) {
      if (id is String) return id;
      if (id is Map && id['\$oid'] != null) return id['\$oid'];
      return id?.toString() ?? '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: (itemData!['variants'] as List).map<Widget>((variant) {
            final variantIdStr = getIdString(variant['_id']);
            final isSelected = selectedVariantId == variantIdStr;
            final stock = variant['stock'] ?? 0;
            final isOutOfStock = stock <= 0;
            final isAvailable = variant['isAvailable'] ?? true;

            return GestureDetector(
              onTap: isOutOfStock || !isAvailable
                  ? null
                  : () => setState(() => selectedVariantId = variantIdStr),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isOutOfStock || !isAvailable
                      ? Colors.grey[100]
                      : isSelected
                      ? Colors.black
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOutOfStock || !isAvailable
                        ? Colors.grey[300]!
                        : isSelected
                        ? Colors.black
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          variant['label'] ?? variant['brand'] ?? 'Variant',
                          style: TextStyle(
                            color: isOutOfStock || !isAvailable
                                ? Colors.grey[400]
                                : isSelected
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isOutOfStock || !isAvailable) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (variant['priceModifier'] != null &&
                            variant['priceModifier'] > 0)
                          Text(
                            '+₹${variant['priceModifier']}  •  ',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          '$stock in stock',
                          style: TextStyle(
                            color: stock > 0
                                ? isSelected
                                      ? Colors.green[300]
                                      : Colors.green[600]
                                : Colors.red[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    // Hide date selection if owner is missing to prevent renting
    if (itemData!['createdBy'] == null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This item is currently unavailable because the owner account is missing.',
                style: TextStyle(color: Colors.red[900]),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rental Period',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(true),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDateButton(false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateButton(bool isStartDate) {
    if (itemData!['createdBy'] == null) return SizedBox.shrink();

    final date = isStartDate ? startDate : endDate;
    final label = isStartDate ? 'Start Date' : 'End Date';
    final isSelected = date != null;

    return GestureDetector(
      onTap: () => _selectDate(isStartDate),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              isSelected ? DateFormat('dd MMM, yyyy').format(date) : 'Select',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    if (itemData!['createdBy'] == null) return SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Quantity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (quantity > 1) setState(() => quantity--);
                },
                icon: Icon(Icons.remove),
                color: Colors.black,
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  quantity.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => quantity++),
                icon: Icon(Icons.add),
                color: Colors.black,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final double total = _calculateTotal();
    final bool canBook = startDate != null && endDate != null && !isOwner;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '₹${total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: canBook && !isRequesting ? _requestToRent : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: isRequesting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Request to Rent',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
      initialDate: isStartDate
          ? (startDate ?? DateTime.now().add(Duration(days: 1)))
          : (endDate ?? (startDate ?? DateTime.now())),
      firstDate: DateTime.now().add(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          if (endDate != null && endDate!.isBefore(startDate!)) {
            endDate = null;
          }
        } else {
          if (startDate != null && picked.isBefore(startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('End date must be after start date')),
            );
          } else {
            endDate = picked;
          }
        }
      });
    }
  }

  double _calculateTotal() {
    if (startDate == null || endDate == null) return 0;
    final days = endDate!.difference(startDate!).inDays + 1;
    final basePrice = double.tryParse(itemData!['basePrice'].toString()) ?? 0.0;

    // Calculate variant price modifier
    double variantPrice = 0;
    if (selectedVariantId != null) {
      final variant = (itemData!['variants'] as List).firstWhere(
        (v) => v['_id'] == selectedVariantId,
        orElse: () => {},
      );
      variantPrice =
          double.tryParse(variant['priceModifier']?.toString() ?? '0') ?? 0.0;
    }

    return (basePrice + variantPrice) * days * quantity;
  }
}
