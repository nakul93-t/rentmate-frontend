import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:rentmate/constants.dart';

class RentalAcceptanceForm extends StatefulWidget {
  final Map<String, dynamic> request;
  final String currentUserId;

  const RentalAcceptanceForm({
    Key? key,
    required this.request,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<RentalAcceptanceForm> createState() => _RentalAcceptanceFormState();
}

class _RentalAcceptanceFormState extends State<RentalAcceptanceForm> {
  final _formKey = GlobalKey<FormState>();
  final String baseUrl = kBaseUrl;

  // Color scheme
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _darkSlate = Color(0xFF1E293B);
  static const Color _lightGrey = Color(0xFFF1F5F9);
  static const Color _mediumGrey = Color(0xFF64748B);

  // Form controllers
  final _customerNameController = TextEditingController();
  final _customerMobileController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _advanceAmountController = TextEditingController();
  final _extraChargeController = TextEditingController();
  final _quantityController = TextEditingController();

  // Form values
  DateTime? _rentFromDate;
  DateTime? _expectedReturnDate;
  DateTime? _actualReturnDate;
  String _status = 'on_rent';
  String _paymentMethod = 'cash';
  String _idProofType = 'aadhar_card';

  // Calculated values
  int _totalDays = 0;
  int _extraDays = 0;
  double _totalAmount = 0;

  bool _isSubmitting = false;

  // Dropdown options
  final List<Map<String, String>> _idProofOptions = [
    {'value': 'aadhar_card', 'label': 'Aadhar Card'},
    {'value': 'driving_license', 'label': 'Driving License'},
    {'value': 'voter_id', 'label': 'Voter ID'},
    {'value': 'passport', 'label': 'Passport'},
    {'value': 'pan_card', 'label': 'PAN Card'},
    {'value': 'other', 'label': 'Other'},
  ];

  final List<Map<String, String>> _paymentMethods = [
    {'value': 'cash', 'label': 'Cash'},
    {'value': 'upi', 'label': 'UPI'},
    {'value': 'card', 'label': 'Card'},
    {'value': 'bank_transfer', 'label': 'Bank Transfer'},
    {'value': 'online', 'label': 'Online'},
  ];

  final List<Map<String, String>> _statusOptions = [
    {'value': 'on_rent', 'label': 'On Rent'},
    {'value': 'returned', 'label': 'Returned'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final request = widget.request;
    final customer = request['customerId'];

    // Pre-fill customer details
    if (customer != null) {
      _customerNameController.text = customer['name'] ?? '';
      _customerMobileController.text =
          customer['phone'] ?? customer['mobile'] ?? '';
    }

    // Pre-fill dates from request
    if (request['startDate'] != null) {
      _rentFromDate = DateTime.parse(request['startDate']);
    } else {
      _rentFromDate = DateTime.now();
    }

    if (request['endDate'] != null) {
      _expectedReturnDate = DateTime.parse(request['endDate']);
    }

    // Pre-fill quantity
    _quantityController.text = (request['quantity'] ?? 1).toString();

    // Pre-fill advance amount (you can set a default or calculate)
    _advanceAmountController.text = '0';
    _extraChargeController.text = '0';

    // Calculate initial values
    _calculateDays();
    _calculateTotalAmount();
  }

  void _calculateDays() {
    if (_rentFromDate != null && _expectedReturnDate != null) {
      _totalDays = _expectedReturnDate!.difference(_rentFromDate!).inDays;
      if (_totalDays < 1) _totalDays = 1;
    }

    if (_expectedReturnDate != null && _actualReturnDate != null) {
      _extraDays = _actualReturnDate!.difference(_expectedReturnDate!).inDays;
      if (_extraDays < 0) _extraDays = 0;
    } else {
      _extraDays = 0;
    }

    setState(() {});
  }

  void _calculateTotalAmount() {
    final item = widget.request['itemId'];
    if (item == null) return;

    final basePrice = (item['basePrice'] ?? 0).toDouble();
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final extraCharge = double.tryParse(_extraChargeController.text) ?? 0;

    _totalAmount =
        (basePrice * _totalDays * quantity) +
        (basePrice * _extraDays * quantity) +
        extraCharge;
    setState(() {});
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerMobileController.dispose();
    _idNumberController.dispose();
    _locationController.dispose();
    _advanceAmountController.dispose();
    _extraChargeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String field) async {
    final initialDate = field == 'rentFrom'
        ? _rentFromDate ?? DateTime.now()
        : field == 'expectedReturn'
        ? _expectedReturnDate ?? DateTime.now()
        : _actualReturnDate ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (field == 'rentFrom') {
          _rentFromDate = picked;
        } else if (field == 'expectedReturn') {
          _expectedReturnDate = picked;
        } else if (field == 'actualReturn') {
          _actualReturnDate = picked;
        }
        _calculateDays();
        _calculateTotalAmount();
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final requestId = widget.request['_id'];
      final item = widget.request['itemId'];
      final quantity = int.tryParse(_quantityController.text) ?? 1;

      // Prepare rental data
      final rentalData = {
        'status': 'accepted',
        'rentalDetails': {
          'customerName': _customerNameController.text,
          'customerMobile': _customerMobileController.text,
          'idProofType': _idProofType,
          'idNumber': _idNumberController.text,
          'location': _locationController.text,
          'rentFromDate': _rentFromDate?.toIso8601String(),
          'expectedReturnDate': _expectedReturnDate?.toIso8601String(),
          'actualReturnDate': _actualReturnDate?.toIso8601String(),
          'totalDays': _totalDays,
          'extraDays': _extraDays,
          'advanceAmount': double.tryParse(_advanceAmountController.text) ?? 0,
          'extraCharge': double.tryParse(_extraChargeController.text) ?? 0,
          'paymentMethod': _paymentMethod,
          'rentalStatus': _status,
          'quantity': quantity,
          'totalAmount': _totalAmount,
        },
        'quantity': quantity,
        'totalAmount': _totalAmount,
      };

      // Update rent request with rental details
      final response = await http.put(
        Uri.parse('$baseUrl/rent-request/$requestId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(rentalData),
      );

      if (response.statusCode == 200) {
        // Update item stock if status is "on_rent"
        if (_status == 'on_rent' && item != null) {
          await _updateItemStock(item['_id'], -quantity); // Decrease stock
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rental accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to accept rental');
      }
    } catch (e) {
      print('Error submitting form: $e');
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

  Future<void> _updateItemStock(dynamic itemId, int quantityChange) async {
    try {
      String id = '';
      if (itemId is String) {
        id = itemId;
      } else if (itemId is Map && itemId['\$oid'] != null) {
        id = itemId['\$oid'];
      } else {
        id = itemId?.toString() ?? '';
      }

      await http.put(
        Uri.parse('$baseUrl/item/$id/stock'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quantityChange': quantityChange}),
      );
    } catch (e) {
      print('Error updating stock: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.request['itemId'];

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _darkSlate,
        foregroundColor: Colors.white,
        title: Text('Accept Rental'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Summary Card
              _buildItemSummaryCard(item),
              SizedBox(height: 16),

              // Customer Details Section
              _buildSectionCard(
                title: 'Customer Details',
                icon: Icons.person_outline,
                children: [
                  _buildTextField(
                    controller: _customerNameController,
                    label: 'Customer Name',
                    icon: Icons.person,
                    required: true,
                  ),
                  SizedBox(height: 12),
                  _buildTextField(
                    controller: _customerMobileController,
                    label: 'Customer Mobile',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    required: true,
                  ),
                  SizedBox(height: 12),
                  _buildDropdown(
                    label: 'ID Proof Type',
                    value: _idProofType,
                    items: _idProofOptions,
                    icon: Icons.badge_outlined,
                    onChanged: (v) => setState(() => _idProofType = v!),
                  ),
                  SizedBox(height: 12),
                  _buildTextField(
                    controller: _idNumberController,
                    label: 'ID Number',
                    icon: Icons.numbers,
                    required: true,
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Rental Period Section
              _buildSectionCard(
                title: 'Rental Period',
                icon: Icons.calendar_month,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Rent From',
                          value: _rentFromDate,
                          onTap: () => _selectDate(context, 'rentFrom'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField(
                          label: 'Expected Return',
                          value: _expectedReturnDate,
                          onTap: () => _selectDate(context, 'expectedReturn'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Days calculation display
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timelapse, color: _primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Total Rental Days: $_totalDays',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _primaryBlue,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_status == 'returned') ...[
                    SizedBox(height: 12),
                    _buildDateField(
                      label: 'Actual Return Date',
                      value: _actualReturnDate,
                      onTap: () => _selectDate(context, 'actualReturn'),
                    ),
                    if (_extraDays > 0) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Extra Days: $_extraDays',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
              SizedBox(height: 16),

              // Rental Details Section
              _buildSectionCard(
                title: 'Rental Details',
                icon: Icons.assignment_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _quantityController,
                          label: 'Quantity',
                          icon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateTotalAmount(),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Status',
                          value: _status,
                          items: _statusOptions,
                          icon: Icons.flag_outlined,
                          onChanged: (v) {
                            setState(() => _status = v!);
                            if (v == 'returned' && _actualReturnDate == null) {
                              _actualReturnDate = DateTime.now();
                              _calculateDays();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildTextField(
                    controller: _locationController,
                    label: 'Pickup/Delivery Location',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Payment Section
              _buildSectionCard(
                title: 'Payment Details',
                icon: Icons.payment,
                children: [
                  _buildTextField(
                    controller: _advanceAmountController,
                    label: 'Advance Amount',
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    prefix: '₹',
                  ),
                  SizedBox(height: 12),
                  _buildDropdown(
                    label: 'Payment Method',
                    value: _paymentMethod,
                    items: _paymentMethods,
                    icon: Icons.credit_card,
                    onChanged: (v) => setState(() => _paymentMethod = v!),
                  ),
                  SizedBox(height: 12),
                  _buildTextField(
                    controller: _extraChargeController,
                    label: 'Extra Charges',
                    icon: Icons.add_circle_outline,
                    keyboardType: TextInputType.number,
                    prefix: '₹',
                    onChanged: (_) => _calculateTotalAmount(),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Total Amount Display
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _darkSlate,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '₹${_totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${item?['basePrice'] ?? 0}/day × $_totalDays days × ${_quantityController.text} qty',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
                          'Accept Rental',
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

  Widget _buildItemSummaryCard(Map<String, dynamic>? item) {
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
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
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
                          Icon(Icons.image, color: Colors.grey),
                    ),
                  )
                : Icon(Icons.image, color: Colors.grey),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['itemName'] ?? 'Item',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _darkSlate,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '₹${item['basePrice'] ?? 0}/${item['priceUnit'] ?? 'day'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: _primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
              Icon(icon, color: _primaryBlue, size: 20),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool required = false,
    int maxLines = 1,
    String? prefix,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _mediumGrey),
        prefixText: prefix,
        filled: true,
        fillColor: _lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: required
          ? (v) => v?.isEmpty ?? true ? 'Required' : null
          : null,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _mediumGrey),
        filled: true,
        fillColor: _lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item['value'],
              child: Text(item['label']!),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _lightGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: _mediumGrey, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: _mediumGrey,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value != null
                        ? DateFormat('dd MMM yyyy').format(value)
                        : 'Select Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: value != null ? _darkSlate : _mediumGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
