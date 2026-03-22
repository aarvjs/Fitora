import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitora/core/constants/app_colors.dart';

class MemberTrainers extends StatefulWidget {
  const MemberTrainers({super.key});

  @override
  State<MemberTrainers> createState() => _MemberTrainersState();
}

class _MemberTrainersState extends State<MemberTrainers> {
  String? _gymId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (mounted) setState(() => _gymId = doc.data()?['gymId'] as String?);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trainers', style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                  Text('Your gym\'s training staff', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _gymId == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('gyms').doc(_gymId).collection('trainers').orderBy('createdAt', descending: true).snapshots(),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) return _emptyState();
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final d = docs[i].data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _trainerCard(d['name'] ?? '', d['specialty'] ?? '', d['experience'] ?? ''),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trainerCard(String name, String specialty, String exp) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'T', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(specialty, style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                if (exp.isNotEmpty) Text(exp, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.sports_gymnastics_rounded, color: AppColors.primary, size: 32)),
      const SizedBox(height: 16),
      Text('No Trainers Available', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 6),
      Text('Your gym owner hasn\'t added trainers yet.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
    ]));
  }
}
