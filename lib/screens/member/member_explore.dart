import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:fitora/core/constants/app_colors.dart';
import 'package:fitora/widgets/product_card.dart';

class MemberExplore extends StatefulWidget {
  const MemberExplore({super.key});

  @override
  State<MemberExplore> createState() => _MemberExploreState();
}

class _MemberExploreState extends State<MemberExplore> {
  String? _gymId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGymId();
  }

  Future<void> _loadGymId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (mounted) {
        setState(() {
          _gymId = doc.data()?['gymId'] as String?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Explore', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                                if (_gymId != null)
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: _gymId!));
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Gym ID copied!', style: GoogleFonts.inter(color: Colors.white)),
                                        backgroundColor: const Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ));
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Gym: $_gymId', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.divider)),
                            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Image Slider
                    _GymImageSlider(gymId: _gymId ?? ''),
                    const SizedBox(height: 28),

                    // Plans Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Membership Plans', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    if (_gymId != null) _PlansRow(gymId: _gymId!),
                    const SizedBox(height: 28),

                    // Products Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Shop & Supplements', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.75,
                        children: const [
                          ProductCard(name: 'Whey Protein', price: '4500', imageUrl: 'https://plus.unsplash.com/premium_photo-1664302152996-03fcb53a0dd5?auto=format&fit=crop&q=80&w=300'),
                          ProductCard(name: 'Creatine', price: '1200', imageUrl: 'https://images.unsplash.com/photo-1593095948071-474c5cc2989d?auto=format&fit=crop&q=80&w=300'),
                          ProductCard(name: 'Power Belt', price: '850', imageUrl: 'https://images.unsplash.com/photo-1600881333168-2ef49b341f30?auto=format&fit=crop&q=80&w=300'),
                          ProductCard(name: 'Gym Gloves', price: '450', imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&q=80&w=300'),
                          ProductCard(name: 'Shaker', price: '299', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&q=80&w=300'),
                          ProductCard(name: 'Yoga Mat', price: '650', imageUrl: 'https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?auto=format&fit=crop&q=80&w=300'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ────────────────────────── IMAGE SLIDER ──────────────────────────
class _GymImageSlider extends StatefulWidget {
  final String gymId;
  const _GymImageSlider({required this.gymId});

  @override
  State<_GymImageSlider> createState() => _GymImageSliderState();
}

class _GymImageSliderState extends State<_GymImageSlider> {
  final _controller = PageController();

  final List<Map<String, String>> _slides = const [
    {'url': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=800&q=80', 'text': 'Train Hard. Stay Fit.'},
    {'url': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=800&q=80', 'text': 'Push Your Limits.'},
    {'url': 'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?auto=format&fit=crop&w=800&q=80', 'text': 'Consistency is Key.'},
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  image: DecorationImage(image: NetworkImage(slide['url']!), fit: BoxFit.cover),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    ),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.gymId.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(8)),
                          child: Text(widget.gymId, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      const SizedBox(height: 6),
                      Text(slide['text']!, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: _controller,
          count: _slides.length,
          effect: const ExpandingDotsEffect(
            dotHeight: 6,
            dotWidth: 6,
            activeDotColor: AppColors.primary,
            dotColor: AppColors.divider,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────── PLANS ROW ──────────────────────────
class _PlansRow extends StatelessWidget {
  final String gymId;
  const _PlansRow({required this.gymId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('plans').where('gymId', isEqualTo: gymId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Text('No plans available yet', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          );
        }
        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              final data = docs[idx].data() as Map<String, dynamic>;
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withValues(alpha: 0.9), const Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.card_membership_rounded, color: Colors.white70, size: 22),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['planName'] ?? 'Plan', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                        Text('₹${data['price'] ?? '0'}', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
