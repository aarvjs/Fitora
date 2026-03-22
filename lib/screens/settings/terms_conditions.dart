import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitora/core/constants/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Terms & Conditions', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Acceptance of Terms', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 12),
            Text(
              'By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 32),
            Text('2. User Conduct', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 12),
            Text(
              'You agree to use the app only for lawful purposes. You agree not to take any action that might compromise the security of the app, render the app inaccessible to others or otherwise cause damage to the app or its content.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 32),
            Text('3. Modifications', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 12),
            Text(
              'We reserve the right to modify these terms from time to time at our sole discretion. Any such modifications shall be effective immediately upon posting.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
