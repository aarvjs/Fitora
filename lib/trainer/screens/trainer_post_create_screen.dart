import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/cloudinary_upload.dart';
import '../models/trainer_post_model.dart';

class TrainerPostCreateScreen extends StatefulWidget {
  final String initialMode; // 'photo', 'video', 'article', or '' for general

  const TrainerPostCreateScreen({super.key, this.initialMode = ''});

  @override
  State<TrainerPostCreateScreen> createState() => _TrainerPostCreateScreenState();
}

class _TrainerPostCreateScreenState extends State<TrainerPostCreateScreen> {
  File? _mediaFile;
  bool _isVideo = false;
  bool _isTextMode = false;
  VideoPlayerController? _videoController;

  final TextEditingController _descController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Auto-trigger the right mode when opened from dashboard quick actions
    if (widget.initialMode.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        switch (widget.initialMode) {
          case 'photo':
            _pickMedia(ImageSource.gallery, false);
            break;
          case 'video':
            _pickMedia(ImageSource.gallery, true);
            break;
          case 'article':
            setState(() {
              _isTextMode = true;
              _mediaFile = null;
              _isVideo = false;
            });
            break;
        }
      });
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, bool isVideoMode) async {
    final picker = ImagePicker();
    XFile? pickedFile;
    
    try {
      if (isVideoMode) {
        pickedFile = await picker.pickVideo(source: source);
      } else {
        pickedFile = await picker.pickImage(source: source, imageQuality: 70);
      }

      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile!.path);
          _isVideo = isVideoMode;
          _isTextMode = false;
        });

        if (_isVideo) {
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(_mediaFile!)
            ..initialize().then((_) {
              setState(() {});
              _videoController!.setLooping(true);
              _videoController!.play();
            });
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking media: $e')));
    }
  }

  void _showMediaPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Post Type', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.article_outlined, color: AppColors.primary),
              title: const Text('Write Article'),
              onTap: () { 
                Navigator.pop(ctx); 
                setState(() {
                  _isTextMode = true;
                  _mediaFile = null;
                  _isVideo = false;
                  _videoController?.dispose();
                  _videoController = null;
                });
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () { Navigator.pop(ctx); _pickMedia(ImageSource.camera, false); },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: AppColors.primary),
              title: const Text('Record Video'),
              onTap: () { Navigator.pop(ctx); _pickMedia(ImageSource.camera, true); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose Image from Gallery'),
              onTap: () { Navigator.pop(ctx); _pickMedia(ImageSource.gallery, false); },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: AppColors.primary),
              title: const Text('Choose Video from Gallery'),
              onTap: () { Navigator.pop(ctx); _pickMedia(ImageSource.gallery, true); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPost() async {
    if (!_isTextMode && _mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select media or switch to Article mode!')));
      return;
    }
    if (_isTextMode && _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write an article first!')));
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() => _isUploading = true);
    
    try {
      String? url;
      if (!_isTextMode) {
        url = await CloudinaryService.uploadMedia(_mediaFile!, _isVideo);
        if (url == null) throw Exception('Failed to upload media to Cloudinary');
      }

      final postRef = FirebaseFirestore.instance.collection('posts').doc();
      final post = TrainerPostModel(
        id: postRef.id,
        trainerId: currentUserId,
        mediaUrl: url ?? '',
        type: _isTextMode ? 'text' : (_isVideo ? 'video' : 'image'),
        description: _descController.text.trim(),
        createdAt: DateTime.now(),
      );

      await postRef.set(post.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post published successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading post: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('New Post', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (!_isUploading)
            TextButton(
              onPressed: _uploadPost,
              child: Text('Post', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          if (_isUploading)
            const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0FDF4),
                foregroundColor: AppColors.primary,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50)
              ),
              icon: Icon(_isTextMode ? Icons.article : Icons.add_photo_alternate),
              label: Text(_isTextMode ? 'Article Mode Active (Tap to switch)' : 'Select Media / Write Article'),
              onPressed: _showMediaPickerOptions,
            ),
            const SizedBox(height: 24),
            
            if (_isTextMode)
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                 child: Row(
                   children: [
                     const Icon(Icons.info_outline, color: Colors.blue),
                     const SizedBox(width: 8),
                     Expanded(child: Text("You are writing an Article. No media is required.", style: GoogleFonts.inter(color: Colors.blue[800]))),
                   ],
                 ),
               )
            else if (_mediaFile != null) ...[
              if (_isVideo && _videoController != null && _videoController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                )
              else if (!_isVideo)
                Image.file(_mediaFile!, height: 300, width: double.infinity, fit: BoxFit.cover),
            ],
            
            const SizedBox(height: 24),
            TextField(
              controller: _descController,
              maxLines: _isTextMode ? 15 : 4,
              maxLength: _isTextMode ? 3000 : 500,
              style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.w500), // Fix constraints
              decoration: InputDecoration(
                hintText: 'Write your thoughts...', // Generic static constraint mapped
                hintStyle: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.w600), // Clarified Hint
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100], // Visible block
              ),
            ),
          ],
        ),
      ),
    );
  }
}
