import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:rentmate/constants.dart';

class ReturnItemForm extends StatefulWidget {
  final Map<String, dynamic> request;
  final String currentUserId;

  const ReturnItemForm({
    Key? key,
    required this.request,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ReturnItemForm> createState() => _ReturnItemFormState();
}

class _ReturnItemFormState extends State<ReturnItemForm> {
  final _formKey = GlobalKey<FormState>();
  final String baseUrl = kBaseUrl;

  // Color scheme
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _darkSlate = Color(0xFF1E293B);
  static const Color _lightGrey = Color(0xFFF1F5F9);
  static const Color _mediumGrey = Color(0xFF64748B);

  // Form controllers
  final _extraChargeController = TextEditingController();
  final _damageChargeController = TextEditingController();
  final _notesController = TextEditingController();

  // Form values
  DateTime _returnDate = DateTime.now();
  String _condition = 'good';
  bool _isSubmitting = false;

  // Calculated values
  int _extraDays = 0;
  double _lateFee = 0;
  int _totalDays = 0;

  final List<Map<String, String>> _conditionOptions = [
    {'value': 'excellent', 'label': 'Excellent'},
    {'value': 'good', 'label': 'Good'},
    {'value': 'fair', 'label': 'Fair'},
    {'value': 'damaged', 'label': 'Damaged'},
  ];

  @override
  void initState() {
    super.initState();
    _calculateExtraDays();
  }

  void _calculateExtraDays() {
    final startDateStr = widget.request['startDate'];
    final endDateStr = widget.request['endDate'];

    if (startDateStr != null) {
      final startDate = DateTime.parse(startDateStr);
      // Calculate total days from start date to return date
      _totalDays =
          _returnDate.difference(startDate).inDays +
          1; // +1 to include both start and end day
    }

    if (endDateStr != null) {
      final endDate = DateTime.parse(endDateStr);
      final diff = _returnDate.difference(endDate).inDays;
      _extraDays = diff > 0 ? diff : 0;

      // Calculate late fee (1.5x daily rate)
      final item = widget.request['itemId'];
      if (item != null && _extraDays > 0) {
        final basePrice = (item['basePrice'] ?? 0).toDouble();
        _lateFee = basePrice * _extraDays * 1.5;
      } else {
        _lateFee = 0;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _extraChargeController.dispose();
    _damageChargeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        _returnDate = picked;
        _calculateExtraDays();
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final requestId = widget.request['_id'];
      final extraCharge = double.tryParse(_extraChargeController.text) ?? 0;
      final damageCharge = double.tryParse(_damageChargeController.text) ?? 0;

      final returnData = {
        'actualReturnDate': _returnDate.toIso8601String(),
        'conditionOnReturn': _condition,
        'damageNotes': _notesController.text,
        'damageCharge': damageCharge,
        'lateFee': _lateFee + extraCharge,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/rent-request/$requestId/return'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(returnData),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item marked as returned!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to mark as returned');
      }
    } catch (e) {
      print('Error submitting return: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.request['itemId'];
    final customer = widget.request['customerId'];
    final rentalDetails = widget.request['rentalDetails'];

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: Text('Mark as Returned'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item & Customer Summary
              _buildSummaryCard(item, customer, rentalDetails),
              SizedBox(height: 16),

              // Return Details Section
              _buildSectionCard(
                title: 'Return Details',
                icon: Icons.assignment_return,
                children: [
                  // Return Date
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _lightGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: _mediumGrey),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Return Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _mediumGrey,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy').format(_returnDate),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _darkSlate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.edit, color: _primaryBlue, size: 20),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  // Extra days warning
                  if (_extraDays > 0)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Late Return: $_extraDays extra day(s)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                                Text(
                                  'Late fee: ₹${_lateFee.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 12),
                  // Condition dropdown
                  DropdownButtonFormField<String>(
                    value: _condition,
                    decoration: InputDecoration(
                      labelText: 'Item Condition',
                      prefixIcon: Icon(
                        Icons.check_circle_outline,
                        color: _mediumGrey,
                      ),
                      filled: true,
                      fillColor: _lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _conditionOptions
                        .map(
                          (c) => DropdownMenuItem(
                            value: c['value'],
                            child: Text(c['label']!),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _condition = v!),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Charges Section
              _buildSectionCard(
                title: 'Charges',
                icon: Icons.attach_money,
                children: [
                  TextFormField(
                    controller: _extraChargeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Extra Charges',
                      prefixIcon: Icon(
                        Icons.add_circle_outline,
                        color: _mediumGrey,
                      ),
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: _lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintText: '0',
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _damageChargeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Damage Charges (if any)',
                      prefixIcon: Icon(
                        Icons.report_problem_outlined,
                        color: _mediumGrey,
                      ),
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: _lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintText: '0',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Notes Section
              _buildSectionCard(
                title: 'Notes',
                icon: Icons.note_alt_outlined,
                children: [
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Return Notes / Comments',
                      hintText: 'Any damage, issues, or remarks...',
                      filled: true,
                      fillColor: _lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Confirm Return',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    Map<String, dynamic>? item,
    Map<String, dynamic>? customer,
    Map<String, dynamic>? rentalDetails,
  ) {
    if (item == null) return SizedBox();

    final images = item['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty ? images[0] : null;

    return Container(
      padding: EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
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
                    Text(
                      'Rented to: ${customer?['name'] ?? 'Customer'}',
                      style: TextStyle(color: _mediumGrey, fontSize: 13),
                    ),
                    if (rentalDetails?['customerMobile'] != null)
                      Text(
                        'Mobile: ${rentalDetails!['customerMobile']}',
                        style: TextStyle(color: _mediumGrey, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rent From Date',
                          style: TextStyle(fontSize: 11, color: _mediumGrey),
                        ),
                        Text(
                          widget.request['startDate'] != null
                              ? DateFormat(
                                  'dd MMM yyyy',
                                ).format(
                                  DateTime.parse(widget.request['startDate']),
                                )
                              : 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Days',
                          style: TextStyle(fontSize: 11, color: _mediumGrey),
                        ),
                        Text(
                          '$_totalDays days',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expected Return',
                          style: TextStyle(fontSize: 11, color: _mediumGrey),
                        ),
                        Text(
                          widget.request['endDate'] != null
                              ? DateFormat(
                                  'dd MMM yyyy',
                                ).format(
                                  DateTime.parse(widget.request['endDate']),
                                )
                              : 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rental Amount',
                          style: TextStyle(fontSize: 11, color: _mediumGrey),
                        ),
                        Text(
                          '₹${widget.request['totalAmount'] ?? 0}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Extended rental alert
          if (_extraDays > 0) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ Rental Period Extended',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'This rental has been extended by $_extraDays day(s) beyond the expected return date.',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _darkSlate,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
