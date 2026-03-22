import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitora/core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Privacy Policy', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Information We Collect', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 12),
            Text(
              'We collect information you provide directly to us when you create an account, update your profile, use the interactive features of the App, participate in contests, promotions or surveys, request customer support or otherwise communicate with us.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 32),
            Text('2. How We Use Information', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 12),
            Text(
              'We may use information about you to maintain and improve our App, provide and deliver the products and services you request, process transactions, send you related information, including confirmations and receipts.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 32),
            Text('3. Data Security', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 12),
            Text(
              'We take reasonable measures to help protect information about you from loss, theft, misuse and unauthorized access, disclosure, alteration and destruction.',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
