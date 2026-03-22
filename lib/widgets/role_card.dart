import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitora/core/constants/app_colors.dart';

class RoleCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final String tag;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.tag,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isPrimary = widget.gradientColors.first != const Color(0xFF1A1A1A);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: size.height * 0.20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPrimary
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.divider,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isPrimary
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                _buildIconBox(isPrimary),
                const SizedBox(width: 22),
                Expanded(child: _buildTextContent(isPrimary)),
                _buildArrow(isPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(bool isPrimary) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isPrimary
            ? Colors.white.withValues(alpha: 0.18)
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPrimary
              ? Colors.white.withValues(alpha: 0.25)
              : AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Icon(
        widget.icon,
        size: 32,
        color: isPrimary ? Colors.white : AppColors.primary,
      ),
    );
  }

  Widget _buildTextContent(bool isPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: isPrimary
                ? Colors.white.withValues(alpha: 0.18)
                : AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.tag.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isPrimary ? Colors.white : AppColors.primary,
              letterSpacing: 1.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.description,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: isPrimary
                ? Colors.white.withValues(alpha: 0.75)
                : AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildArrow(bool isPrimary) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isPrimary
            ? Colors.white.withValues(alpha: 0.18)
            : AppColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 18,
        color: isPrimary ? Colors.white : AppColors.primary,
      ),
    );
  }
}
