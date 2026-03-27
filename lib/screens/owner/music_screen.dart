import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:fitora/core/constants/app_colors.dart';
import 'package:fitora/services/youtube_music_service.dart';
import 'package:fitora/widgets/search_bar_widget.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final _youtubeService = YouTubeMusicService();
  List<Map<String, String>> _videos = [];
  bool _isLoading = true;
  String? _errorMsg;
  Timer? _debounce;

  // Player State
  YoutubePlayerController? _youtubeController;
  Map<String, String>? _currentPlaying;
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _fetchDefaultMusic();
  }

  @override
  void dispose() {
    _isPlaying.dispose();
    _debounce?.cancel();
    _youtubeController?.dispose();
    super.dispose();
  }

  Future<void> _fetchDefaultMusic() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final videos = await _youtubeService.getDefaultWorkoutMusic();
      if (mounted) setState(() => _videos = videos);
    } catch (e) {
      if (mounted) setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchMusic(String query) async {
    if (query.trim().isEmpty) {
      await _fetchDefaultMusic();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final videos = await _youtubeService.searchVideos(query);
      if (mounted) setState(() => _videos = videos);
    } catch (e) {
      if (mounted) setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => _searchMusic(query));
  }

  void _playVideo(Map<String, String> video) {
    final videoId = video['videoId']!;
    if (_currentPlaying?['videoId'] == videoId) return; // Prevent redundant requests

    if (_youtubeController == null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          hideControls: true,
          loop: true,
        ),
      )..addListener(_onPlayerStateChange);
    } else {
      _youtubeController!.load(videoId);
    }
    setState(() {
      _currentPlaying = video;
    });
    _isPlaying.value = true;
  }

  void _onPlayerStateChange() {
    if (_youtubeController != null && mounted) {
      if (_isPlaying.value != _youtubeController!.value.isPlaying) {
        _isPlaying.value = _youtubeController!.value.isPlaying;
      }
    }
  }

  void _togglePlayPause() {
    if (_youtubeController == null) return;
    if (_isPlaying.value) {
      _youtubeController!.pause();
    } else {
      _youtubeController!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.divider)),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Music', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SearchBarWidget(
                hintText: 'Search workout music...',
                onChanged: _onSearchChanged,
              ),
            ),

            // Main Content Area
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Lottie.asset('assets/images/loading.json', width: 140, height: 140, fit: BoxFit.cover),
                    )
                  : _errorMsg != null
                      ? _buildErrorState()
                      : _buildVideoList(),
            ),

            // Sticky Bottom Mini Player
            if (_currentPlaying != null) _buildMiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final isApiKeyMissing = _errorMsg!.contains('API Key is missing');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isApiKeyMissing ? Icons.vpn_key_off_rounded : Icons.error_outline_rounded, color: Colors.redAccent, size: 50),
            const SizedBox(height: 16),
            Text('Playback Unavailable', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              isApiKeyMissing
                  ? 'Please add your YouTube API Key in lib/core/config/api_keys.dart to search and play music.'
                  : _errorMsg!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // extra padding for bottom player
      itemCount: _videos.length,
      itemBuilder: (context, i) {
        final video = _videos[i];
        final isPlaying = _currentPlaying?['videoId'] == video['videoId'];
        
        return GestureDetector(
          onTap: () => _playVideo(video),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPlaying ? AppColors.primary.withValues(alpha: 0.12) : AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isPlaying ? AppColors.primary.withValues(alpha: 0.4) : AppColors.divider),
            ),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    video['thumbnail']!,
                    width: 70,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70, height: 50, color: AppColors.surface,
                      child: const Icon(Icons.music_note_rounded, color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Titles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video['title']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: isPlaying ? AppColors.primary : Colors.white, fontWeight: FontWeight.w700, fontSize: 13, height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video['channelTitle']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Action Icon
                ValueListenableBuilder<bool>(
                  valueListenable: _isPlaying,
                  builder: (context, isPlayingNow, child) {
                    return Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isPlaying ? AppColors.primary : AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? (isPlayingNow ? Icons.pause_rounded : Icons.play_arrow_rounded) : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniPlayer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Spotify dark gray
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The hidden youtube player that produces audio safely scaled
          if (_youtubeController != null)
            Opacity(
              opacity: 0.01,
              child: SizedBox(
                height: 1,
                width: 1,
                child: YoutubePlayer(
                  controller: _youtubeController!,
                  showVideoProgressIndicator: false,
                ),
              ),
            ),
            
          // Progress Bar Header
          if (_youtubeController != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProgressBar(
                isExpanded: true,
                controller: _youtubeController,
                colors: const ProgressBarColors(
                  playedColor: AppColors.primary,
                  handleColor: Colors.white,
                  backgroundColor: AppColors.surface,
                  bufferedColor: AppColors.divider,
                ),
              ),
            ),

          // Player Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _currentPlaying!['thumbnail']!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 44, height: 44),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentPlaying!['title']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentPlaying!['channelTitle']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Controls
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28),
                  onPressed: () {
                    // Logic for previous song can be added here
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _isPlaying,
                  builder: (context, isPlayingNow, child) {
                    return GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          isPlayingNow ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 26,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                  onPressed: () {
                    // Logic for next song can be added here
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
