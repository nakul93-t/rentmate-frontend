import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:rentmate/constants.dart';
import 'package:rentmate/screens/return_item_form.dart';
import 'package:rentmate/theme/app_colors.dart';

class RentalDetailsScreen extends StatefulWidget {
  final String rentalId;
  final String currentUserId;

  const RentalDetailsScreen({
    Key? key,
    required this.rentalId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<RentalDetailsScreen> createState() => _RentalDetailsScreenState();
}

class _RentalDetailsScreenState extends State<RentalDetailsScreen> {
  final String baseUrl = kBaseUrl;

  Map<String, dynamic>? _rental;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRentalDetails();
  }

  Future<void> _fetchRentalDetails() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rent-request/${widget.rentalId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _rental = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showMessage('Failed to load rental details');
      }
    } catch (e) {
      print('Error fetching rental details: $e');
      setState(() => _isLoading = false);
      _showMessage('Network error');
    }
  }

  Widget? _buildBottomActionHide() {
    if (_rental == null || _isLoading) return null;

    final status = _rental!['status'] ?? 'pending';
    final renterId = _rental!['renterId'] is Map
        ? _rental!['renterId']['_id']
        : _rental!['renterId'];

    final isOwner = renterId.toString() == widget.currentUserId;

    // Show "Mark as Returned" button for owner when status is accepted
    if (status == 'accepted' && isOwner) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReturnItemForm(
                    request: _rental!,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
              if (result == true) {
                _fetchRentalDetails(); // Refresh after return
              }
            },
            icon: Icon(Icons.assignment_return),
            label: Text(
              'Mark as Returned',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    // Show Accept/Reject buttons for owner when status is pending
    if (status != 'pending' || !isOwner) {
      return null;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _rejectRequest,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Reject'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _acceptRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Accept Request',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest() async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/rent-request/${widget.rentalId}/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': 'accepted'}),
      );

      if (response.statusCode == 200) {
        _fetchRentalDetails(); // Refresh details
        _showMessage('Request accepted successfully!');
      } else {
        _showMessage('Failed to accept request');
      }
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  Future<void> _rejectRequest() async {
    final reasonController = TextEditingController();

    // Show confirmation dialog with input
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          String? errorText;
          return AlertDialog(
            title: Text('Reject Request'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to reject this request?'),
                SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'Reason for rejection (required)',
                    errorText: errorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLines: 3,
                  onChanged: (_) {
                    if (errorText != null) setState(() => errorText = null);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (reasonController.text.trim().isEmpty) {
                    setState(() => errorText = 'Reason is required');
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: Text('Reject', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/rent-request/${widget.rentalId}/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': 'rejected',
          'rejectionReason': reasonController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        _fetchRentalDetails(); // Refresh details
        _showMessage('Request rejected');
      } else {
        _showMessage('Failed to reject request');
      }
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        title: Text('Rental Details'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            )
          : _rental == null
          ? _buildErrorState()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemSection(),
                  SizedBox(height: 12),
                  _buildStatusSection(),
                  SizedBox(height: 12),
                  _buildParticipantsSection(),
                  SizedBox(height: 12),
                  _buildRentalPeriodSection(),
                  SizedBox(height: 12),
                  _buildPricingSection(),
                  if (_rental!['rentalDetails'] != null) ...[
                    SizedBox(height: 12),
                    _buildRentalDetailsSection(),
                  ],
                  if (_rental!['status'] == 'returned' ||
                      _rental!['status'] == 'completed') ...[
                    SizedBox(height: 12),
                    _buildReturnInfoSection(),
                  ],
                  SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomActionHide(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'Failed to load rental details',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchRentalDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSection() {
    final item = _rental!['itemId'];
    final images = item?['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty ? images[0] : null;
    final itemName = item?['itemName'] ?? 'Item';
    final description = item?['description'] ?? '';

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Icon(Icons.image, size: 64, color: Colors.grey),
                ),
              ),
            ),
          SizedBox(height: 16),
          Text(
            itemName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    final status = _rental!['status'] ?? 'pending';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryTeal, size: 20),
              SizedBox(width: 8),
              Text(
                'Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Spacer(),
              _buildStatusBadge(status),
            ],
          ),
          if (status == 'rejected' && _rental!['rejectionReason'] != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(),
                  SizedBox(height: 4),
                  Text(
                    'Reason for Rejection:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _rental!['rejectionReason'],
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    final customer = _rental!['customerId'];
    final owner = _rental!['renterId'];
    final customerName = customer?['name'] ?? 'Customer';
    final ownerName = owner?['name'] ?? 'Owner';
    final customerEmail = customer?['email'] ?? '';
    final ownerEmail = owner?['email'] ?? '';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline,
                color: AppColors.primaryTeal,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Participants',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildParticipantRow(
            'Customer',
            customerName,
            customerEmail,
            Icons.person,
          ),
          Divider(height: 24),
          _buildParticipantRow('Owner', ownerName, ownerEmail, Icons.store),
        ],
      ),
    );
  }

  Widget _buildParticipantRow(
    String role,
    String name,
    String email,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryTeal, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRentalPeriodSection() {
    final startDate = _rental!['startDate'] != null
        ? DateTime.parse(_rental!['startDate'])
        : null;
    final endDate = _rental!['endDate'] != null
        ? DateTime.parse(_rental!['endDate'])
        : null;

    int? totalDays;
    if (startDate != null && endDate != null) {
      totalDays = endDate.difference(startDate).inDays + 1;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.primaryTeal,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Rental Period',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateInfo(
                  'Start Date',
                  startDate != null
                      ? DateFormat('dd MMM yyyy').format(startDate)
                      : 'N/A',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDateInfo(
                  'End Date',
                  endDate != null
                      ? DateFormat('dd MMM yyyy').format(endDate)
                      : 'N/A',
                ),
              ),
            ],
          ),
          if (totalDays != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppColors.primaryTeal,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Total Duration: $totalDays days',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    final rentalPrice = _rental!['rentalPrice'] ?? 0;
    final securityDeposit = _rental!['securityDeposit'] ?? 0;
    final totalAmount = _rental!['totalAmount'] ?? 0;
    final lateFee = _rental!['lateFee'] ?? 0;
    final damageCharge = _rental!['damageCharge'] ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                color: AppColors.primaryTeal,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Pricing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildPriceRow('Rental Amount', rentalPrice),
          if (securityDeposit > 0) ...[
            SizedBox(height: 8),
            _buildPriceRow('Security Deposit', securityDeposit),
          ],
          if (lateFee > 0) ...[
            SizedBox(height: 8),
            _buildPriceRow('Late Fee', lateFee, color: AppColors.primaryTeal),
          ],
          if (damageCharge > 0) ...[
            SizedBox(height: 8),
            _buildPriceRow('Damage Charge', damageCharge, color: Colors.red),
          ],
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '₹${totalAmount + lateFee + damageCharge}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, num amount, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '₹$amount',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRentalDetailsSection() {
    final details = _rental!['rentalDetails'];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: AppColors.primaryTeal,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Additional Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (details['customerName'] != null)
            _buildDetailRow('Customer Name', details['customerName']),
          if (details['customerMobile'] != null)
            _buildDetailRow('Mobile', details['customerMobile']),
          if (details['idProofType'] != null)
            _buildDetailRow('ID Proof', details['idProofType']),
          if (details['paymentMethod'] != null)
            _buildDetailRow('Payment Method', details['paymentMethod']),
        ],
      ),
    );
  }

  Widget _buildReturnInfoSection() {
    final actualReturnDate = _rental!['actualReturnDate'] != null
        ? DateTime.parse(_rental!['actualReturnDate'])
        : null;
    final condition = _rental!['conditionOnReturn'] ?? '';
    final damageNotes = _rental!['damageNotes'] ?? '';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_return,
                color: AppColors.primaryTeal,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Return Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (actualReturnDate != null)
            _buildDetailRow(
              'Returned On',
              DateFormat('dd MMM yyyy, hh:mm a').format(actualReturnDate),
            ),
          if (condition.isNotEmpty)
            _buildDetailRow('Condition', condition.toUpperCase()),
          if (damageNotes.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                damageNotes,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        color = AppColors.primaryTeal;
        label = 'Pending';
        break;
      case 'accepted':
        color = Colors.blue;
        label = 'Accepted';
        break;
      case 'active':
        color = Colors.green;
        label = 'Active';
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
        color = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
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
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}
