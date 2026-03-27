import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../models/trainer_post_model.dart';
import '../models/trainer_model.dart';
import '../services/trainer_auth_service.dart';
import '../widgets/trainer_post_card.dart';

class TrainerHomeScreen extends StatefulWidget {
  const TrainerHomeScreen({super.key});

  @override
  State<TrainerHomeScreen> createState() => _TrainerHomeScreenState();
}

class _TrainerHomeScreenState extends State<TrainerHomeScreen> {
  final TrainerAuthService _authService = TrainerAuthService();
  TrainerModel? _currentTrainer;

  final PageController _pageController = PageController();
  int _currentSlide = 0;
  Timer? _timer;

  // Stats - real time via stream
  Stream<QuerySnapshot>? _postsStream;

  final List<String> _sliderImages = [
    'assets/images/trainer_slider_1.png',
    'assets/images/trainer_slider_2.png',
    'assets/images/trainer_slider_3.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrainerData();
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _loadTrainerData() async {
    final trainer = await _authService.getCurrentTrainer();
    if (mounted) {
      setState(() {
        _currentTrainer = trainer;
        if (trainer != null) {
          _postsStream = FirebaseFirestore.instance
              .collection('posts')
              .where('trainerId', isEqualTo: trainer.id)
              .snapshots();
        }
      });
    }
  }

  void _startCarouselTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentSlide + 1;
        if (nextPage >= _sliderImages.length) nextPage = 0;
        _pageController.animateToPage(nextPage,
            duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            _buildCarousel(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildStatsCard(),
            const SizedBox(height: 20),
            _buildMotivationalCard(),
            const SizedBox(height: 20),
            _buildRecentPosts(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── 1. AppBar (unchanged profile) ──────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      toolbarHeight: 70,
      title: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[200],
            backgroundImage: _currentTrainer != null && _currentTrainer!.profileImage.isNotEmpty
                ? CachedNetworkImageProvider(_currentTrainer!.profileImage)
                : null,
            child: _currentTrainer == null || _currentTrainer!.profileImage.isEmpty
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Hello,', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              Text(
                _currentTrainer?.name ?? 'Trainer',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. Carousel ─────────────────────────────────────────────────
  Widget _buildCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 185,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentSlide = idx),
            itemCount: _sliderImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  image: DecorationImage(
                    image: AssetImage(_sliderImages[index]),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SmoothPageIndicator(
          controller: _pageController,
          count: _sliderImages.length,
          effect: const ExpandingDotsEffect(
            dotHeight: 6, dotWidth: 6,
            activeDotColor: AppColors.primary,
            dotColor: Color(0xFFD1D5DB),
          ),
        ),
      ],
    );
  }

  // ── 3. Quick Actions Row ─────────────────────────────────────────
  Widget _buildQuickActions() {
    final actionDefs = [
      {'icon': Icons.add_box_outlined,       'label': 'Create Post',   'mode': ''},
      {'icon': Icons.photo_camera_outlined,  'label': 'Upload Photo',  'mode': 'photo'},
      {'icon': Icons.videocam_outlined,      'label': 'Upload Video',  'mode': 'video'},
      {'icon': Icons.article_outlined,       'label': 'Write Article', 'mode': 'article'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Quick Actions', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: actionDefs.length,
            itemBuilder: (_, i) {
              final item = actionDefs[i];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/trainer-post-create',
                  arguments: item['mode'] as String,
                ),
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item['icon'] as IconData, color: AppColors.primary, size: 26),
                      const SizedBox(height: 6),
                      Text(
                        item['label'] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 4. Stats Card ────────────────────────────────────────────────
  Widget _buildStatsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Stats', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _postsStream,
              builder: (ctx, snap) {
                int totalPosts = 0, totalLikes = 0, totalComments = 0;
                if (snap.hasData) {
                  for (final doc in snap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    totalPosts++;
                    totalLikes += (d['likesCount'] as int? ?? 0);
                    totalComments += (d['commentsCount'] as int? ?? 0);
                  }
                }
                final loaded = snap.hasData;
                return Row(
                  children: [
                    _statItem(loaded ? '$totalPosts' : '--', 'Posts', Icons.grid_on_rounded),
                    _statDivider(),
                    _statItem(loaded ? '$totalLikes' : '--', 'Likes', Icons.favorite_rounded),
                    _statDivider(),
                    _statItem(loaded ? '$totalComments' : '--', 'Comments', Icons.chat_bubble_rounded),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(height: 48, width: 1, color: Colors.grey[200]);
  }

  // ── 5. Motivational Card ─────────────────────────────────────────
  Widget _buildMotivationalCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4))],
          image: const DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff?q=80&w=1469&auto=format&fit=crop',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.55), Colors.black.withOpacity(0.2)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Stay Strong 💪',
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Inspire your clients every single day.',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 6. Recent Posts ──────────────────────────────────────────────
  Widget _buildRecentPosts() {
    if (_currentTrainer == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Posts', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
              GestureDetector(
                // Navigate to Activity tab (index 3 in dashboard)
                onTap: () {},
                child: Text('View All', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('trainerId', isEqualTo: _currentTrainer!.id)
              .limit(2)
              .snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: Center(child: Text('No posts yet. Create your first post!', style: GoogleFonts.inter(color: Colors.grey[500]))),
                ),
              );
            }
            final posts = docs.map((d) => TrainerPostModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
            posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: posts.map((p) => TrainerPostCard(key: ValueKey(p.id), post: p)).toList()),
            );
          },
        ),
      ],
    );
  }
}
