import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitora/core/constants/app_colors.dart';

class TrainerListScreen extends StatefulWidget {
  final String gymId;
  const TrainerListScreen({super.key, required this.gymId});

  @override
  State<TrainerListScreen> createState() => _TrainerListScreenState();
}

class _TrainerListScreenState extends State<TrainerListScreen> {
  String _query = '';

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Trainer', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Remove this internal trainer?', style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); FirebaseFirestore.instance.collection('gym_trainers').doc(docId).delete(); },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text('Trainers', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ── Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search trainers by name or phone...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                  filled: true, fillColor: AppColors.backgroundCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('gym_trainers').where('gymId', isEqualTo: widget.gymId).snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  final all = snap.data?.docs ?? [];
                  final docs = _query.isEmpty
                      ? all
                      : all.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          final name = (data['name'] as String? ?? '').toLowerCase();
                          final phone = (data['phone'] as String? ?? '').toLowerCase();
                          return name.contains(_query) || phone.contains(_query);
                        }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sports_outlined, color: AppColors.textMuted, size: 48),
                          const SizedBox(height: 12),
                          Text(_query.isEmpty ? 'No trainers added yet.' : 'No results found.',
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final id = docs[i].id;
                      final name = d['name'] as String? ?? 'Trainer';
                      final phone = d['phone'] as String? ?? '';
                      final address = d['address'] as String? ?? '';
                      final salary = d['salary']?.toString() ?? '0';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.2)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0EA5E9))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                  if (phone.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(phone, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                  if (address.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(address, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                    child: Text('₹$salary / month', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF0EA5E9), fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                              onPressed: () => _confirmDelete(id),
                            ),
                          ],
                        ),
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
}
