import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitora/core/constants/app_colors.dart';
import '../../trainer/models/trainer_post_model.dart';
import '../../trainer/models/trainer_model.dart';
import '../../trainer/widgets/trainer_post_card.dart';
import '../../trainer/screens/trainer_profile_screen.dart';

class MemberTrainers extends StatefulWidget {
  const MemberTrainers({super.key});

  @override
  State<MemberTrainers> createState() => _MemberTrainersState();
}

class _MemberTrainersState extends State<MemberTrainers> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  List<TrainerModel> _allTrainers = [];
  List<TrainerModel> _filtered = [];
  bool _loadingTrainers = true;

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTrainers() async {
    // Load all trainers from the global trainers collection (same collection trainer module uses)
    final snap = await FirebaseFirestore.instance.collection('trainers').get();
    final trainers = snap.docs.map((d) => TrainerModel.fromMap(d.data(), d.id)).toList();
    if (mounted) setState(() { _allTrainers = trainers; _filtered = trainers; _loadingTrainers = false; });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
      _filtered = _searchQuery.isEmpty
          ? _allTrainers
          : _allTrainers.where((t) =>
              t.username.toLowerCase().contains(_searchQuery) ||
              t.name.toLowerCase().contains(_searchQuery)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trainers', style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                      Text('Explore & connect with trainers', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SearchBarDelegate(
                  height: 68.0,
                  child: Container(
                    color: const Color(0xFF0A0A0A),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearch,
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Search trainers by username...',
                        hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 22),
                        suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                              onPressed: () { _searchCtrl.clear(); _onSearch(''); },
                            )
                          : null,
                        filled: true,
                        fillColor: AppColors.backgroundCard,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: _loadingTrainers
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _searchQuery.isNotEmpty
              // Search results: show trainer cards
              ? _filtered.isEmpty
                ? _noResults()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _trainerTile(_filtered[i]),
                  )
              // Default: stream of all trainer posts
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) return _emptyFeed();

                    final posts = docs.map((d) => TrainerPostModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: posts.length,
                      itemBuilder: (_, i) => TrainerPostCard(post: posts[i]),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _trainerTile(TrainerModel trainer) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrainerProfileScreen(trainerId: trainer.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.surface,
              backgroundImage: trainer.profileImage.isNotEmpty ? CachedNetworkImageProvider(trainer.profileImage) : null,
              child: trainer.profileImage.isEmpty ? Text(trainer.name.isNotEmpty ? trainer.name[0].toUpperCase() : 'T', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trainer.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('@${trainer.username}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  if (trainer.bio != null && trainer.bio!.isNotEmpty)
                    Text(trainer.bio!, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _noResults() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.person_search_rounded, color: AppColors.textMuted, size: 52),
      const SizedBox(height: 12),
      Text('No trainers found', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      Text('Try a different username', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
    ]));
  }

  Widget _emptyFeed() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.sports_gymnastics_rounded, color: AppColors.primary, size: 32)),
      const SizedBox(height: 16),
      Text('No Posts Yet', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
      Text('Trainer posts will appear here in real-time.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
    ]));
  }
}

// ──────────────────────────────────────────────────────────────────
// SLIVER DELEGATE FOR STICKY SEARCH BAR
// ──────────────────────────────────────────────────────────────────
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SearchBarDelegate({required this.child, this.height = 76.0});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SearchBarDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
