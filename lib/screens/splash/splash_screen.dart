import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitora/core/constants/app_colors.dart';
import 'package:fitora/core/constants/app_strings.dart';
import 'package:fitora/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.6)),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _textController.forward();

    // Minimum delay to show the branding smoothly while Firebase loads in background
    final minimumWait = Future.delayed(const Duration(milliseconds: 1800));
    final routeFuture = _getInitialRoute();

    // Wait for BOTH the timer and the auth check to finish
    final results = await Future.wait([minimumWait, routeFuture]);
    final routeName = results[1] as String;

    if (mounted) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  Future<String> _getInitialRoute() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return AppRoutes.onboarding;
      }

      // Check users collection (for owners and members)
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final role = data['role'] as String?;
        if (role == 'owner') return AppRoutes.ownerDashboard;
        if (role == 'member') return AppRoutes.memberDashboard;
        return AppRoutes.onboarding;
      }

      // Check trainers collection
      final trainerDoc = await FirebaseFirestore.instance.collection('trainers').doc(user.uid).get();
      if (trainerDoc.exists) {
        return AppRoutes.trainerDashboard;
      }

      // Force sign out if orphaned
      await FirebaseAuth.instance.signOut();
      return AppRoutes.onboarding;
    } catch (e) {
      return AppRoutes.onboarding;
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: Stack(
          children: [
            _buildBackgroundOrbs(),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoOpacity,
                        child: _buildLogo(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _textOpacity,
                      child: SlideTransition(
                        position: _textSlide,
                        child: _buildText(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Center(
                  child: Text(
                    AppStrings.appTagline.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      letterSpacing: 3.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.asset(
          'assets/applogo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: const Center(
              child: Text(
                'F',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'FITLI',
                style: GoogleFonts.inter(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4.0,
                ),
              ),
              TextSpan(
                text: 'X',
                style: GoogleFonts.inter(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ).createShader(
                      const Rect.fromLTWH(0, 0, 40, 50),
                    ),
                  letterSpacing: 4.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -60,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
