import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/constants/app_colors.dart';
import '../models/trainer_post_model.dart';
import '../models/trainer_model.dart';
import '../services/trainer_auth_service.dart';
import '../screens/trainer_profile_screen.dart'; // Added router integration

class TrainerPostCard extends StatefulWidget {
  final TrainerPostModel post;
  final VoidCallback? onDelete;
  final VoidCallback? onLikesTap;

  const TrainerPostCard({super.key, required this.post, this.onDelete, this.onLikesTap});

  @override
  State<TrainerPostCard> createState() => _TrainerPostCardState();
}

class _TrainerPostCardState extends State<TrainerPostCard> {
  final TrainerAuthService _authService = TrainerAuthService();
  TrainerModel? _currentTrainer;
  VideoPlayerController? _videoController;

  bool _isLiked = false;
  int _likesCount = 0;
  int _commentsCount = 0;
  bool _isExpanded = false; // Controls "Read More" logic

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;
    _loadUser();
    _checkInitialLike();
    
    if (widget.post.type == 'video' && widget.post.mediaUrl.isNotEmpty) {
       _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.post.mediaUrl))
         ..initialize().then((_) {
           if (mounted) setState(() {});
         })
         ..setLooping(true)
         ..setVolume(0.0)
         ..play();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final trainer = await _authService.getCurrentTrainer();
    if (mounted) setState(() => _currentTrainer = trainer);
  }

  Future<void> _checkInitialLike() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.post.id)
        .collection('likes')
        .doc(userId)
        .get();

    if (mounted) {
      setState(() {
        _isLiked = doc.exists;
      });
    }
  }

  Future<void> _toggleLike() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.post.id);
    final likeRef = postRef.collection('likes').doc(userId);

    if (_isLiked) {
      setState(() {
        _isLiked = false;
        _likesCount = (_likesCount - 1).clamp(0, 999999);
      });
      await likeRef.delete();
      await postRef.update({'likesCount': FieldValue.increment(-1)});
    } else {
      setState(() {
        _isLiked = true;
        _likesCount++;
      });
      await likeRef.set({'createdAt': FieldValue.serverTimestamp()});
      await postRef.update({'likesCount': FieldValue.increment(1)});
    }
  }

  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentsSheet(
        postId: widget.post.id,
        postOwnerId: widget.post.trainerId,
        currentTrainer: _currentTrainer,
        onCommentsChanged: (delta) {
          setState(() {
            _commentsCount = (_commentsCount + delta).clamp(0, 999999);
          });
        },
      )
    );
  }

  Future<TrainerModel?> _getTrainerInfo() async {
    final doc = await FirebaseFirestore.instance.collection('trainers').doc(widget.post.trainerId).get();
    if (doc.exists && doc.data() != null) {
      return TrainerModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  void _navigateToProfile() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => TrainerProfileScreen(trainerId: widget.post.trainerId))
    );
  }
  
  Widget _buildDescriptionClamp(String text, {double fontSize = 14}) {
    if (text.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: _isExpanded ? null : 2,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: fontSize, color: Colors.black87, fontWeight: FontWeight.w500, height: 1.5), // High contrast UX fix
        ),
        if (text.length > 80 || '\n'.allMatches(text).length > 1)
          GestureDetector(
             onTap: () => setState(() => _isExpanded = !_isExpanded),
             child: Padding(
               padding: const EdgeInsets.only(top: 6.0),
               child: Text(
                 _isExpanded ? 'Show Less' : '... Read More',
                 style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
               ),
             ),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: FutureBuilder<TrainerModel?>(
        future: _getTrainerInfo(),
        builder: (context, snapshot) {
          final trainer = snapshot.data;
          final timeString = timeago.format(widget.post.createdAt);
          final isArticle = widget.post.type == 'text';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Interactive Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: _navigateToProfile,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFDCEEFB), // Light blue
                        backgroundImage: trainer != null && trainer.profileImage.isNotEmpty
                            ? CachedNetworkImageProvider(trainer.profileImage)
                            : null,
                        child: trainer == null || trainer.profileImage.isEmpty
                            ? const Icon(Icons.person, color: Color(0xFF1976D2))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trainer?.name ?? 'Loading...',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87), // Increased weight/color
                            ),
                            if (trainer?.username != null)
                               Text(
                                 '@${trainer!.username}',
                                 style: GoogleFonts.inter(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600), // Enforced dark text
                               ),
                            Text(
                              timeString,
                              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (ctx) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.delete, color: Colors.red),
                                      title: const Text('Delete Post', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        widget.onDelete!();
                                      },
                                    ),
                                  ],
                                ),
                              )
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Content Core
              if (isArticle)
                // Text Article Layout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: _buildDescriptionClamp(widget.post.description, fontSize: 16),
                )
              else ...[
                // Media Layout
                if (widget.post.mediaUrl.isNotEmpty) ...[
                  if (widget.post.type == 'video' && _videoController != null && _videoController!.value.isInitialized)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                        });
                      },
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_videoController!),
                            if (!_videoController!.value.isPlaying)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                              )
                          ],
                        ),
                      ),
                    )
                  else
                    CachedNetworkImage(
                      imageUrl: widget.post.mediaUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                ],
                
                // Description (if Media)
                if (widget.post.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildDescriptionClamp(widget.post.description), // Capped and stylized string
                  ),
              ],

              // Actions Footer
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.black87,
                      ),
                      onPressed: _toggleLike,
                    ),
                    GestureDetector(
                      onTap: widget.onLikesTap,
                      child: Text('$_likesCount', style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, 
                        color: widget.onLikesTap != null ? Colors.blue[700] : Colors.black87,
                        decoration: widget.onLikesTap != null ? TextDecoration.underline : TextDecoration.none,
                      )),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
                      onPressed: _showCommentsSheet,
                    ),
                    Text('$_commentsCount', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------
// Internal Comments Sheet (Nested Threads Mechanism)
// ----------------------------------------------------

class _CommentsSheet extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final TrainerModel? currentTrainer;
  final void Function(int delta) onCommentsChanged;

  const _CommentsSheet({required this.postId, required this.postOwnerId, this.currentTrainer, required this.onCommentsChanged});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _replyingToId;
  String? _replyingToName;
  bool _isSubmitting = false;

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Comment', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('Are you sure you want to delete this comment? This will also remove any replies attached to it.', style: GoogleFonts.inter(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );

    if (confirm != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
      final commentsRef = postRef.collection('comments');

      batch.delete(commentsRef.doc(commentId));

      final replies = await commentsRef.where('replyToId', isEqualTo: commentId).get();
      for (var r in replies.docs) {
         batch.delete(r.reference);
      }

      final totalDeleted = 1 + replies.docs.length;
      batch.update(postRef, {'commentsCount': FieldValue.increment(-totalDeleted)});

      await batch.commit();

      widget.onCommentsChanged(-totalDeleted);

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment deleted securely.')));
      }
    } catch (_) {}
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSubmitting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      String userName = 'User';
      String userImage = '';
      if (userId != null) {
        if (widget.currentTrainer != null) {
          userName = widget.currentTrainer!.name;
          userImage = widget.currentTrainer!.profileImage;
        } else {
          // Check users collection (members/owners)
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final d = userDoc.data()!;
            userName = d['name'] ?? d['gymName'] ?? 'User';
            userImage = d['profileImage'] ?? d['avatarUrl'] ?? '';
            
            // If it's an owner or fallback user, pull from Gym collection
            if ((d['role'] == 'owner' || d['gymId'] != null) && (userName == 'User' || userImage.isEmpty)) {
              final gymId = d['gymId'];
              if (gymId != null && gymId.toString().isNotEmpty) {
                final gymDoc = await FirebaseFirestore.instance.collection('gyms').doc(gymId).get();
                if (gymDoc.exists) {
                  final gymData = gymDoc.data()!;
                  if (userName == 'User') userName = gymData['name'] ?? 'Owner';
                  if (userImage.isEmpty) userImage = gymData['avatarUrl'] ?? gymData['profileImage'] ?? '';
                }
              }
            }
          }
        }
      }

      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').add({
        'userId': userId,
        'userName': userName,
        'userImage': userImage,
        'text': text,
        'replyToId': _replyingToId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
        'commentsCount': FieldValue.increment(1)
      });

      _commentCtrl.clear();
      widget.onCommentsChanged(1);
      
      setState(() {
        _replyingToId = null;
        _replyingToName = null;
      });
      _focusNode.unfocus();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildCommentTile(Map<String, dynamic> comment, bool isReply) {
    final t = comment['createdAt'] as Timestamp?;
    final timeStr = t != null ? timeago.format(t.toDate(), locale: 'en_short') : 'now';
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnerOrAuthor = currentUserId == widget.postOwnerId || currentUserId == comment['userId'];

    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40.0 : 0.0, bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundColor: Colors.grey[300],
            backgroundImage: (comment['userImage'] != null && comment['userImage'].toString().isNotEmpty)
                ? CachedNetworkImageProvider(comment['userImage'])
                : null,
            child: (comment['userImage'] == null || comment['userImage'].toString().isEmpty)
                ? Icon(Icons.person, size: isReply ? 16 : 22, color: Colors.grey[600])
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment['userName'] ?? 'User', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: isReply ? 13 : 14)), // Darkened constraints
                    const SizedBox(width: 8),
                    Text(timeStr, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment['text'] ?? '', style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)), // High contrast text
                const SizedBox(height: 6),
                // Native Reply / Delete Actions
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                           _replyingToId = isReply ? comment['replyToId'] : comment['id'];
                           _replyingToName = comment['userName'];
                        });
                        _focusNode.requestFocus();
                      },
                      child: Text('Reply', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    ),
                    if (isOwnerOrAuthor) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                         onTap: () => _deleteComment(comment['id']),
                         child: Text('Delete', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[400])),
                      )
                    ]
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Text('Comments', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const Divider(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').snapshots(),
              builder: (ctx, snapshot) {
                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                 final docs = snapshot.data!.docs;
                 if (docs.isEmpty) return Center(child: Text('Be the first to comment!', style: GoogleFonts.inter(color: Colors.grey[700], fontWeight: FontWeight.w500)));

                 final allComments = docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
                 final roots = allComments.where((c) => c['replyToId'] == null).toList();
                 roots.sort((a,b) {
                    final ta = a['createdAt'] as Timestamp?;
                    final tb = b['createdAt'] as Timestamp?;
                    if (ta == null || tb == null) return 0;
                    return tb.compareTo(ta); 
                 });

                 return ListView.builder(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                   itemCount: roots.length,
                   itemBuilder: (ctx, idx) {
                      final root = roots[idx];
                      final replies = allComments.where((c) => c['replyToId'] == root['id']).toList();
                      replies.sort((a,b) {
                        final ta = a['createdAt'] as Timestamp?;
                        final tb = b['createdAt'] as Timestamp?;
                        if (ta == null || tb == null) return 0;
                        return ta.compareTo(tb); 
                      });

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCommentTile(root, false),
                          ...replies.map((r) => _buildCommentTile(r, true)),
                        ]
                      );
                   }
                 );
              }
            )
          ),

          if (_replyingToName != null)
             Container(
               color: Colors.grey[100],
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
               child: Row(
                 children: [
                   Text('Replying to $_replyingToName', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
                   const Spacer(),
                   GestureDetector(
                     onTap: () => setState(() { _replyingToId = null; _replyingToName = null; }),
                     child: const Icon(Icons.close, size: 18, color: Colors.grey),
                   )
                 ]
               )
             ),
             
          // Highly visible input row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: widget.currentTrainer?.profileImage.isNotEmpty == true ? CachedNetworkImageProvider(widget.currentTrainer!.profileImage) : null,
                  child: widget.currentTrainer == null || widget.currentTrainer!.profileImage.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    focusNode: _focusNode,
                    style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: _replyingToName != null ? 'Write a reply...' : 'Write a comment...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.w500),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSubmitting ? null : () {
                    _submitComment();
                  },
                  icon: _isSubmitting 
                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                     : const Icon(Icons.send, color: AppColors.primary),
                )
              ],
            ),
          )
        ],
      )
    );
  }
}
