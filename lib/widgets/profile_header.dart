import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitora/core/constants/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String? posterUrl;
  final String? avatarUrl;
  final String placeholderInitial;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLogout;

  const ProfileHeader({
    super.key,
    this.posterUrl,
    this.avatarUrl,
    required this.placeholderInitial,
    required this.onEdit,
    required this.onDelete,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background Poster
        GestureDetector(
          onTap: posterUrl != null && posterUrl!.isNotEmpty
              ? () => Navigator.pushNamed(
                    context,
                    '/image-preview',
                    arguments: {'heroTag': 'posterHero', 'imageUrl': posterUrl},
                  )
              : null,
          child: Hero(
            tag: 'posterHero',
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                image: posterUrl != null && posterUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(posterUrl!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.3), BlendMode.darken),
                      )
                    : null,
              ),
              child: posterUrl == null || posterUrl!.isEmpty
                  ? Stack(
                      children: [
                        // A subtle gradient or pattern for default poster
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        const Center(
                          child: Icon(Icons.fitness_center_rounded,
                              size: 64, color: Colors.white12),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
        ),

        // Gradient overlay for bottom edge of poster
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0A0A0A).withValues(alpha: 0.0),
                  const Color(0xFF0A0A0A),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // 3-dot Menu (Top Right)
        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                color: AppColors.backgroundCard,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                offset: const Offset(0, 48),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                  if (val == 'logout') onLogout();
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Text('Edit Profile',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Text('Delete Account',
                            style: GoogleFonts.inter(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Text('Logout',
                            style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Circular Avatar overlapping the poster
        Positioned(
          bottom: -50,
          left: 24,
          child: GestureDetector(
            onTap: avatarUrl != null && avatarUrl!.isNotEmpty
                ? () => Navigator.pushNamed(
                      context,
                      '/image-preview',
                      arguments: {'heroTag': 'avatarHero', 'imageUrl': avatarUrl},
                    )
                : null,
            child: Hero(
              tag: 'avatarHero',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.backgroundCard,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  image: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? Center(
                        child: Text(
                          placeholderInitial,
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
