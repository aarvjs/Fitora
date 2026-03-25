import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitora/core/constants/app_colors.dart';
import 'package:fitora/screens/owner/staff_list_screen.dart';
import 'package:fitora/screens/owner/trainer_list_screen.dart';
import 'package:fitora/screens/owner/video_list_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OwnerHome extends StatefulWidget {
  const OwnerHome({super.key});

  @override
  State<OwnerHome> createState() => _OwnerHomeState();
}

class _OwnerHomeState extends State<OwnerHome> {
  String gymName = '';
  String gymId = '';
  String profileImage = '';
  String gymPosterUrl = '';
  bool _loading = true;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  
  // Slider auto-play
  final PageController _pageController = PageController();
  Timer? _sliderTimer;
  int _currentSliderQuery = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentSliderQuery = (_currentSliderQuery + 1) % 2;
        _pageController.animateToPage(
          _currentSliderQuery,
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _salaryCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = userDoc.data();
      if (data != null) {
        final gId = data['gymId'] as String? ?? '';
        final gymDoc =
            await FirebaseFirestore.instance.collection('gyms').doc(gId).get();
        final gymData = gymDoc.data();
        final gPosterUrl = gymData?['posterUrl'] as String? ?? '';
        final pImg = data['profileImage'] as String? ??
            data['avatarUrl'] as String? ??
            gymData?['avatarUrl'] as String? ??
            gymData?['profileImage'] as String? ??
            '';
        if (mounted) {
          setState(() {
            gymId = gId;
            gymName = gymData?['name'] as String? ?? 'Your Gym';
            profileImage = pImg;
            gymPosterUrl = gPosterUrl;
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Slider
            SliverToBoxAdapter(child: _buildGymSlider()),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Stats
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(child: _label('Stats')),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _buildStatsRow()),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Quick Actions
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(child: _label('Quick Actions')),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _buildQuickActions()),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Videos
            SliverToBoxAdapter(child: _buildVideoSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Staff
            SliverToBoxAdapter(child: _buildStaffSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Trainers
            SliverToBoxAdapter(child: _buildTrainerSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Announcements
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(child: _label('Announcements')),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _buildAnnouncementsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),

            // Banner
            SliverToBoxAdapter(child: _buildFinalBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Header (PRESERVED)
  // ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    final today = DateFormat('EEEE, d MMM').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4), width: 2),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ClipOval(
              child: profileImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: profileImage,
                      fit: BoxFit.cover,
                      width: 52,
                      height: 52,
                      placeholder: (context, url) => Container(
                          color: AppColors.surface,
                          padding: const EdgeInsets.all(12),
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary)),
                      errorWidget: (context, url, error) => _defaultAvatar(),
                    )
                  : _defaultAvatar(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gymName,
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('Active · Owner',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(today,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _showUploadVideoDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_rounded,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text('Video',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() => Container(
      color: AppColors.surface,
      child: const Icon(Icons.person_rounded,
          color: AppColors.textMuted, size: 26));

  void _showUploadVideoDialog() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile == null) return;
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 20),
            Text('Uploading Video...', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Please keep the app open.', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );

    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/dnba3dkxk/video/upload");
      var request = http.MultipartRequest("POST", url);
      request.fields['upload_preset'] = "fitora_upload";
      request.fields['resource_type'] = "video";
      request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);
      
      if (response.statusCode == 200) {
        var data = json.decode(responseData.body);
        String videoUrl = data['secure_url'];
        
        await FirebaseFirestore.instance.collection('videos').add({
          'gymId': gymId,
          'videoUrl': videoUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Video uploaded successfully!'),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        throw Exception('Upload failed: ${responseData.body}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        String errStr = e.toString();
        if (errStr.startsWith('Exception: ')) {
          errStr = errStr.substring('Exception: '.length);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $errStr', maxLines: 2, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ));
      }
    }
  }

  // ─────────────────────────────────────────────────────
  // GYM SLIDER (PREMIUM DESIGN)
  // ─────────────────────────────────────────────────────
  Widget _buildGymSlider() {
    return SizedBox(
      height: 200,
      child: PageView(
        controller: _pageController,
        padEnds: false,
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Card 1: Gym Identity Card
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ALWAYS USE ASSET FOR SLIDER 1
                Image.asset('assets/gym_slider_bg.png', fit: BoxFit.cover),
                // Dark gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                ),
                // Text content at bottom
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('YOUR GYM',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      letterSpacing: 2.5,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text(gymName,
                                  style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.1),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text('ID: $gymId',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2)),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: gymId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gym ID copied!',
                                    style: GoogleFonts.inter()),
                                backgroundColor: Colors.black87,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                margin: const EdgeInsets.all(20),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.5))),
                            child: const Icon(Icons.copy_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Card 2: Motivational Card with asset image
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Generated motivation background
                Image.asset('assets/gym_motivation_bg.png', fit: BoxFit.cover),
                // Dark overlay for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.black.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bolt_rounded,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(height: 14),
                      Text('Push Hard 💪',
                          style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Text(
                          'Great leadership builds\ngreat gyms.',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.5,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gymGradientBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A00), Color(0xFF2A1800), Color(0xFF0A0A0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16, left: 16,
            child: Icon(Icons.fitness_center_rounded,
                color: AppColors.primary.withValues(alpha: 0.08), size: 120),
          ),
          Positioned(
            bottom: 10, right: 10,
            child: Icon(Icons.sports_gymnastics_rounded,
                color: Colors.white.withValues(alpha: 0.04), size: 80),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // STATS SECTION (REAL-TIME, 3 CARDS)
  // ─────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    if (gymId.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('staff')
            .where('gymId', isEqualTo: gymId)
            .snapshots(),
        builder: (ctx, staffSnap) {
          final staffCount = staffSnap.data?.docs.length ?? 0;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('plans')
                .where('gymId', isEqualTo: gymId)
                .snapshots(),
            builder: (ctx2, planSnap) {
              final activePlans = planSnap.data?.docs.length ?? 0;
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('gymId', isEqualTo: gymId)
                    .where('role', isEqualTo: 'member')
                    .snapshots(),
                builder: (ctx3, memberSnap) {
                  final totalMembers = memberSnap.data?.docs.length ?? 0;
                  return Row(
                    children: [
                      Expanded(
                          child: _statCard(Icons.group_rounded, 'Members',
                              '$totalMembers', AppColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statCard(
                              Icons.card_membership_rounded, 'Active Plans',
                              '$activePlans', const Color(0xFF10B981))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statCard(
                              Icons.badge_rounded, 'Staff',
                              '$staffCount', const Color(0xFF8B5CF6))),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _statCard(
      IconData icon, String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // QUICK ACTIONS (HORIZONTAL SCROLL + MODALS)
  // ─────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.person_add_rounded,
        'label': 'Add Staff',
        'sub': 'Manage team',
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFF052E1C),
        'onTap': () => _showPersonModal('staff'),
      },
      {
        'icon': Icons.campaign_rounded,
        'label': 'Announcement',
        'sub': 'Notify members',
        'color': const Color(0xFFEAB308),
        'bg': const Color(0xFF1F1500),
        'onTap': () => _showAnnouncementModal(),
      },
      {
        'icon': Icons.sports_rounded,
        'label': 'Add Trainer',
        'sub': 'Internal team',
        'color': const Color(0xFF0EA5E9),
        'bg': const Color(0xFF051525),
        'onTap': () => _showPersonModal('gym_trainers'),
      },
    ];

    return SizedBox(
      height: 118,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: actions.length,
        itemBuilder: (_, i) {
          final a = actions[i];
          final color = a['color'] as Color;
          final bg = a['bg'] as Color;
          return GestureDetector(
            onTap: a['onTap'] as VoidCallback,
            child: Container(
              width: 110,
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(a['icon'] as IconData, color: color, size: 20),
                  ),
                  const Spacer(),
                  Text(a['label'] as String,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                      maxLines: 1),
                  Text(a['sub'] as String,
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          color: color.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Modal: Add Staff / Add Trainer
  void _showPersonModal(String collection) {
    _nameCtrl.clear();
    _phoneCtrl.clear();
    _addressCtrl.clear();
    _salaryCtrl.clear();
    final isStaff = collection == 'staff';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
              0, 0, 0, MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: const BoxDecoration(
              color: Color(0xFF141414),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4))),
                ),
                const SizedBox(height: 20),
                Text(isStaff ? 'Add Staff Member' : 'Add Internal Trainer',
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 20),
                _inputField(_nameCtrl, 'Full Name', Icons.person_outline_rounded),
                const SizedBox(height: 12),
                _inputField(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
                    type: TextInputType.phone),
                const SizedBox(height: 12),
                _inputField(_addressCtrl, 'Address', Icons.location_on_outlined),
                const SizedBox(height: 12),
                _inputField(_salaryCtrl, 'Monthly Salary (₹)',
                    Icons.currency_rupee_rounded,
                    type: TextInputType.number),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      if (_nameCtrl.text.trim().isEmpty ||
                          _phoneCtrl.text.trim().isEmpty) { return; }
                      final nav = Navigator.of(ctx);
                      await FirebaseFirestore.instance
                          .collection(collection)
                          .add({
                        'name': _nameCtrl.text.trim(),
                        'phone': _phoneCtrl.text.trim(),
                        'address': _addressCtrl.text.trim(),
                        'salary': _salaryCtrl.text.trim(),
                        'gymId': gymId,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      nav.pop();
                    },
                    child: Text('Save',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Modal: Announcement
  void _showAnnouncementModal() {
    _msgCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.fromLTRB(0, 0, 0, MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(height: 20),
              Text('New Announcement',
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: TextField(
                  controller: _msgCtrl,
                  maxLines: 4,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAB308),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    if (_msgCtrl.text.trim().isEmpty) return;
                    final nav = Navigator.of(ctx);
                    final now = DateTime.now();
                    await FirebaseFirestore.instance
                        .collection('announcements')
                        .add({
                      'message': _msgCtrl.text.trim(),
                      'gymId': gymId,
                      'createdAt': FieldValue.serverTimestamp(),
                      'date': DateFormat('MMM d, yyyy').format(now),
                      'time': DateFormat('h:mm a').format(now),
                    });
                    nav.pop();
                  },
                  child: Text('Post Announcement',
                      style: GoogleFonts.inter(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // VIDEO SECTION
  // ─────────────────────────────────────────────────────
  Widget _buildVideoSection() {
    if (gymId.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label('Latest Videos'),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoListScreen(gymId: gymId),
                    ),
                  );
                },
                child: Text('View All',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 155,
          child: StreamBuilder<QuerySnapshot>(
            // No compound orderBy – sort locally to avoid index requirement
            stream: FirebaseFirestore.instance
                .collection('videos')
                .where('gymId', isEqualTo: gymId)
                .limit(10)
                .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Could not load videos.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary)),
                );
              }
              final rawDocs = snap.data?.docs ?? [];
              // Sort locally by createdAt descending
              final docs = rawDocs.toList()
                ..sort((a, b) {
                  final at = (a.data() as Map)['createdAt'] as Timestamp?;
                  final bt = (b.data() as Map)['createdAt'] as Timestamp?;
                  if (at == null && bt == null) return 0;
                  if (at == null) return 1;
                  if (bt == null) return -1;
                  return bt.compareTo(at);
                });
              final limited = docs.take(3).toList();
              if (limited.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_off_rounded,
                            color: AppColors.textMuted, size: 32),
                        const SizedBox(height: 10),
                        Text('No videos uploaded yet',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                itemCount: limited.length,
                separatorBuilder: (ctx, idx) => const SizedBox(width: 16),
                itemBuilder: (ctx, idx) {
                  final data = limited[idx].data() as Map<String, dynamic>;
                  final String videoUrl = data['videoUrl'] ?? '';
                  final String docId = limited[idx].id;

                  return SizedBox(
                    width: 260,
                    child: VideoFeedItem(
                      videoUrl: videoUrl,
                      videoId: docId,
                      isCompact: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // STAFF SECTION
  // ─────────────────────────────────────────────────────
  Widget _buildStaffSection() {
    if (gymId.isEmpty) return const SizedBox.shrink();
    return _personSection(
      title: 'Staff',
      collection: 'staff',
      accentColor: const Color(0xFF10B981),
    );
  }

  // ─────────────────────────────────────────────────────
  // TRAINER SECTION
  // ─────────────────────────────────────────────────────
  Widget _buildTrainerSection() {
    if (gymId.isEmpty) return const SizedBox.shrink();
    return _personSection(
      title: 'Trainers',
      collection: 'gym_trainers',
      accentColor: const Color(0xFF0EA5E9),
    );
  }

  Widget _personSection({
    required String title,
    required String collection,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label(title),
              GestureDetector(
                onTap: () {
                  if (collection == 'staff') {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => StaffListScreen(gymId: gymId),
                    ));
                  } else {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TrainerListScreen(gymId: gymId),
                    ));
                  }
                },
                child: Text('View All',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 145,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(collection)
                .where('gymId', isEqualTo: gymId)
                .limit(5)
                .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('No $title added yet.',
                      style:
                          GoogleFonts.inter(color: AppColors.textSecondary)),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final id = docs[i].id;
                  final name = d['name'] as String? ?? title;
                  final phone = d['phone'] as String? ?? '';
                  final salary = d['salary']?.toString() ?? '0';
                  return Container(
                    width: 148,
                    margin: const EdgeInsets.only(right: 14),
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                            color: accentColor.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar initials
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  accentColor.withValues(alpha: 0.15),
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(name,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            if (phone.isNotEmpty)
                              Text(phone,
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.textMuted),
                                  maxLines: 1),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text('₹$salary',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: accentColor,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => _confirmDelete(collection, id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // ANNOUNCEMENTS SECTION (WITH DATE + TIME)
  // ─────────────────────────────────────────────────────
  Widget _buildAnnouncementsSection() {
    if (gymId.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: StreamBuilder<QuerySnapshot>(
        // No compound orderBy – sort locally to avoid Firestore index requirement
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .where('gymId', isEqualTo: gymId)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final rawDocs = snap.data?.docs ?? [];
          // Sort locally newest first
          final docs = rawDocs.toList()
            ..sort((a, b) {
              final at = (a.data() as Map)['createdAt'] as Timestamp?;
              final bt = (b.data() as Map)['createdAt'] as Timestamp?;
              if (at == null && bt == null) return 0;
              if (at == null) return 1;
              if (bt == null) return -1;
              return bt.compareTo(at);
            });
          final limited = docs.take(5).toList();
          if (limited.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider)),
              child: Row(
                children: [
                  const Icon(Icons.campaign_outlined,
                      color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Text('No announcements posted yet.',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return Column(
            children: limited.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              final msg = d['message'] as String? ?? '';
              final ts = d['createdAt'] as Timestamp?;
              final dateStr = d['date'] as String? ??
                  (ts != null ? DateFormat('MMM d, yyyy').format(ts.toDate()) : '');
              final timeStr = d['time'] as String? ??
                  (ts != null ? DateFormat('h:mm a').format(ts.toDate()) : '');
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.campaign_rounded,
                          color: Color(0xFFEAB308), size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg,
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5)),
                          if (dateStr.isNotEmpty || timeStr.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    color: AppColors.textMuted, size: 11),
                                const SizedBox(width: 4),
                                Text(dateStr,
                                    style: GoogleFonts.inter(
                                        color: AppColors.textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 10),
                                const Icon(Icons.access_time_rounded,
                                    color: AppColors.textMuted, size: 11),
                                const SizedBox(width: 4),
                                Text(timeStr,
                                    style: GoogleFonts.inter(
                                        color: AppColors.textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Delete Button
                    GestureDetector(
                      onTap: () => _confirmDeleteAnnouncement(docId),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent, size: 16),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _confirmDeleteAnnouncement(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Announcement',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Remove this announcement?',
            style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              FirebaseFirestore.instance.collection('announcements').doc(docId).delete();
            },
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // DELETE CONFIRMATION
  // ─────────────────────────────────────────────────────
  void _confirmDelete(String collection, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm Delete',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to remove this record?',
            style:
                GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: AppColors.textMuted))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              FirebaseFirestore.instance.collection(collection).doc(docId).delete();
            },
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // FINAL BANNER
  // ─────────────────────────────────────────────────────
  Widget _buildFinalBanner() {
    return Column(
      children: [
        Container(
          height: 155,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Premium generated background
              Image.asset('assets/gym_final_banner.png', fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          color: AppColors.primary, size: 30),
                    ),
                    const SizedBox(height: 12),
                    Text('TAKE YOUR GYM TO THE NEXT LEVEL',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text('Stay strong. Stay consistent.',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white60,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Made by A Cube Technology',
          style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────
  Widget _label(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white));
  }
}
