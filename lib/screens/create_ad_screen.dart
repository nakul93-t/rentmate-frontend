import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:rentmate/constants.dart';

class CreateAdScreen extends StatefulWidget {
  final String currentUserId;

  const CreateAdScreen({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();

  // Selected values
  String? selectedCategoryId;
  String? selectedSubCategoryId;
  String selectedUnit = 'piece';
  String selectedPriceUnit = 'day';

  // Lists
  List<dynamic> categories = [];
  List<dynamic> subCategories = [];
  List<dynamic> allSubCategories = [];
  List<File> selectedImages = [];
  List<VariantInput> variants = [];

  bool isLoading = false;
  bool isLoadingCategories = true;

  final String baseUrl = kBaseUrl;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    // Add one default variant
    variants.add(VariantInput());
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
        Uri.parse('$baseUrl/api/category'),
      );

      final subCatResponse = await http.get(
        Uri.parse('$baseUrl/api/sub-category'),
      );

      if (response.statusCode == 200 && subCatResponse.statusCode == 200) {
        setState(() {
          categories = json.decode(response.body);
          allSubCategories = json.decode(subCatResponse.body);
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => isLoadingCategories = false);
    }
  }

  void _onCategoryChanged(String? categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
      selectedSubCategoryId = null;

      // Filter subcategories
      if (categoryId != null) {
        subCategories = allSubCategories
            .where((sub) => sub['categoryId'] == categoryId)
            .toList();
      } else {
        subCategories = [];
      }
    });
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          // Limit to 4 images
          selectedImages = images
              .take(4)
              .map((xFile) => File(xFile.path))
              .toList();
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images')),
      );
    }
  }

  void _addVariant() {
    setState(() {
      variants.add(VariantInput());
    });
  }

  void _removeVariant(int index) {
    setState(() {
      variants.removeAt(index);
    });
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Prepare variants data
      List<Map<String, dynamic>> variantsData = variants
          .where((v) => v.label.isNotEmpty)
          .map(
            (v) => {
              'label': v.label,
              'variantType': v.type,
              'stock': v.stock,
              'priceModifier': v.priceModifier,
              'isAvailable': true,
            },
          )
          .toList();

      // Create item data
      final itemData = {
        'itemName': _nameController.text.trim(),
        'categoryId': selectedCategoryId,
        'subCategoryId': selectedSubCategoryId,
        'basePrice': double.parse(_priceController.text),
        'priceUnit': selectedPriceUnit,
        'unit': selectedUnit,
        'description': _descriptionController.text.trim(),
        'securityDeposit': _depositController.text.isNotEmpty
            ? double.parse(_depositController.text)
            : 0,
        'variants': variantsData,
        'isActive': true,
        'createdBy': widget.currentUserId,
        // TODO: Upload images to server/cloud storage
        'images': [], // For now, empty. You'll need image upload
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/item/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(itemData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ad posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _formKey.currentState!.reset();
        _nameController.clear();
        _priceController.clear();
        _descriptionController.clear();
        _depositController.clear();
        setState(() {
          selectedImages.clear();
          variants = [VariantInput()];
          selectedCategoryId = null;
          selectedSubCategoryId = null;
        });
      } else {
        throw Exception('Failed to create ad');
      }
    } catch (e) {
      print('Error creating ad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post ad'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingCategories) {
      return Scaffold(
        appBar: AppBar(title: Text('Post Ad')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Post Ad'),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _submitAd,
            child: Text(
              'POST',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images Section
              Text(
                'Photos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              _buildImagePicker(),
              SizedBox(height: 24),

              // Item Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Drill Machine, Camera',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: categories.map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem(
                    value: category['_id'],
                    child: Text(category['categoryName']),
                  );
                }).toList(),
                onChanged: _onCategoryChanged,
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Subcategory (if available)
              if (subCategories.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: selectedSubCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Subcategory',
                    border: OutlineInputBorder(),
                  ),
                  items: subCategories.map<DropdownMenuItem<String>>((sub) {
                    return DropdownMenuItem(
                      value: sub['_id'],
                      child: Text(sub['subCategoryName']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedSubCategoryId = value);
                  },
                ),
              if (subCategories.isNotEmpty) SizedBox(height: 16),

              // Price
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price *',
                        border: OutlineInputBorder(),
                        prefixText: '₹',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedPriceUnit,
                      decoration: InputDecoration(
                        labelText: 'Per',
                        border: OutlineInputBorder(),
                      ),
                      items: ['day', 'hour', 'week', 'month']
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedPriceUnit = value!);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Security Deposit
              TextFormField(
                controller: _depositController,
                decoration: InputDecoration(
                  labelText: 'Security Deposit (Optional)',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),

              // Unit
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                items: ['piece', 'kg', 'box', 'meter', 'liter']
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedUnit = value!);
                },
              ),
              SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  hintText: 'Describe your item...',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Variants Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Variants (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addVariant,
                    icon: Icon(Icons.add),
                    label: Text('Add Variant'),
                  ),
                ],
              ),
              Text(
                'Add different brands, sizes, or colors',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: 8),
              ...variants.asMap().entries.map((entry) {
                return _buildVariantInput(entry.key, entry.value);
              }).toList(),

              SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitAd,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Post Ad',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      height: 120,
      child: Row(
        children: [
          // Add Image Button
          InkWell(
            onTap: _pickImages,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                  SizedBox(height: 4),
                  Text(
                    'Add Photos',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '(Max 4)',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),

          // Selected Images
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantInput(int index, VariantInput variant) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Variant ${index + 1}',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                if (variants.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeVariant(index),
                  ),
              ],
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: variant.type,
              decoration: InputDecoration(
                labelText: 'Variant Type',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: ['brand', 'size', 'color', 'model', 'capacity']
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => variant.type = value!);
              },
            ),
            SizedBox(height: 8),
            TextFormField(
              initialValue: variant.label,
              decoration: InputDecoration(
                labelText: 'Label (e.g., Bosch, Large, Red)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => variant.label = value,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: variant.stock.toString(),
                    decoration: InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      variant.stock = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: variant.priceModifier.toString(),
                    decoration: InputDecoration(
                      labelText: 'Extra Charge',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '₹',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      variant.priceModifier = double.tryParse(value) ?? 0;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class for variant input
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
