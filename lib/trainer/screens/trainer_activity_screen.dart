import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/trainer_post_model.dart';
import '../models/trainer_model.dart';
import '../widgets/trainer_post_card.dart';
import '../services/trainer_auth_service.dart';
import '../../core/utils/cloudinary_upload.dart';

class TrainerActivityScreen extends StatefulWidget {
  const TrainerActivityScreen({super.key});

  @override
  State<TrainerActivityScreen> createState() => _TrainerActivityScreenState();
}

class _TrainerActivityScreenState extends State<TrainerActivityScreen> {
  final TrainerAuthService _authService = TrainerAuthService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final trainer = await _authService.getCurrentTrainer();
    if (mounted) setState(() => _currentUserId = trainer?.id);
  }

  Future<void> _deletePost(TrainerPostModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Post?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
        content: Text('This will permanently delete this post.', style: GoogleFonts.inter(color: Colors.black87)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            ),
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );

    if (confirm != true) return;

    if (post.mediaUrl.isNotEmpty) {
      await CloudinaryService.deleteMedia(post.mediaUrl, isVideo: post.type == 'video');
    }
    await FirebaseFirestore.instance.collection('posts').doc(post.id).delete();
  }

  void _showLikers(String postId) async {
    final likesSnap = await FirebaseFirestore.instance.collection('posts').doc(postId).collection('likes').get();
    final likerIds = likesSnap.docs.map((d) => d.id).toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 4, width: 40,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Text('Liked by', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Divider(),
            Expanded(
              child: likerIds.isEmpty
                ? Center(child: Text('No likes yet', style: GoogleFonts.inter(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: likerIds.length,
                    itemBuilder: (ctx, i) => FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('trainers').doc(likerIds[i]).get(),
                      builder: (ctx, snap) {
                        if (!snap.hasData) return const ListTile(leading: CircleAvatar(child: Icon(Icons.person)));
                        final data = snap.data!.data() as Map<String, dynamic>?;
                        if (data == null) return const SizedBox.shrink();
                        final trainer = TrainerModel.fromMap(data, snap.data!.id);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            backgroundImage: trainer.profileImage.isNotEmpty ? CachedNetworkImageProvider(trainer.profileImage) : null,
                            child: trainer.profileImage.isEmpty ? const Icon(Icons.person) : null,
                          ),
                          title: Text(trainer.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
                          subtitle: Text('@${trainer.username}', style: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                        );
                      },
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text('My Activity', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('trainerId', isEqualTo: _currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'You have no activity yet.',
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final posts = snapshot.data!.docs.map((doc) => TrainerPostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
          // Sort locally to bypass index requirements
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return RefreshIndicator(
            onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
            child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TrainerPostCard(
                  post: posts[index],
                  onDelete: () => _deletePost(posts[index]),
                  onLikesTap: () => _showLikers(posts[index].id),
                ),
              );
            },
            ),
          );
        },
      ),
    );
  }
}
