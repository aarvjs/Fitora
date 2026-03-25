import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:fitora/core/constants/app_colors.dart';
import 'package:fitora/trainer/screens/trainer_profile_screen.dart';
import 'package:fitora/screens/member/member_trainers.dart';
import 'package:fitora/screens/member/member_plan.dart';

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

  // Live clock
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  
  // Streams
  Stream<QuerySnapshot>? _notificationsStream;

  @override
  void initState() {
    super.initState();
    _loadData();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
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
            
            if (gId.isNotEmpty) {
              _notificationsStream = FirebaseFirestore.instance
                  .collection('announcements')
                  .where('gymId', isEqualTo: gId)
                  .snapshots();
            }
            
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
                    // ── EXISTING: Header (DO NOT CHANGE) ────────────────
                    _buildHeader(),
                    const SizedBox(height: 28),

                    // ── EXISTING: Gym Slider (DO NOT CHANGE) ────────────
                    _buildGymSlider(),
                    const SizedBox(height: 28),

                    // ── NEW 1: Gym Notifications ─────────────────────────
                    if (gymId.isNotEmpty) ...[
                      _buildGymNotifications(),
                      const SizedBox(height: 28),
                    ],

                    // ── NEW 2: Quick Actions ─────────────────────────────
                    _buildQuickActions(),
                    const SizedBox(height: 28),

                    // ── NEW 3: Trainer Recommendations ───────────────────
                    _buildTrainerRecommend(),
                    const SizedBox(height: 28),

                    // ── NEW 4: Motivation Banner with Live Clock ──────────
                    _buildMotivationBanner(),
                    const SizedBox(height: 28),

                    // ── EXISTING: Daily Motivation Card ─────────────────
                    _buildMotivationCard(),
                    const SizedBox(height: 28),

                    // ── EXISTING: Today Section ──────────────────────────
                    _buildSectionTitle('Today'),
                    const SizedBox(height: 16),
                    _buildTodayTile(
                      icon: Icons.fitness_center_rounded,
                      title: 'Morning Workout',
                      subtitle: 'Upper body · 60 min',
                      time: '7:00 AM',
                    ),
                    const SizedBox(height: 48),

                    // ── FOOTER ──────────────────────────────────────────
                    Center(
                      child: Text(
                        'Created by A cube Technology',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── EXISTING: Header (unchanged) ────────────────────────────────────
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

  // ── EXISTING: Gym Slider (unchanged) ────────────────────────────────
  Widget _buildGymSlider() {
    return SizedBox(
      height: 160,
      child: PageView(
        controller: PageController(viewportFraction: 0.95),
        padEnds: false,
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.1)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
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
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30, bottom: -30,
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -10, bottom: -10,
                        child: Icon(Icons.fitness_center_rounded, size: 80, color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
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
          Container(
            margin: const EdgeInsets.only(right: 4),
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

  // ── NEW 1: Gym Notifications ─────────────────────────────────────────
  Widget _buildGymNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notifications_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text('Gym Updates', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _notificationsStream,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            final docs = (snap.data?.docs ?? []).toList();
            docs.sort((a, b) {
              final aMap = a.data() as Map<String, dynamic>;
              final bMap = b.data() as Map<String, dynamic>;
              final aTime = aMap['createdAt'] as Timestamp?;
              final bTime = bMap['createdAt'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });
            final limitedDocs = docs.take(3).toList();

            if (limitedDocs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 18),
                    const SizedBox(width: 10),
                    Text('No updates from your gym yet.', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              );
            }
            return Column(
              children: limitedDocs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final msg = d['message'] as String? ?? '';
                final ts = d['createdAt'] as Timestamp?;
                final timeStr = ts != null
                    ? DateFormat('MMM d · h:mm a').format(ts.toDate())
                    : '';
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4)),
                            if (timeStr.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(timeStr, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ── NEW 2: Quick Actions (Timer, Music, My Plan) ─────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.timer_outlined, 'label': 'Timer', 'route': '/timer', 'color': const Color(0xFFFF6B35)},
      {'icon': Icons.music_note_rounded, 'label': 'Music', 'route': '/music', 'color': const Color(0xFF7C3AED)},
      {'icon': Icons.assignment_outlined, 'label': 'My Plan', 'route': null, 'color': const Color(0xFF059669)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 12),
        Row(
          children: actions.map((a) {
            final color = a['color'] as Color;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  final route = a['route'] as String?;
                  if (route != null) {
                    Navigator.pushNamed(context, route);
                  } else {
                    // Navigate to member plan screen
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberPlan()));
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(a['icon'] as IconData, color: color, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a['label'] as String,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── NEW 3: Trainer Recommendations ───────────────────────────────────
  Widget _buildTrainerRecommend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Top Trainers', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            GestureDetector(
              onTap: () {
                // Switch to trainers tab (index 2)
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberTrainers()));
              },
              child: Text('View All', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('trainers')
              .limit(3)
              .get(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return Text('No trainers yet.', style: GoogleFonts.inter(color: AppColors.textSecondary));
            }
            return SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final name = d['name'] as String? ?? 'Trainer';
                  final img = d['profileImage'] as String? ?? '';
                  final tid = docs[i].id;
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrainerProfileScreen(trainerId: tid))),
                    child: Container(
                      width: 95,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFF1E1E1E),
                            backgroundImage: img.isNotEmpty ? CachedNetworkImageProvider(img) : null,
                            child: img.isEmpty
                                ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'T', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white))
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ── NEW 4: Motivation Banner with Live Clock ─────────────────────────
  Widget _buildMotivationBanner() {
    final dateStr = DateFormat('EEEE, MMM d').format(_now);
    final timeStr = DateFormat('h:mm:ss a').format(_now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            image: const DecorationImage(
              image: AssetImage('assets/member_motivation_banner.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.72), Colors.black.withOpacity(0.3)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Stay Consistent 💪', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Date and Time below the image
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr, style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Text(
                    timeStr,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('LIVE', style: GoogleFonts.inter(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── EXISTING: Daily Motivation Card (unchanged) ──────────────────────
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

  // ── EXISTING: Section title (unchanged) ─────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white));
  }

  // ── EXISTING: Today tile (unchanged) ────────────────────────────────
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
