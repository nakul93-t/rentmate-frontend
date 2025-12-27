import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:rentmate/constants.dart';

class CreateAdScreen extends StatefulWidget {
  final String currentUserId;
  final String? itemId; // Optional - if provided, we're in edit mode

  const CreateAdScreen({
    Key? key,
    required this.currentUserId,
    this.itemId,
  }) : super(key: key);

  @override
  State<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  // Design colors
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _darkSlate = Color(0xFF1E293B);
  static const Color _lightGrey = Color(0xFFF1F5F9);
  static const Color _mediumGrey = Color(0xFF64748B);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _depositController = TextEditingController();

  bool get isEditMode => widget.itemId != null;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> subCategories = [];
  String? selectedCategoryId;
  String? selectedSubCategoryId;
  String selectedUnit = 'piece';
  String selectedPriceUnit = 'day';
  List<ImageData> imagesList = [];
  List<VariantInput> variants = [VariantInput()];

  bool isLoading = false;
  bool isUploadingImage = false;
  bool isLoadingCategories = true;
  bool isLoadingItem = false;

  String get baseUrl => '$kIpAddress';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (isEditMode) {
      _loadExistingItem();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/category/fetch-all'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories = List<Map<String, dynamic>>.from(
            data['data'] ?? [],
          );
          isLoadingCategories = false;
        });
      } else {
        setState(() => isLoadingCategories = false);
      }
    } catch (e) {
      setState(() => isLoadingCategories = false);
    }
  }

  Future<void> _loadExistingItem() async {
    if (widget.itemId == null) return;
    setState(() => isLoadingItem = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/item/${widget.itemId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final item = data['item'];

        // Helper to extract ID string
        String getIdStr(dynamic id) {
          if (id is String) return id;
          if (id is Map && id['\$oid'] != null) return id['\$oid'];
          return id?.toString() ?? '';
        }

        _nameController.text = item['itemName'] ?? '';
        _priceController.text = (item['basePrice'] ?? 0).toString();
        _descriptionController.text = item['description'] ?? '';
        _depositController.text = (item['depositAmount'] ?? 0).toString();
        selectedUnit = item['unit'] ?? 'piece';
        selectedPriceUnit = item['priceUnit'] ?? 'day';
        selectedCategoryId = getIdStr(item['categoryId']);
        selectedSubCategoryId = item['subCategoryId'] != null
            ? getIdStr(item['subCategoryId'])
            : null;

        // Load subcategories
        if (selectedCategoryId != null) {
          await _loadSubCategories(selectedCategoryId!);
        }

        // Load existing images
        final images = item['images'] as List? ?? [];
        imagesList = images
            .map(
              (url) => ImageData(
                file: File(''),
                url: url.toString(),
                isExisting: true,
              ),
            )
            .toList();

        // Load variants
        final variantsList = item['variants'] as List? ?? [];
        if (variantsList.isNotEmpty) {
          variants = variantsList
              .map(
                (v) => VariantInput(
                  type: v['type'] ?? 'brand',
                  label: v['label'] ?? '',
                  stock: v['stock'] ?? 0,
                  priceModifier: (v['priceModifier'] ?? 0).toDouble(),
                ),
              )
              .toList();
        }

        setState(() => isLoadingItem = false);
      }
    } catch (e) {
      setState(() => isLoadingItem = false);
    }
  }

  Future<void> _loadSubCategories(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sub-category/fetch-all?categoryId=$categoryId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          subCategories = List<Map<String, dynamic>>.from(
            data['data'] ?? [],
          );
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  void _onCategoryChanged(String? categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
      selectedSubCategoryId = null;
      subCategories = [];
    });
    if (categoryId != null) {
      _loadSubCategories(categoryId);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => isUploadingImage = true);

      try {
        final uri = Uri.parse('$baseUrl/api/upload');
        final request = http.MultipartRequest('POST', uri);
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            pickedFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            imagesList.add(
              ImageData(
                file: File(pickedFile.path),
                url: data['url'],
                isExisting: false,
              ),
            );
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image')),
        );
      } finally {
        setState(() => isUploadingImage = false);
      }
    }
  }

  void _removeImage(int index) {
    setState(() => imagesList.removeAt(index));
  }

  void _addVariant() {
    setState(() => variants.add(VariantInput()));
  }

  void _removeVariant(int index) {
    if (variants.length > 1) {
      setState(() => variants.removeAt(index));
    }
  }

  Future<void> _showAddSubCategoryDialog() async {
    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a category first')),
      );
      return;
    }

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add New Subcategory'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter subcategory name',
            filled: true,
            fillColor: _lightGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _mediumGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _createSubCategory(result);
    }
  }

  Future<void> _createSubCategory(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sub-category/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'subCategoryName': name,
          'categoryId': selectedCategoryId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final newSubCategory = data['data'];
          setState(() {
            subCategories.add(Map<String, dynamic>.from(newSubCategory));
            selectedSubCategoryId = newSubCategory['_id'] as String;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Subcategory "$name" created!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create subcategory')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (imagesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final body = {
        'itemName': _nameController.text,
        'categoryId': selectedCategoryId,
        'subCategoryId': selectedSubCategoryId,
        'basePrice': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'depositAmount': double.tryParse(_depositController.text) ?? 0,
        'unit': selectedUnit,
        'priceUnit': selectedPriceUnit,
        'images': imagesList.map((img) => img.url).toList(),
        'variants': variants
            .where((v) => v.label.isNotEmpty) // Filter out empty labels
            .map(
              (v) => {
                'variantType': v.type,
                'label': v.label,
                'stock': v.stock,
                'priceModifier': v.priceModifier,
                'isAvailable': v.stock > 0,
              },
            )
            .toList(),
        'createdBy': widget.currentUserId,
      };

      http.Response response;
      if (isEditMode) {
        response = await http.put(
          Uri.parse('$baseUrl/api/item/update/${widget.itemId}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );
      } else {
        response = await http.post(
          Uri.parse('$baseUrl/api/item/create'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? 'Item updated successfully!'
                  : 'Item posted successfully!',
            ),
          ),
        );
        if (isEditMode) {
          Navigator.pop(context, true);
        } else {
          _clearForm();
        }
      } else {
        throw Exception('Failed to ${isEditMode ? 'update' : 'post'} item');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _depositController.clear();
    setState(() {
      selectedCategoryId = null;
      selectedSubCategoryId = null;
      subCategories = [];
      imagesList = [];
      variants = [VariantInput()];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingCategories || isLoadingItem) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: _darkSlate,
          elevation: 0,
          title: Text(
            isEditMode ? 'Edit Ad' : 'Post New Ad',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _primaryBlue),
              SizedBox(height: 16),
              Text(
                isEditMode ? 'Loading item...' : 'Loading...',
                style: TextStyle(color: _mediumGrey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _darkSlate,
        elevation: 0,
        title: Text(
          isEditMode ? 'Edit Ad' : 'Post New Ad',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton(
              onPressed: isLoading || isUploadingImage ? null : _submitAd,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                isEditMode ? 'UPDATE' : 'POST',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos Section
              _buildSectionCard(
                title: 'Photos',
                icon: Icons.photo_library,
                required: true,
                child: Column(
                  children: [
                    _buildImagePicker(),
                    if (isUploadingImage)
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primaryBlue,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Uploading...',
                              style: TextStyle(
                                fontSize: 12,
                                color: _primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Basic Info Section
              _buildSectionCard(
                title: 'Basic Information',
                icon: Icons.info_outline,
                child: Column(
                  children: [
                    _buildModernTextField(
                      controller: _nameController,
                      label: 'Item Name',
                      hint: 'e.g., Drill Machine, DSLR Camera',
                      icon: Icons.inventory_2_outlined,
                      required: true,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    SizedBox(height: 16),
                    _buildModernDropdown(
                      value: selectedCategoryId,
                      label: 'Category',
                      icon: Icons.category_outlined,
                      required: true,
                      items: categories
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat['_id'] as String,
                              child: Text(cat['categoryName']),
                            ),
                          )
                          .toList(),
                      onChanged: _onCategoryChanged,
                    ),
                    if (selectedCategoryId != null) ...[
                      SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: subCategories.isEmpty
                                ? Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _lightGrey,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.subdirectory_arrow_right,
                                          color: _mediumGrey,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'No subcategories yet',
                                          style: TextStyle(color: _mediumGrey),
                                        ),
                                      ],
                                    ),
                                  )
                                : _buildModernDropdown(
                                    value: selectedSubCategoryId,
                                    label: 'Subcategory',
                                    icon: Icons.subdirectory_arrow_right,
                                    items: subCategories
                                        .map(
                                          (sub) => DropdownMenuItem(
                                            value: sub['_id'] as String,
                                            child: Text(sub['subCategoryName']),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) => setState(
                                      () => selectedSubCategoryId = v,
                                    ),
                                  ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: _primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: _showAddSubCategoryDialog,
                              icon: Icon(Icons.add, color: Colors.white),
                              tooltip: 'Add Subcategory',
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 16),
                    _buildModernTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Describe your item...',
                      icon: Icons.description_outlined,
                      required: true,
                      maxLines: 4,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ],
                ),
              ),

              // Pricing Section
              _buildSectionCard(
                title: 'Pricing',
                icon: Icons.currency_rupee,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildModernTextField(
                            controller: _priceController,
                            label: 'Price',
                            hint: '0',
                            icon: Icons.currency_rupee,
                            required: true,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v?.isEmpty ?? true) return 'Required';
                              if (double.tryParse(v!) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildModernDropdown(
                            value: selectedPriceUnit,
                            label: 'Per',
                            items: ['day', 'hour', 'week', 'month']
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => selectedPriceUnit = v!),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernTextField(
                            controller: _depositController,
                            label: 'Security Deposit',
                            hint: '0',
                            icon: Icons.lock_outline,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildModernDropdown(
                            value: selectedUnit,
                            label: 'Unit',
                            items: ['piece', 'kg', 'box', 'meter', 'liter']
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => selectedUnit = v!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Variants Section
              _buildSectionCard(
                title: 'Variants & Stock',
                icon: Icons.inventory,
                trailing: TextButton.icon(
                  onPressed: _addVariant,
                  icon: Icon(Icons.add, size: 18, color: _primaryBlue),
                  label: Text('Add', style: TextStyle(color: _primaryBlue)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Add brands, sizes, or colors with stock',
                      style: TextStyle(fontSize: 12, color: _mediumGrey),
                    ),
                    SizedBox(height: 12),
                    ...variants
                        .asMap()
                        .entries
                        .map((e) => _buildVariantCard(e.key, e.value))
                        .toList(),
                  ],
                ),
              ),

              // Submit Button
              Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading || isUploadingImage ? null : _submitAd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isEditMode ? 'Update Ad' : 'Post Ad',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    bool required = false,
    Widget? trailing,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _primaryBlue, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _darkSlate,
                      ),
                    ),
                    if (required)
                      Text(' *', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: _mediumGrey, size: 20)
            : null,
        filled: true,
        fillColor: _lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required T? value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    IconData? icon,
    bool required = false,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        prefixIcon: icon != null
            ? Icon(icon, color: _mediumGrey, size: 20)
            : null,
        filled: true,
        fillColor: _lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryBlue, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...imagesList.asMap().entries.map((entry) {
              final index = entry.key;
              final img = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: img.isExisting
                            ? NetworkImage(img.url)
                            : FileImage(img.file) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ],
              );
            }),
            GestureDetector(
              onTap: isUploadingImage ? null : _pickAndUploadImage,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _lightGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _primaryBlue,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Icon(Icons.add_a_photo, color: _primaryBlue, size: 28),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVariantCard(int index, VariantInput variant) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _primaryBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Variant ${index + 1}',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Spacer(),
              if (variants.length > 1)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _removeVariant(index),
                  constraints: BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: variant.type,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: ['brand', 'size', 'color', 'model', 'capacity']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => variant.type = v!),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: variant.label,
                  decoration: InputDecoration(
                    labelText: 'Label',
                    hintText: 'e.g., Bosch',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (v) => variant.label = v,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: variant.stock.toString(),
                  decoration: InputDecoration(
                    labelText: 'Stock Qty',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => variant.stock = int.tryParse(v) ?? 0,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: variant.priceModifier.toString(),
                  decoration: InputDecoration(
                    labelText: 'Extra ₹',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      variant.priceModifier = double.tryParse(v) ?? 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ImageData {
  final File file;
  final String url;
  final bool isExisting;

  ImageData({
    required this.file,
    required this.url,
    this.isExisting = false,
  });
}

class VariantInput {
  String type;
  String label;
  int stock;
  double priceModifier;

  VariantInput({
    this.type = 'brand',
    this.label = '',
    this.stock = 0,
    this.priceModifier = 0,
  });
}
