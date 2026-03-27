import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../services/follow_service.dart';

class TrainerFollowersScreen extends StatelessWidget {
  final String trainerId;
  final String trainerName;

  const TrainerFollowersScreen({
    super.key,
    required this.trainerId,
    required this.trainerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Followers',
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Text(
              trainerName,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FollowService().getFollowersStream(trainerId),
        builder: (context, snapshot) {
          // Show Firestore errors explicitly (helps debug index issues)
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Error loading followers:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final docs = snapshot.data?.docs ?? [];

          // Client-side sort by createdAt descending (no composite index required)
          final sorted = List.of(docs)
            ..sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['createdAt'];
              final bTime = (b.data() as Map<String, dynamic>)['createdAt'];
              if (aTime == null || bTime == null) return 0;
              return (bTime as dynamic).compareTo(aTime as dynamic);
            });
          if (sorted.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text('No followers yet', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('Share profile to get followers!', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            );
          }

          final followerIds = sorted
              .map((d) => (d.data() as Map<String, dynamic>)['followerId'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: followerIds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _FollowerCard(userId: followerIds[index]);
            },
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Individual follower card (fetches user data)
// ──────────────────────────────────────────────
class _FollowerCard extends StatelessWidget {
  final String userId;

  const _FollowerCard({required this.userId});

  Future<Map<String, dynamic>?> _fetchUser() async {
    // 1. Try trainers collection first
    final trainerDoc = await FirebaseFirestore.instance.collection('trainers').doc(userId).get();
    if (trainerDoc.exists && trainerDoc.data() != null) {
      final d = trainerDoc.data()!;
      return {
        'name': d['name'] ?? 'Trainer',
        'username': '@${d['username'] ?? ''}',
        'image': d['profileImage'] ?? '',
        'role': 'trainer',
      };
    }

    // 2. Try users collection (members and owners)
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data() != null) {
      final d = userDoc.data()!;
      final role = d['role'] as String? ?? 'member';

      if (role == 'owner') {
        // Owners: identity = gym name from gyms collection
        final gymId = d['gymId'] as String? ?? '';
        String gymName = 'Gym Owner';
        String gymAvatar = '';
        if (gymId.isNotEmpty) {
          final gymDoc = await FirebaseFirestore.instance.collection('gyms').doc(gymId).get();
          if (gymDoc.exists && gymDoc.data() != null) {
            final g = gymDoc.data()!;
            gymName = g['name'] as String? ?? 'Gym Owner';
            gymAvatar = g['avatarUrl'] as String? ?? '';
          }
        }
        return {
          'name': gymName,
          'username': 'Gym Owner',
          'image': gymAvatar,
          'role': 'owner',
        };
      } else {
        // Members
        return {
          'name': d['name'] ?? 'Member',
          'username': d['email'] ?? '',
          'image': d['avatarUrl'] ?? d['profileImage'] ?? '',
          'role': 'member',
        };
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
          );
        }

        final user = snapshot.data;
        if (user == null) return const SizedBox.shrink();

        final name = user['name'] as String;
        final username = user['username'] as String;
        final image = user['image'] as String;
        final role = user['role'] as String;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Navigate to trainer profile if follower is a trainer
              if (role == 'trainer') {
                Navigator.pushNamed(context, '/trainer-profile', arguments: userId);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    backgroundImage: image.isNotEmpty ? CachedNetworkImageProvider(image) : null,
                    child: image.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),

                  // Name + username
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        if (username.isNotEmpty)
                          Text(
                            username.contains('@') ? username : '@$username',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                  ),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _roleColor(role).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role[0].toUpperCase() + role.substring(1),
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _roleColor(role)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'trainer': return AppColors.primary;
      case 'owner': return const Color(0xFF7C3AED);
      default: return const Color(0xFF059669);
    }
  }
}
