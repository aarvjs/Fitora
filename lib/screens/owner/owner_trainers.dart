import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitora/core/constants/app_colors.dart';

class OwnerTrainers extends StatefulWidget {
  const OwnerTrainers({super.key});

  @override
  State<OwnerTrainers> createState() => _OwnerTrainersState();
}

class _OwnerTrainersState extends State<OwnerTrainers> {
  final _nameCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  String? _gymId;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _loadGymId();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specialtyCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGymId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (mounted) setState(() => _gymId = doc.data()?['gymId'] as String?);
  }

  Future<void> _addTrainer() async {
    if (_gymId == null) return;
    final name = _nameCtrl.text.trim();
    final specialty = _specialtyCtrl.text.trim();
    final exp = _expCtrl.text.trim();
    if (name.isEmpty || specialty.isEmpty) return;

    setState(() => _adding = true);
    try {
      await FirebaseFirestore.instance.collection('gyms').doc(_gymId).collection('trainers').add({
        'name': name,
        'specialty': specialty,
        'experience': exp,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _nameCtrl.clear();
      _specialtyCtrl.clear();
      _expCtrl.clear();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Trainer added!', style: GoogleFonts.inter()), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), margin: const EdgeInsets.all(20)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    }
    if (mounted) setState(() => _adding = false);
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 20),
            Text('Add Trainer', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 20),
            _field(_nameCtrl, 'Full Name', Icons.person_outline_rounded),
            const SizedBox(height: 14),
            _field(_specialtyCtrl, 'Specialty (e.g. Cardio, Strength)', Icons.star_outline_rounded),
            const SizedBox(height: 14),
            _field(_expCtrl, 'Experience (e.g. 3 years)', Icons.workspace_premium_outlined),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _adding ? null : _addTrainer,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _adding
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Add Trainer', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true, fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trainers', style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                        Text('Manage your training staff', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAddDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 5),
                        Text('Add', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                  ),
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
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.sports_gymnastics_rounded, color: AppColors.primary, size: 32)),
      const SizedBox(height: 16),
      Text('No Trainers Yet', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 6),
      Text('Tap + Add to list your trainers', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
    ]));
  }
}
