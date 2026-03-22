import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitora/core/constants/app_colors.dart';
import 'package:fitora/core/constants/app_strings.dart';
import 'package:fitora/widgets/premium_role_card.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  String? _selectedRole;

  late AnimationController _heroController;
  late AnimationController _contentController;

  late Animation<double> _heroOpacity;
  late Animation<Offset> _heroSlide;
  late Animation<double> _card1Opacity;
  late Animation<Offset> _card1Slide;
  late Animation<double> _card2Opacity;
  late Animation<Offset> _card2Slide;
  late Animation<double> _buttonOpacity;
  late Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _heroOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOut),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic));

    _card1Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _contentController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _card1Slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _contentController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)));

    _card2Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _contentController, curve: const Interval(0.2, 0.8, curve: Curves.easeOut)),
    );
    _card2Slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _contentController, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)));

    _buttonOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _contentController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _contentController, curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic)));

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    _heroController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _contentController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_selectedRole == null) return;
    
    // Navigate to the correct registration screen based on role
    if (_selectedRole == 'owner') {
      Navigator.pushNamed(context, '/register-owner');
    } else if (_selectedRole == 'member') {
      Navigator.pushNamed(context, '/register-member');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHero(size),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 28),
                    _buildTitleSection(),
                    const SizedBox(height: 28),
                    _buildCard(
                      animation: _card1Opacity,
                      slideAnimation: _card1Slide,
                      roleKey: 'owner',
                      title: AppStrings.gymOwner,
                      description: AppStrings.gymOwnerDesc,
                      icon: Icons.storefront_rounded,
                      accentColor: AppColors.primary,
                      extraDetail: 'Manage members · Payments · Reports',
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      animation: _card2Opacity,
                      slideAnimation: _card2Slide,
                      roleKey: 'member',
                      title: AppStrings.gymMember,
                      description: AppStrings.gymMemberDesc,
                      icon: Icons.fitness_center_rounded,
                      accentColor: const Color(0xFF2563EB),
                      extraDetail: 'Workouts · Progress · Schedule',
                    ),
                    const SizedBox(height: 32),
                    _buildContinueButton(),
                    const SizedBox(height: 16),
                    _buildFooterNote(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(Size size) {
    return FadeTransition(
      opacity: _heroOpacity,
      child: SlideTransition(
        position: _heroSlide,
        child: Container(
          height: size.height * 0.30,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                child: Image.asset(
                  'assets/images/role_hero.png',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildHeroFallback(),
                ),
              ),
              Positioned(
                top: 16,
                left: 20,
                child: _buildLogoChip(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF3EE), Color(0xFFFFE8DC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.fitness_center_rounded, size: 80, color: AppColors.primary),
      ),
    );
  }

  Widget _buildLogoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        AppStrings.appName,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return FadeTransition(
      opacity: _card1Opacity,
      child: Column(
        children: [
          Text(
            AppStrings.chooseRole,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF111111),
              letterSpacing: -0.5,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.chooseRoleSubtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF888888),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required Animation<double> animation,
    required Animation<Offset> slideAnimation,
    required String roleKey,
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required String extraDetail,
  }) {
    final isSelected = _selectedRole == roleKey;

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slideAnimation,
        child: PremiumRoleCard(
          title: title,
          description: description,
          extraDetail: extraDetail,
          icon: icon,
          accentColor: accentColor,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedRole = roleKey),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = _selectedRole != null;

    return FadeTransition(
      opacity: _buttonOpacity,
      child: SlideTransition(
        position: _buttonSlide,
        child: GestureDetector(
          onTap: isEnabled ? _onContinue : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? AppColors.primaryGradient
                  : const LinearGradient(
                      colors: [Color(0xFFE0E0E0), Color(0xFFE0E0E0)],
                    ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isEnabled ? Colors.white : const Color(0xFFAAAAAA),
                  letterSpacing: 0.3,
                ),
                child: const Text('Continue'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return FadeTransition(
      opacity: _buttonOpacity,
      child: Text(
        'You can switch roles anytime from settings',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFFAAAAAA),
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
