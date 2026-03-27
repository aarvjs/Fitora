import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fitora/core/constants/app_colors.dart';
import '../../core/utils/cloudinary_upload.dart';
import '../services/trainer_auth_service.dart';

class TrainerAuthScreen extends StatefulWidget {
  const TrainerAuthScreen({super.key});

  @override
  State<TrainerAuthScreen> createState() => _TrainerAuthScreenState();
}

class _TrainerAuthScreenState extends State<TrainerAuthScreen> {
  final TrainerAuthService _authService = TrainerAuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  File? _imageFile;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isLogin && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a profile photo', style: GoogleFonts.inter()), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _authService.loginTrainer(username: _usernameController.text.trim(), password: _passwordController.text);
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/trainer-dashboard', (r) => false);
      } else {
        final imageUrl = await CloudinaryService.uploadImage(_imageFile!);
        if (imageUrl == null) throw Exception("Failed to upload profile photo.");
        await _authService.registerTrainer(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          profileImageUrl: imageUrl,
        );
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/trainer-dashboard', (r) => false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.inter()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _isLogin;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero Image ──────────────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 300,
                  child: Image.asset(
                    isLogin ? 'assets/trainer_login_hero.png' : 'assets/trainer_register_hero.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // Dark gradient overlay
                Container(
                  height: 300,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC0D0D0D)],
                      stops: [0.4, 1.0],
                    ),
                  ),
                ),
                // Back button
                Positioned(
                  top: 48,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    ),
                  ),
                ),
                // Title overlay
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLogin ? 'Welcome Back,\nTrainer 💪' : 'Join the\nFitlix Team 🔥',
                        style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isLogin ? 'Login to continue your fitness journey.' : 'Create your professional trainer profile.',
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Form Card ──────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0D0D0D),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Profile Image Picker (Register only) ──
                    if (!isLogin) ...[
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 100, height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 2.5),
                                  image: _imageFile != null
                                      ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                                      : null,
                                  color: const Color(0xFF1A1A1A),
                                ),
                                child: _imageFile == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 28),
                                          const SizedBox(height: 4),
                                          Text('Add Photo', style: GoogleFonts.inter(fontSize: 10, color: AppColors.primary)),
                                        ],
                                      )
                                    : null,
                              ),
                              if (_imageFile != null)
                                Positioned(
                                  right: 2, bottom: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                    child: const Icon(Icons.edit, color: Colors.white, size: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildField(controller: _nameController, label: 'Full Name', hint: 'Your display name', icon: Icons.person_outline,
                        validator: (v) => v!.trim().isEmpty ? 'Enter your name' : null),
                      const SizedBox(height: 14),
                    ],

                    _buildField(controller: _usernameController, label: 'Username', hint: 'e.g. john_trainer', icon: Icons.alternate_email,
                      validator: (v) {
                        if (v!.isEmpty) return 'Enter username';
                        if (v.contains(' ')) return 'No spaces allowed';
                        if (v != v.toLowerCase()) return 'Lowercase only';
                        return null;
                      }),
                    const SizedBox(height: 14),

                    if (!isLogin) ...[
                      _buildField(controller: _phoneController, label: 'Phone Number', hint: 'e.g. 9876543210', icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.trim().isEmpty ? 'Enter phone number' : null),
                      const SizedBox(height: 14),
                    ],

                    _buildField(
                      controller: _passwordController, label: 'Password', hint: 'Min 6 characters', icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 14),

                    if (!isLogin) ...[
                      _buildField(
                        controller: _confirmPasswordController, label: 'Confirm Password', hint: 'Re-enter password', icon: Icons.lock_outline,
                        obscureText: _obscureConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 24),
                    ],

                    const SizedBox(height: 10),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _submit,
                              child: Text(
                                isLogin ? 'Login' : 'Create Account',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),

                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white12)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                        ),
                        Expanded(child: Divider(color: Colors.white12)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Toggle
                    GestureDetector(
                      onTap: () => setState(() { _isLogin = !_isLogin; _formKey.currentState?.reset(); _imageFile = null; }),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
                          children: [
                            TextSpan(text: isLogin ? "Don't have an account? " : "Already have an account? "),
                            TextSpan(
                              text: isLogin ? 'Register' : 'Login',
                              style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        errorStyle: GoogleFonts.inter(color: Colors.redAccent),
      ),
    );
  }
}
