import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:rentmate/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfileScreen({super.key, this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _userId;
  File? _selectedImage;
  String? _currentProfileImage;

  // Color scheme - matching app design
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _darkSlate = Color(0xFF1E293B);
  static const Color _lightGrey = Color(0xFFF1F5F9);
  static const Color _mediumGrey = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.userData != null) {
      _nameController.text = widget.userData?['name'] ?? '';
      _phoneController.text = widget.userData?['phone'] ?? '';
      _addressController.text =
          widget.userData?['location']?['addressName'] ?? '';
      _currentProfileImage = widget.userData?['profileImage'];
    }
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      log('Error picking image: $e');
      _showMessage('Failed to pick image');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) {
      _showMessage('User not logged in');
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? uploadedImageUrl;

      // Upload image first if a new image was selected
      if (_selectedImage != null) {
        log('📤 [UPLOAD] Starting image upload...');
        uploadedImageUrl = await _uploadImage(_selectedImage!);
        if (uploadedImageUrl == null) {
          log('❌ [UPLOAD] Image upload failed');
          if (mounted) {
            _showMessage('Failed to upload image. Please try again.');
            setState(() => _isSaving = false);
          }
          return;
        }
        log('✅ [UPLOAD] Image uploaded successfully: $uploadedImageUrl');
      }

      // Build request body
      final Map<String, dynamic> body = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': {
          'addressName': _addressController.text.trim(),
        },
      };

      // Include profileImage if we uploaded a new one
      if (uploadedImageUrl != null) {
        body['profileImage'] = uploadedImageUrl;
        log('📝 [PROFILE] Including profileImage in update: $uploadedImageUrl');
      }

      log('📤 [PROFILE] Updating profile for user: $_userId');
      log('📤 [PROFILE] Request body: ${jsonEncode(body)}');

      final response = await http
          .put(
            Uri.parse('$kBaseUrl/user/$_userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      log('📥 [PROFILE] Response status: ${response.statusCode}');
      log('📥 [PROFILE] Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showMessage('Profile updated successfully!', isError: false);
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        final errorData = jsonDecode(response.body);
        _showMessage(errorData['message'] ?? 'Failed to update profile');
      }
    } catch (e, s) {
      log('Error saving profile: $e', stackTrace: s);
      if (mounted) {
        _showMessage('Network error. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Uploads an image file to the server and returns the URL
  Future<String?> _uploadImage(File imageFile) async {
    try {
      log('📤 [UPLOAD] Preparing multipart request...');

      final uri = Uri.parse('$kBaseUrl/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add the image file
      final fileName = imageFile.path.split('/').last;
      log('📤 [UPLOAD] File name: $fileName');

      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // This must match the backend field name
          imageFile.path,
          filename: fileName,
        ),
      );

      log('📤 [UPLOAD] Sending request to: $uri');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      log('📥 [UPLOAD] Response status: ${response.statusCode}');
      log('📥 [UPLOAD] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['url'] as String?;
        log('✅ [UPLOAD] Got image URL: $url');
        return url;
      } else {
        log('❌ [UPLOAD] Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e, s) {
      log('❌ [UPLOAD] Error uploading image: $e', stackTrace: s);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _darkSlate),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: _darkSlate,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primaryBlue,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: _primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileImageSection(),
                  const SizedBox(height: 16),
                  _buildFormSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileImageSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryBlue.withOpacity(0.1),
                  border: Border.all(
                    color: _primaryBlue.withOpacity(0.2),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _buildProfileImage(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to change photo',
            style: TextStyle(
              fontSize: 14,
              color: _mediumGrey.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    } else if (_currentProfileImage != null &&
        _currentProfileImage!.isNotEmpty) {
      return Image.network(
        _currentProfileImage!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (_, __, ___) => _buildInitials(),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    final name = _nameController.text;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: _primaryBlue,
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkSlate,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter your phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Location',
              hint: 'Enter your location',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _darkSlate,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            color: _darkSlate,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _mediumGrey.withOpacity(0.6),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              icon,
              color: _mediumGrey,
              size: 22,
            ),
            filled: true,
            fillColor: _lightGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.orange.shade700
            : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
