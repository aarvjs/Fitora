import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:fitora/core/constants/app_colors.dart';

class VideoListScreen extends StatefulWidget {
  final String gymId;
  final bool isOwner;
  const VideoListScreen({super.key, required this.gymId, this.isOwner = true});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Gym Videos',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('videos')
            .where('gymId', isEqualTo: widget.gymId)
            // No compound ordering, sort locally
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snap.hasError || !snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No videos found.',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 16),
              ),
            );
          }

          final rawDocs = snap.data!.docs;
          final docs = rawDocs.toList()
            ..sort((a, b) {
              final at = (a.data() as Map)['createdAt'] as Timestamp?;
              final bt = (b.data() as Map)['createdAt'] as Timestamp?;
              if (at == null && bt == null) return 0;
              if (at == null) return 1;
              if (bt == null) return -1;
              return bt.compareTo(at);
            });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 24),
            itemBuilder: (ctx, idx) {
              final data = docs[idx].data() as Map<String, dynamic>;
              final String videoUrl = data['videoUrl'] ?? '';
              final String docId = docs[idx].id;

              return VideoFeedItem(
                videoUrl: videoUrl,
                videoId: docId,
                isOwner: widget.isOwner,
              );
            },
          );
        },
      ),
    );
  }
}

class VideoFeedItem extends StatefulWidget {
  final String videoUrl;
  final String videoId;
  final bool isCompact;
  final bool isOwner;

  const VideoFeedItem({
    super.key,
    required this.videoUrl,
    required this.videoId,
    this.isCompact = false,
    this.isOwner = true,
  });

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          _controller!.setLooping(true);
          if (mounted) {
            setState(() {
              _initialized = true;
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _error = true;
            });
          }
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null || !_initialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 8),
            Text('Failed to load video', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Container(
      height: widget.isCompact ? null : 450,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Video Player Box
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_initialized && _controller != null)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                else
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),

                // Play/Pause Overlay
                if (_initialized && _controller != null)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        color: _controller!.value.isPlaying
                            ? Colors.transparent
                            : Colors.black.withValues(alpha: 0.35),
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Progress Indicator integrated into the bottom
                if (_initialized && _controller != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      colors: VideoProgressColors(
                        playedColor: AppColors.primary,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Delete / Info Footer (Hidden in compact mode)
          if (!widget.isCompact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gym Video',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  if (widget.isOwner)
                    IconButton(
                      onPressed: () => _confirmDelete(),
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 22),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Video?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('This action cannot be undone.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('videos').doc(widget.videoId).delete();
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
