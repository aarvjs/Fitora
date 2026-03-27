import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/cloudinary_upload.dart';
import '../models/trainer_model.dart';
import '../models/trainer_post_model.dart';
import '../services/trainer_auth_service.dart';
import '../services/follow_service.dart';
import '../widgets/trainer_post_card.dart';
import 'trainer_followers_screen.dart';

class TrainerProfileScreen extends StatefulWidget {
  final String? trainerId;

  const TrainerProfileScreen({super.key, this.trainerId});

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  final TrainerAuthService _authService = TrainerAuthService();
  TrainerModel? _profileTrainer;
  bool _isOwner = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final currentTrainer = await _authService.getCurrentTrainer();
    final targetId = widget.trainerId ?? currentTrainer?.id;

    if (targetId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (currentTrainer != null && currentTrainer.id == targetId) {
      _isOwner = true;
      _profileTrainer = currentTrainer;
    } else {
      _isOwner = false;
      final doc = await FirebaseFirestore.instance.collection('trainers').doc(targetId).get();
      if (doc.exists && doc.data() != null) {
        _profileTrainer = TrainerModel.fromMap(doc.data()!, doc.id);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // --- Image Edits ---
  Future<void> _changeCoverImage() async {
    final file = await _pickImage();
    if (file == null) return;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading Cover Image...')));
    final url = await CloudinaryService.uploadImage(file);
    if (url != null) {
      if (_profileTrainer!.coverImage != null) {
        await CloudinaryService.deleteImage(_profileTrainer!.coverImage!);
      }
      await FirebaseFirestore.instance.collection('trainers').doc(_profileTrainer!.id).update({'coverImage': url});
      _loadProfile();
    }
  }

  Future<void> _changeProfileImage() async {
    final file = await _pickImage();
    if (file == null) return;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading Profile Image...')));
    final url = await CloudinaryService.uploadImage(file);
    if (url != null) {
      if (_profileTrainer!.profileImage.isNotEmpty) {
        await CloudinaryService.deleteImage(_profileTrainer!.profileImage);
      }
      await FirebaseFirestore.instance.collection('trainers').doc(_profileTrainer!.id).update({'profileImage': url});
      _loadProfile();
    }
  }

  Future<File?> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    return picked != null ? File(picked.path) : null;
  }

  void _showImageEditOptions() {
    showModalBottomSheet(context: context, builder: (ctx) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.wallpaper),
              title: const Text('Change Cover Image'),
              onTap: () { Navigator.pop(ctx); _changeCoverImage(); },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Change Profile Image'),
              onTap: () { Navigator.pop(ctx); _changeProfileImage(); },
            ),
          ],
        ),
      );
    });
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Account', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('Are you unconditionally sure? This will permanently delete ALL your posts, uploaded media, certifications, and profile data from Fitlix.', style: GoogleFonts.inter(color: Colors.black87)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[700], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete Permanently', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    try {
      final trainerId = _profileTrainer!.id;
      final postsQuery = await FirebaseFirestore.instance.collection('posts').where('trainerId', isEqualTo: trainerId).get();
      
      // Delete post media + documents
      for (var doc in postsQuery.docs) {
        final data = doc.data();
        final mediaUrl = data['mediaUrl'] as String?;
        final type = data['type'] as String?;
        if (mediaUrl != null && mediaUrl.isNotEmpty) {
           await CloudinaryService.deleteMedia(mediaUrl, isVideo: type == 'video');
        }
        await doc.reference.delete();
      }

      // Delete Trainer's personal media
      if (_profileTrainer!.profileImage.isNotEmpty) await CloudinaryService.deleteImage(_profileTrainer!.profileImage);
      if (_profileTrainer!.coverImage != null && _profileTrainer!.coverImage!.isNotEmpty) await CloudinaryService.deleteImage(_profileTrainer!.coverImage!);
      if (_profileTrainer!.certificateImages != null) {
        for (var url in _profileTrainer!.certificateImages!) {
          await CloudinaryService.deleteImage(url);
        }
      }

      // Delete Trainer document
      await FirebaseFirestore.instance.collection('trainers').doc(trainerId).delete();

      // Delete Firebase Auth user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
      }
      
      if (mounted) {
        Navigator.pop(context); // close loading overlay
        Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (r) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);
      if (e.code == 'requires-recent-login') {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
             content: Text('Security check: Please log out and back in to verify your identity before deleting your account.'),
             duration: Duration(seconds: 5),
           ));
         }
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Firebase Error: ${e.message}')));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred during deletion: $e')));
    }
  }

// --- Text Detail Edits ---
  Future<void> _editDetailField(String title, String fieldKey, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final newVal = await showDialog<String>(context: context, builder: (ctx) {
      return AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          maxLines: title == 'Bio' || title == 'Address' ? 3 : 1,
          decoration: InputDecoration(hintText: 'Enter your $title...', border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      );
    });

    if (newVal != null && newVal != currentValue) {
      await FirebaseFirestore.instance.collection('trainers').doc(_profileTrainer!.id).update({fieldKey: newVal});
      _loadProfile();
    }
  }

  // --- Certificates Upload ---
  Future<void> _uploadCertificate() async {
    final file = await _pickImage();
    if (file == null) return;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading Certificate...')));
    final url = await CloudinaryService.uploadImage(file);
    if (url != null) {
      await FirebaseFirestore.instance.collection('trainers').doc(_profileTrainer!.id).update({
        'certificateImages': FieldValue.arrayUnion([url])
      });
      _loadProfile();
    }
  }
  
  // --- Social Links ---
  Future<void> _editSocialLinks() async {
    final instaController = TextEditingController(text: _profileTrainer!.socialLinks?['instagram'] ?? '');
    final fbController = TextEditingController(text: _profileTrainer!.socialLinks?['facebook'] ?? '');
    final otherController = TextEditingController(text: _profileTrainer!.socialLinks?['other'] ?? '');

    final update = await showDialog<bool>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Edit Social Links'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: instaController, decoration: const InputDecoration(labelText: 'Instagram URL')),
              const SizedBox(height: 12),
              TextField(controller: fbController, decoration: const InputDecoration(labelText: 'Facebook URL')),
              const SizedBox(height: 12),
              TextField(controller: otherController, decoration: const InputDecoration(labelText: 'Other URL (e.g., Website)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      );
    });

    if (update == true) {
      Map<String, String> newLinks = {};
      if (instaController.text.isNotEmpty) newLinks['instagram'] = instaController.text.trim();
      if (fbController.text.isNotEmpty) newLinks['facebook'] = fbController.text.trim();
      if (otherController.text.isNotEmpty) newLinks['other'] = otherController.text.trim();

      await FirebaseFirestore.instance.collection('trainers').doc(_profileTrainer!.id).update({'socialLinks': newLinks});
      _loadProfile();
    }
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

// --- Render Widgets ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_profileTrainer == null) return const Scaffold(body: Center(child: Text('Trainer not found.')));

    final trainer = _profileTrainer!;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Light professional background
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(bottom: 60),
                  child: trainer.coverImage != null && trainer.coverImage!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: trainer.coverImage!, fit: BoxFit.cover)
                      : const Center(child: Icon(Icons.fitness_center, color: Colors.grey, size: 60)),
                ),
                Positioned(
                  top: 40,
                  right: 16,
                  child: Row(
                    children: [
                      if (_isOwner) ...[
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.black87, size: 20),
                            onPressed: _showImageEditOptions,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                            onPressed: _deleteAccount,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                                  content: Text('Are you sure you want to logout?', style: GoogleFonts.inter(color: AppColors.textMuted)),
                                  actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text('Logout', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                )
                              );
                              if (confirm == true) {
                                await FirebaseAuth.instance.signOut();
                                if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (r) => false);
                              }
                            },
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: trainer.profileImage.isNotEmpty ? CachedNetworkImageProvider(trainer.profileImage) : null,
                      child: trainer.profileImage.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                    ),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(trainer.name, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text('@${trainer.username}', style: GoogleFonts.inter(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),

                  // ── Follower Count (real-time, tappable) ───────────────
                  StreamBuilder<int>(
                    stream: FollowService().followerCountStream(trainer.id),
                    builder: (ctx, snap) {
                      final count = snap.data ?? 0;
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrainerFollowersScreen(
                              trainerId: trainer.id,
                              trainerName: trainer.name,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_alt_outlined, size: 15, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Text(
                                '$count ${count == 1 ? 'Follower' : 'Followers'}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // ── Follow / Following button (non-owner only) ─────────
                  if (!_isOwner) ...[  
                    const SizedBox(height: 12),
                    StreamBuilder<bool>(
                      stream: FollowService().isFollowingStream(trainer.id),
                      builder: (ctx, snap) {
                        final isFollowing = snap.data ?? false;
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: isFollowing
                              ? OutlinedButton.icon(
                                  key: const ValueKey('following'),
                                  onPressed: () => FollowService().unfollow(trainer.id),
                                  icon: const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                                  label: Text('Following', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  key: const ValueKey('follow'),
                                  onPressed: () => FollowService().follow(trainer.id),
                                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: Colors.white),
                                  label: Text('Follow', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                                  ),
                                ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 24),
                  
                  // Small Cards UI
                  _buildDetailCard('Bio', 'bio', trainer.bio, Icons.person_outline),
                  _buildDetailCard('Experience', 'experience', trainer.experience, Icons.work_outline),
                  _buildDetailCard('Address', 'address', trainer.address, Icons.location_on_outlined),
                  
                  const SizedBox(height: 16),
                  _buildCertificationsSection(trainer),
                  
                  const SizedBox(height: 16),
                  _buildSocialLinksSection(trainer),
                  
                  // Posts section (only shown when viewing someone else's profile)
                  if (!_isOwner) ..._postsSectionWidgets(trainer.id),
                  
                  const SizedBox(height: 50),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _postsSectionWidgets(String trainerId) {
    return [
      const SizedBox(height: 24),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Text('Posts', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      ),
      const SizedBox(height: 12),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('trainerId', isEqualTo: trainerId)
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No posts yet.', style: GoogleFonts.inter(color: Colors.grey, fontStyle: FontStyle.italic)),
          );
          final posts = docs.map((d) => TrainerPostModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return Column(children: posts.map((p) => TrainerPostCard(key: ValueKey(p.id), post: p)).toList());
        },
      ),
    ];
  }

  Widget _buildDetailCard(String title, String fieldKey, String? value, IconData icon) {
    if (!_isOwner && (value == null || value.isEmpty)) return const SizedBox.shrink();

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                  ],
                ),
                if (_isOwner)
                  InkWell(
                    onTap: () => _editDetailField(title, fieldKey, value ?? ''),
                    child: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                  )
              ],
            ),
            if (value != null && value.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(value, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500, height: 1.4)),
            ] else if (_isOwner) ...[
              const SizedBox(height: 8),
              Text('Tap edit to add your $title', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationsSection(TrainerModel trainer) {
    final certs = trainer.certificateImages ?? [];
    if (!_isOwner && certs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Certifications', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_isOwner)
              TextButton.icon(
                onPressed: _uploadCertificate,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              )
          ],
        ),
        if (certs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('No certificates uploaded yet.', style: GoogleFonts.inter(color: Colors.grey, fontStyle: FontStyle.italic)),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: certs.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12, top: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(image: CachedNetworkImageProvider(certs[index]), fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSocialLinksSection(TrainerModel trainer) {
    final links = trainer.socialLinks ?? {};
    if (!_isOwner && links.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Social Links', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                if (_isOwner)
                  InkWell(
                    onTap: _editSocialLinks,
                    child: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                  )
              ],
            ),
            const SizedBox(height: 16),
            if (links.isEmpty)
               Text('No social links provided.', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic))
            else
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   if (links['instagram'] != null)
                     IconButton(icon: const Icon(Icons.camera_alt_outlined, color: Colors.purple), onPressed: () => _launchURL(links['instagram']!)),
                   if (links['facebook'] != null)
                     IconButton(icon: const Icon(Icons.facebook, color: Colors.blue), onPressed: () => _launchURL(links['facebook']!)),
                   if (links['other'] != null)
                     IconButton(icon: const Icon(Icons.link, color: Colors.black87), onPressed: () => _launchURL(links['other']!)),
                 ],
               )
          ],
        ),
      ),
    );
  }
}
