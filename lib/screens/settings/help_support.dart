import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitora/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('Help & Support', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text('How can we help you?', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 12),
                  Text('It looks like you are experiencing problems with our process. We are here to help so please get in touch with us.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 32),
                  
                  // Use IntrinsicWidth so button expands to native width without overflowing
                  IntrinsicWidth(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: 'arvindyadav70075@gmail.com',
                          queryParameters: {'subject': 'Fitora App Support Request'},
                        );
                        if (await canLaunchUrl(emailUri)) {
                          await launchUrl(emailUri);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open email client.')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.email_rounded, color: Colors.white, size: 20),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Email: arvindyadav70075@gmail.com',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
