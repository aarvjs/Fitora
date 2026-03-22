import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumRoleCard extends StatefulWidget {
  final String title;
  final String description;
  final String extraDetail;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const PremiumRoleCard({
    super.key,
    required this.title,
    required this.description,
    required this.extraDetail,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<PremiumRoleCard> createState() => _PremiumRoleCardState();
}

class _PremiumRoleCardState extends State<PremiumRoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.972).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accentColor
                  : const Color(0xFFEEEEEE),
              width: widget.isSelected ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? widget.accentColor.withValues(alpha: 0.15)
                    : const Color(0x0A000000),
                blurRadius: widget.isSelected ? 24 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildIconBox(),
                const SizedBox(width: 18),
                Expanded(child: _buildContent()),
                _buildSelectionIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: widget.isSelected
            ? widget.accentColor.withValues(alpha: 0.12)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        widget.icon,
        size: 30,
        color: widget.isSelected ? widget.accentColor : const Color(0xFFAAAAAA),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111111),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.description,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF777777),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        _buildDetailChip(),
      ],
    );
  }

  Widget _buildDetailChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? widget.accentColor.withValues(alpha: 0.08)
            : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.extraDetail,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: widget.isSelected ? widget.accentColor : const Color(0xFF999999),
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 26,
      height: 26,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isSelected ? widget.accentColor : Colors.transparent,
        border: Border.all(
          color: widget.isSelected ? widget.accentColor : const Color(0xFFCCCCCC),
          width: 2,
        ),
      ),
      child: widget.isSelected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}
