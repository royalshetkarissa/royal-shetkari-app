import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../core/providers/post_provider.dart';
import '../core/providers/auth_provider.dart';
import '../localization/app_localizations.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  String _selectedCategory = 'farming';
  bool _isLoading = false;
  List<File> _selectedImages = [];
  List<Uint8List> _selectedImagesBytes = [];
  bool _isWeb = false;

  String? _animalType;
  String? _lactation;
  final _milkPerDayController = TextEditingController();

  final List<String> _animalTypes = [
    'Cow',
    'Buffalo',
    'Goat',
    'Sheep',
    'Other'
  ];
  final List<String> _lactationOptions = ['1st', '2nd', '3rd', '4th', '5th+'];

  final List<String> _categories = ['farming', 'animals', 'equipment', 'land'];

  @override
  void initState() {
    super.initState();
    _isWeb = kIsWeb;
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _contactController.text = user['mobile'] ?? '';
    }
  }

  @override
  void dispose() {
    _milkPerDayController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      if (_isWeb) {
        for (var file in pickedFiles) {
          final bytes = await file.readAsBytes();
          setState(() => _selectedImagesBytes.add(bytes));
        }
      } else {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((f) => File(f.path)));
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty && _selectedImagesBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one image')));
      return;
    }

    setState(() => _isLoading = true);
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    double? parsedPrice = double.tryParse(_priceController.text);
    double? milkPerDay = double.tryParse(_milkPerDayController.text);

    Position? position;
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied)
          perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse) {
          position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low);
        }
      }
    } catch (e) {
      // Ignore
    }

    final success = await postProvider.createPost(
      category: _selectedCategory,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: parsedPrice,
      location: _locationController.text.trim(),
      contactMobile: _contactController.text.trim(),
      imageFiles: _selectedImages,
      imageBytesList: _selectedImagesBytes,
      isWeb: _isWeb,
      latitude: position?.latitude,
      longitude: position?.longitude,
      animalType: _selectedCategory == 'animals' ? _animalType : null,
      lactation: _selectedCategory == 'animals' ? _lactation : null,
      milkPerDay: _selectedCategory == 'animals' ? milkPerDay : null,
    );

    setState(() => _isLoading = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Post published to community!'),
          backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(postProvider.error ?? 'Failed to publish post'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.translate('create_post_title'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 32),
              _buildCategorySelector(),
              const SizedBox(height: 24),
              if (_selectedCategory == 'animals') ...[
                _buildAnimalFields(),
                const SizedBox(height: 24),
              ],
              _buildTextField(_titleController,
                  context.translate('title_label'), Icons.title),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController,
                  context.translate('description_label'), Icons.description,
                  maxLines: 4),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(
                          _priceController,
                          context.translate('price_label'),
                          Icons.currency_rupee,
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField(
                          _locationController,
                          context.translate('location_label'),
                          Icons.location_on)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                  _contactController, context.translate('contact'), Icons.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 5),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(context.translate('submit_post').toUpperCase(),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.translate('select_images'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!)),
                    child: const Icon(Icons.add_a_photo,
                        color: Colors.grey, size: 30)),
              ),
              if (_isWeb)
                ..._selectedImagesBytes.map((bytes) => Container(
                      width: 100,
                      margin: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                              image: MemoryImage(bytes), fit: BoxFit.cover)),
                    ))
              else
                ..._selectedImages.map((file) => Container(
                      width: 100,
                      margin: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                              image: FileImage(file), fit: BoxFit.cover)),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.translate('category_label'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _categories.map((cat) {
            String catLabel = cat.toUpperCase();
            if (cat == 'animals')
              catLabel = context.translate('animals_category');
            if (cat == 'farming')
              catLabel = context.translate('farming_category');
            if (cat == 'equipment')
              catLabel = context.translate('equipment_category');
            if (cat == 'land') catLabel = context.translate('land_category');
            return ChoiceChip(
              label: Text(catLabel,
                  style: TextStyle(
                      color: _selectedCategory == cat
                          ? Colors.white
                          : Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              selected: _selectedCategory == cat,
              onSelected: (s) => setState(() => _selectedCategory = cat),
              selectedColor: const Color(0xFF2E7D32),
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1,
      TextInputType keyboardType = TextInputType.text,
      bool isOptional = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label + (isOptional ? ' (Optional)' : ''),
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (v) {
        if (isOptional) return null;
        return v!.isEmpty ? 'Field required' : null;
      },
    );
  }

  Widget _buildAnimalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _animalType,
          decoration: InputDecoration(
            labelText: context.translate('animal_type'),
            prefixIcon: const Icon(Icons.pets, color: Color(0xFF2E7D32)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[200]!)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: _animalTypes
              .map((t) => DropdownMenuItem(
                  value: t, child: Text(context.translate(t.toLowerCase()))))
              .toList(),
          onChanged: (v) => setState(() => _animalType = v),
          validator: (v) => _selectedCategory == 'animals' && v == null
              ? context.translate('field_required', defaultValue: 'Required')
              : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _lactation,
                decoration: InputDecoration(
                  labelText: context.translate('lactation'),
                  prefixIcon:
                      const Icon(Icons.numbers, color: Color(0xFF2E7D32)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[200]!)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: _lactationOptions
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(context.translate(t.toLowerCase()))))
                    .toList(),
                onChanged: (v) => setState(() => _lactation = v),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                _milkPerDayController,
                context.translate('milk_per_day'),
                Icons.water_drop,
                keyboardType: TextInputType.number,
                isOptional: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
