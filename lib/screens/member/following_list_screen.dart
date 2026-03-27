import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitora/core/constants/app_colors.dart';
import 'package:fitora/trainer/services/follow_service.dart';

class FollowingListScreen extends StatefulWidget {
  final String followerId;

  const FollowingListScreen({super.key, required this.followerId});

  @override
  State<FollowingListScreen> createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Following', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search trainers...',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          Expanded(
            // Stream of followed trainer IDs
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('follows')
                  .where('followerId', isEqualTo: widget.followerId)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_add_disabled_rounded, color: AppColors.textMuted, size: 48),
                        const SizedBox(height: 16),
                        Text("Not following anyone yet.", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
                      ],
                    ),
                  );
                }

                final trainerIds = docs
                    .map((d) => (d.data() as Map<String, dynamic>)['trainerId'] as String? ?? '')
                    .where((id) => id.isNotEmpty)
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: trainerIds.length,
                  itemBuilder: (context, index) {
                    return _SearchedTrainerCard(
                      trainerId: trainerIds[index],
                      searchQuery: _searchQuery,
                      onUnfollow: () => FollowService().unfollow(trainerIds[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchedTrainerCard extends StatelessWidget {
  final String trainerId;
  final String searchQuery;
  final VoidCallback onUnfollow;

  const _SearchedTrainerCard({
    required this.trainerId,
    required this.searchQuery,
    required this.onUnfollow,
  });

  Future<Map<String, dynamic>?> _fetchTrainer() async {
    final doc = await FirebaseFirestore.instance.collection('trainers').doc(trainerId).get();
    if (doc.exists && doc.data() != null) {
      final d = doc.data()!;
      return {
        'name': d['name'] ?? 'Trainer',
        'username': d['username'] ?? '',
        'image': d['profileImage'] ?? '',
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchTrainer(),
      builder: (context, snap) {
        if (!snap.hasData) {
          // If searching, hide loading skeleton to avoid layout jumps
          if (searchQuery.isNotEmpty) return const SizedBox.shrink();

          return Container(
            height: 68,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
          );
        }

        final trainer = snap.data;
        if (trainer == null) return const SizedBox.shrink();

        final name = (trainer['name'] as String);
        final username = (trainer['username'] as String);
        final image = trainer['image'] as String;

        // Apply Search Filter locally
        if (searchQuery.isNotEmpty) {
          final matchesName = name.toLowerCase().contains(searchQuery);
          final matchesUsername = username.toLowerCase().contains(searchQuery);
          if (!matchesName && !matchesUsername) return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: image.isNotEmpty ? CachedNetworkImageProvider(image) : null,
                child: image.isEmpty
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'T',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (username.isNotEmpty)
                      Text('@$username', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onUnfollow,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Unfollow', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
