import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitora/core/constants/app_colors.dart';

class MemberHome extends StatefulWidget {
  const MemberHome({super.key});

  @override
  State<MemberHome> createState() => _MemberHomeState();
}

class _MemberHomeState extends State<MemberHome> {
  String memberName = '';
  String gymName = '';
  String gymId = '';
  String profileImage = '';
  String gymPosterUrl = '';
  String ownerProfileImage = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = userDoc.data();
      if (data != null) {
        final gId = data['gymId'] as String? ?? '';
        final pImg = data['profileImage'] as String? ?? data['avatarUrl'] as String? ?? '';
        
        final gymDoc = await FirebaseFirestore.instance.collection('gyms').doc(gId).get();
        final gymData = gymDoc.data();

        // Fetch Gym Owner Profile Image
        final ownerQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('gymId', isEqualTo: gId)
            .where('role', isEqualTo: 'owner')
            .limit(1)
            .get();
        
        String ownerImg = gymData?['avatarUrl'] as String? ?? gymData?['profileImage'] as String? ?? '';
        if (ownerImg.isEmpty && ownerQuery.docs.isNotEmpty) {
          final ownerData = ownerQuery.docs.first.data();
          ownerImg = ownerData['profileImage'] as String? ?? ownerData['avatarUrl'] as String? ?? '';
        }

        if (mounted) {
          setState(() {
            memberName = data['name'] as String? ?? 'Member';
            profileImage = pImg;
            gymId = gId;
            gymName = gymData?['name'] as String? ?? 'Your Gym';
            gymPosterUrl = gymData?['posterUrl'] as String? ?? '';
            ownerProfileImage = ownerImg;
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.surface,
      child: const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 28),
                    _buildGymSlider(),
                    const SizedBox(height: 28),
                    _buildMotivationCard(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Today'),
                    const SizedBox(height: 16),
                    _buildTodayTile(
                      icon: Icons.fitness_center_rounded,
                      title: 'Morning Workout',
                      subtitle: 'Upper body · 60 min',
                      time: '7:00 AM',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memberName,
                style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white,
                  height: 1.1, letterSpacing: -0.5,
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Gym Member · Active',
                    style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Member Profile Avatar
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4), width: 2),
            boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ClipOval(
            child: profileImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: profileImage,
                    fit: BoxFit.cover,
                    width: 52, height: 52,
                    placeholder: (context, url) => Container(color: AppColors.surface, padding: const EdgeInsets.all(12), child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)),
                    errorWidget: (context, url, error) => _defaultAvatar(),
                  )
                : _defaultAvatar(),
          ),
        ),
      ],
    );
  }

  Widget _buildGymSlider() {
    return SizedBox(
      height: 160,
      child: PageView(
        controller: PageController(viewportFraction: 0.95),
        padEnds: false,
        physics: const BouncingScrollPhysics(),
        children: [
          // CARD 1: Gym Owner Info (Half Image, Half Text)
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white, // Requested white background
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.1)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            clipBehavior: Clip.antiAlias, // Important to clip the half-image perfectly
            child: Row(
              children: [
                // Left Half: Image
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: double.infinity,
                    child: ownerProfileImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ownerProfileImage,
                            fit: BoxFit.cover,
                            errorWidget: (ctx, url, err) => Container(color: AppColors.surface, child: const Center(child: Icon(Icons.storefront_rounded, color: AppColors.textMuted, size: 40))),
                          )
                        : Container(color: AppColors.surface, child: const Center(child: Icon(Icons.storefront_rounded, color: AppColors.textMuted, size: 40))),
                  ),
                ),
                // Right Half: Content & Orange Decoration
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      // Orange decorative shape at the bottom right
                      Positioned(
                        right: -30,
                        bottom: -30,
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: Icon(Icons.fitness_center_rounded, size: 80, color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      // Text Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YOUR GYM', style: GoogleFonts.inter(fontSize: 10, color: AppColors.primary, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(gymName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text('ID: $gymId', style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 1)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // CARD 2: Gym Cover Background
          Container(
            margin: const EdgeInsets.only(right: 4), // less margin for last item
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
              image: gymPosterUrl.isNotEmpty
                  ? DecorationImage(image: CachedNetworkImageProvider(gymPosterUrl), fit: BoxFit.cover)
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: gymPosterUrl.isEmpty
                ? const Center(child: Icon(Icons.image_not_supported_rounded, color: AppColors.textMuted, size: 40))
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.all(24),
                    child: Text('Official Gym Cover', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A00), Color(0xFF2A1200)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Motivation', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  '"Push yourself, because no one else is going to do it for you."',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.bolt_rounded, color: AppColors.secondary, size: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white));
  }

  Widget _buildTodayTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(time, style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
