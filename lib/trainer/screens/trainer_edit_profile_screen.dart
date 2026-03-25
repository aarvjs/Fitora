import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/cloudinary_upload.dart';
import '../models/trainer_model.dart';
import '../services/trainer_auth_service.dart';

class TrainerEditProfileScreen extends StatefulWidget {
  const TrainerEditProfileScreen({super.key});

  @override
  State<TrainerEditProfileScreen> createState() => _TrainerEditProfileScreenState();
}

class _TrainerEditProfileScreenState extends State<TrainerEditProfileScreen> {
  final TrainerAuthService _authService = TrainerAuthService();
  final _formKey = GlobalKey<FormState>();

  TrainerModel? _trainer;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _certificationsController = TextEditingController();

  File? _newProfileImage;
  File? _newCoverImage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _trainer = await _authService.getCurrentTrainer();
    if (_trainer != null) {
      _bioController.text = _trainer!.bio ?? '';
      _experienceController.text = _trainer!.experience ?? '';
      _addressController.text = _trainer!.address ?? '';
      _certificationsController.text = _trainer!.certifications ?? '';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage(bool isCover) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        if (isCover) {
          _newCoverImage = File(picked.path);
        } else {
          _newProfileImage = File(picked.path);
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _trainer == null) return;
    setState(() => _isSaving = true);

    try {
      String profileUrl = _trainer!.profileImage;
      String? coverUrl = _trainer!.coverImage;

      if (_newProfileImage != null) {
        final url = await CloudinaryService.uploadImage(_newProfileImage!);
        if (url != null) profileUrl = url;
      }
      if (_newCoverImage != null) {
         final url = await CloudinaryService.uploadImage(_newCoverImage!);
         if (url != null) coverUrl = url;
      }

      await FirebaseFirestore.instance.collection('trainers').doc(_trainer!.id).update({
        'profileImage': profileUrl,
        'coverImage': coverUrl,
        'bio': _bioController.text.trim(),
        'experience': _experienceController.text.trim(),
        'address': _addressController.text.trim(),
        'certifications': _certificationsController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_trainer == null) return const Scaffold(body: Center(child: Text('Error loading data')));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          _isSaving
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(icon: const Icon(Icons.check, color: AppColors.primary), onPressed: _saveProfile),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Image Picker
              GestureDetector(
                onTap: () => _pickImage(true),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: _newCoverImage != null
                        ? DecorationImage(image: FileImage(_newCoverImage!), fit: BoxFit.cover)
                        : (_trainer!.coverImage != null && _trainer!.coverImage!.isNotEmpty
                            ? DecorationImage(image: CachedNetworkImageProvider(_trainer!.coverImage!), fit: BoxFit.cover)
                            : null),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Profile Image Picker
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(false),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _newProfileImage != null
                            ? FileImage(_newProfileImage!) as ImageProvider
                            : (_trainer!.profileImage.isNotEmpty ? CachedNetworkImageProvider(_trainer!.profileImage) : null),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(labelText: 'Experience (e.g., 5 years)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _certificationsController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Certifications (e.g., ACE Certified, First Aid)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
