import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitora/core/constants/app_colors.dart';

class OnboardingData {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        _buildImage(size),
        _buildGradientOverlay(size),
        _buildContent(context, size),
      ],
    );
  }

  Widget _buildImage(Size size) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: size.height * 0.62,
      child: Image.asset(
        data.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.backgroundCard,
          child: const Center(
            child: Icon(
              Icons.fitness_center,
              size: 80,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay(Size size) {
    return Positioned(
      top: size.height * 0.35,
      left: 0,
      right: 0,
      height: size.height * 0.65,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.backgroundDark.withValues(alpha: 0.85),
              AppColors.backgroundDark,
            ],
            stops: const [0.0, 0.4, 0.7],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Size size) {
    return Positioned(
      top: size.height * 0.52,
      left: 32,
      right: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAccentLine(),
          const SizedBox(height: 16),
          Text(
            data.title,
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.description,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccentLine() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
