import 'package:flutter/material.dart';
import 'package:fitora/screens/splash/splash_screen.dart';
import 'package:fitora/screens/onboarding/onboarding_screen.dart';
import 'package:fitora/screens/role_selection/role_selection_screen.dart';

import 'package:fitora/screens/auth/login.dart';
import 'package:fitora/screens/auth/owner_register.dart';
import 'package:fitora/screens/auth/member_register.dart';
import 'package:fitora/trainer/screens/trainer_auth_screen.dart';
import 'package:fitora/trainer/screens/trainer_dashboard.dart';
import 'package:fitora/trainer/screens/trainer_search_screen.dart';
import 'package:fitora/trainer/screens/trainer_post_create_screen.dart';
import 'package:fitora/trainer/screens/trainer_profile_screen.dart';
import 'package:fitora/trainer/screens/trainer_edit_profile_screen.dart';
import 'package:fitora/screens/auth/forgot_password/phone_input.dart';
import 'package:fitora/screens/auth/forgot_password/otp_verify.dart';
import 'package:fitora/screens/auth/forgot_password/reset_password.dart';
import 'package:fitora/screens/owner/owner_dashboard.dart';
import 'package:fitora/screens/member/member_dashboard.dart';
import 'package:fitora/screens/settings/privacy_policy.dart';
import 'package:fitora/screens/settings/terms_conditions.dart';
import 'package:fitora/screens/settings/help_support.dart';
import 'package:fitora/screens/settings/about_app.dart';
import 'package:fitora/widgets/image_preview_screen.dart';
import 'package:fitora/screens/owner/timer_screen.dart';
import 'package:fitora/screens/owner/music_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role-selection';
  
  static const String login = '/login';
  static const String ownerRegister = '/register-owner';
  static const String memberRegister = '/register-member';
  static const String trainerRegister = '/register-trainer';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerify = '/forgot-password/otp';
  static const String resetPassword = '/forgot-password/reset';
  static const String ownerDashboard = '/owner-dashboard';
  static const String memberDashboard = '/member-dashboard';
  static const String trainerDashboard = '/trainer-dashboard';
  static const String trainerSearch = '/trainer-search';
  static const String trainerPostCreate = '/trainer-post-create';
  static const String trainerProfileDetail = '/trainer-profile-detail';
  static const String trainerEditProfile = '/trainer-edit-profile';

  static const String privacyPolicy = '/settings/privacy';
  static const String termsConditions = '/settings/terms';
  static const String helpSupport = '/settings/help';
  static const String aboutApp = '/settings/about';
  static const String imagePreview = '/image-preview';
  static const String timer = '/timer';
  static const String music = '/music';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashScreen(), settings);
      case onboarding:
        return _fadeRoute(const OnboardingScreen(), settings);
      case roleSelection:
        return _slideRoute(const RoleSelectionScreen(), settings);
      
      case login:
        return _slideRoute(const LoginScreen(), settings);
      case ownerRegister:
        return _slideRoute(const OwnerRegisterScreen(), settings);
      case memberRegister:
        return _slideRoute(const MemberRegisterScreen(), settings);
      case trainerRegister:
        return _slideRoute(const TrainerAuthScreen(), settings);
      case forgotPassword:
        return _fadeRoute(const PhoneInputScreen(), settings);
      
      case otpVerify:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return _fadeRoute(
          OtpVerifyScreen(
            verificationId: args['verificationId'] ?? '',
            phone: args['phone'] ?? '',
          ), 
          settings
        );
      
      case resetPassword:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return _fadeRoute(
          ResetPasswordScreen(
            verificationId: args['verificationId'] ?? '',
            smsCode: args['smsCode'] ?? '',
            phone: args['phone'] ?? '',
          ), 
          settings
        );

      case ownerDashboard:
        return _slideRoute(const OwnerDashboard(), settings);
      case memberDashboard:
        return _slideRoute(const MemberDashboard(), settings);
      case trainerDashboard:
        return _slideRoute(const TrainerDashboard(), settings);
      
      case trainerSearch:
        return _slideRoute(const TrainerSearchScreen(), settings);
      case trainerPostCreate:
        final mode = settings.arguments as String? ?? '';
        return _slideRoute(TrainerPostCreateScreen(initialMode: mode), settings);
      case trainerProfileDetail:
        final args = settings.arguments as String?;
        return _slideRoute(TrainerProfileScreen(trainerId: args), settings);
      case trainerEditProfile:
        return _slideRoute(const TrainerEditProfileScreen(), settings);

      case privacyPolicy:
        return _slideRoute(const PrivacyPolicyScreen(), settings);
      case termsConditions:
        return _slideRoute(const TermsConditionsScreen(), settings);
      case helpSupport:
        return _slideRoute(const HelpSupportScreen(), settings);
      case aboutApp:
        return _slideRoute(const AboutAppScreen(), settings);
      case imagePreview:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return _fadeRoute(
          ImagePreviewScreen(
            heroTag: args['heroTag'] ?? '',
            imageUrl: args['imageUrl'] ?? '',
          ), 
          settings
        );

      case timer:
        return _slideRoute(const TimerScreen(), settings);
      case music:
        return _slideRoute(const MusicScreen(), settings);

      default:
        return _fadeRoute(const SplashScreen(), settings);
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static PageRouteBuilder _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 450),
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
