import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitora/core/utils/cloudinary_upload.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fitora/core/constants/app_colors.dart';
import 'package:fitora/widgets/profile_header.dart';
import 'package:fitora/widgets/settings_tile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitora/core/services/account_deletion_service.dart';
import 'package:fitora/routes/app_routes.dart';
import '../../trainer/services/follow_service.dart';
import 'package:fitora/screens/member/following_list_screen.dart';

class MemberProfile extends StatefulWidget {
  const MemberProfile({super.key});

  @override
  State<MemberProfile> createState() => _MemberProfileState();
}

class _MemberProfileState extends State<MemberProfile> {
  String memberName = '';
  String gymName = '';
  String phone = '';
  String gymId = '';
  String? posterUrl;
  String? avatarUrl;
  bool _loading = true;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      final data = userDoc.data();
      if (data != null) {
        final gId = data['gymId'] as String? ?? '';
        final gymDoc = await FirebaseFirestore.instance.collection('gyms').doc(gId).get();
        if (mounted) {
          setState(() {
            gymId = gId;
            memberName = data['name'] as String? ?? 'Member';
            phone = data['phone'] as String? ?? '';
            posterUrl = data['posterUrl'] as String?;
            avatarUrl = data['avatarUrl'] as String?;
            gymName = gymDoc.data()?['name'] as String? ?? 'Your Gym';
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (_) => false);
  }

  void _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text(
          'Are you sure? This will permanently delete your profile, media, and all your follows. This action cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && _uid != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      try {
        await AccountDeletionService.deleteMemberData(_uid!);
        if (mounted) {
          Navigator.pop(context); // Pop loading
          Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }

  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: memberName);
    bool saving = false;
    File? newPosterFile;
    File? newAvatarFile;
    bool isAvatarUploading = false;
    bool isPosterUploading = false;

    Future<void> pickImage(bool isPoster, StateSetter setSheetState) async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        setSheetState(() {
          if (isPoster) {
            newPosterFile = File(picked.path);
            isPosterUploading = true;
          } else {
            newAvatarFile = File(picked.path);
            isAvatarUploading = true;
          }
        });

        File uploadFile = File(picked.path);
        try {
          final url = await CloudinaryService.uploadImage(uploadFile);
          if (url != null) {
            if (_uid != null) {
              await FirebaseFirestore.instance.collection('users').doc(_uid).update({
                isPoster ? 'posterUrl' : 'avatarUrl': url,
              });
            }
            if (mounted) {
              setState(() {
                if (isPoster) {
                  posterUrl = url;
                } else {
                  avatarUrl = url;
                }
              });
            }
          } else {
            throw Exception('Upload failed');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${isPoster ? 'Poster' : 'Avatar'} upload failed. Please try again.', style: GoogleFonts.inter(color: Colors.white)),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ));
          }
          if (isPoster) {
            newPosterFile = null;
          } else {
            newAvatarFile = null;
          }
        } finally {
          try {
            setSheetState(() {
              if (isPoster) {
                isPosterUploading = false;
              } else {
                isAvatarUploading = false;
              }
            });
          } catch (_) {}
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 20),
                Text('Edit Profile', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => pickImage(false, setSheetState),
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                            image: newAvatarFile != null 
                              ? DecorationImage(image: FileImage(newAvatarFile!), fit: BoxFit.cover)
                              : (avatarUrl != null && avatarUrl!.isNotEmpty) 
                                ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover) : null,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (newAvatarFile == null && (avatarUrl == null || avatarUrl!.isEmpty))
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 28),
                                    const SizedBox(height: 8),
                                    Text('Avatar', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              if (newAvatarFile != null || (avatarUrl != null && avatarUrl!.isNotEmpty))
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isAvatarUploading)
                                        const CircularProgressIndicator(color: AppColors.primary)
                                      else ...[
                                        const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
                                        const SizedBox(height: 4),
                                        Text('Edit Avatar', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => pickImage(true, setSheetState),
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                            image: newPosterFile != null 
                              ? DecorationImage(image: FileImage(newPosterFile!), fit: BoxFit.cover)
                              : (posterUrl != null && posterUrl!.isNotEmpty) 
                                ? DecorationImage(image: NetworkImage(posterUrl!), fit: BoxFit.cover) : null,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (newPosterFile == null && (posterUrl == null || posterUrl!.isEmpty))
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 28),
                                    const SizedBox(height: 8),
                                    Text('Poster', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              if (newPosterFile != null || (posterUrl != null && posterUrl!.isNotEmpty))
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isPosterUploading)
                                        const CircularProgressIndicator(color: AppColors.primary)
                                      else ...[
                                        const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
                                        const SizedBox(height: 4),
                                        Text('Edit Poster', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                _editField(nameCtrl, 'Full Name', Icons.person_rounded),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      setSheetState(() => saving = true);
                      try {
                        if (_uid != null) {
                          await FirebaseFirestore.instance.collection('users').doc(_uid).update({
                            'name': nameCtrl.text.trim(),
                          });
                        }

                        setState(() {
                          memberName = nameCtrl.text.trim();
                        });
                        
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Profile updated successfully!', style: GoogleFonts.inter()),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        );
                      } catch (e) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Database update failed. Check connection.', style: GoogleFonts.inter(color: Colors.white)),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        );
                      }
                      try { setSheetState(() => saving = false); } catch (_) {}
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: saving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true, fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Color(0xFF0A0A0A), body: Center(child: CircularProgressIndicator(color: AppColors.primary)));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileHeader(
              posterUrl: posterUrl,
              avatarUrl: avatarUrl,
              placeholderInitial: memberName.isNotEmpty ? memberName[0].toUpperCase() : 'M',
              onEdit: _showEditProfile,
              onDelete: _deleteAccount,
              onLogout: _signOut,
            ),
            const SizedBox(height: 40),

            // Member Name Centered=========================================================
            Transform.translate(
  offset: const Offset(0, -40), // 👈 jitna upar chahiye (-60, -80 kar sakte ho)
  child: Center(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              memberName,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'GYM MEMBER',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF10B981),
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    ),
  ),
),
            
            // Info Boxes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                   _infoBox(Icons.storefront_rounded, 'Gym', gymName),
                   const SizedBox(height: 12),
                   _infoBox(Icons.vpn_key_rounded, 'Gym ID', gymId, showCopy: true),
                   const SizedBox(height: 12),
                   _infoBox(Icons.phone_rounded, 'Contact', phone),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // ── Following Trainers Section ─────────────────────────
            if (_uid != null) _buildFollowingSection(),

            const SizedBox(height: 40),
            
            // Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 16),
                  SettingsTile(icon: Icons.shield_rounded, title: 'Privacy Policy', onTap: () => Navigator.pushNamed(context, '/settings/privacy')),
                  SettingsTile(icon: Icons.description_rounded, title: 'Terms & Conditions', onTap: () => Navigator.pushNamed(context, '/settings/terms')),
                  SettingsTile(icon: Icons.help_outline_rounded, title: 'Help & Support', onTap: () => Navigator.pushNamed(context, '/settings/help')),
                  SettingsTile(icon: Icons.info_outline_rounded, title: 'About App', onTap: () => Navigator.pushNamed(context, '/settings/about')),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Footer
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120),
                child: Text(
                  'Made by A Cube Technology',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyGymId() {
    // Assuming you want the member to easily copy the joined Gym ID
    Clipboard.setData(ClipboardData(text: gymId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gym ID copied!', style: GoogleFonts.inter()),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _infoBox(IconData icon, String title, String value, {bool showCopy = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value.isEmpty ? '---' : value, style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (showCopy)
            GestureDetector(
              onTap: _copyGymId,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  // ── Following Trainers Section ────────────────────────────────
  Widget _buildFollowingSection() {
    final followsStream = FirebaseFirestore.instance
        .collection('follows')
        .where('followerId', isEqualTo: _uid)
        .snapshots(); // No orderBy → no composite index needed

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: StreamBuilder<QuerySnapshot>(
        stream: followsStream,
        builder: (ctx, snap) {
          final count = snap.data?.docs.length ?? 0;

          return InkWell(
            onTap: () {
              if (_uid != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FollowingListScreen(followerId: _uid!)),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Following Trainers', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          '$count trainers',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
