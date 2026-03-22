import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:fitora/core/constants/app_colors.dart';
import 'package:fitora/screens/owner/timer_screen.dart';
import 'package:fitora/screens/owner/music_screen.dart';

class MemberPlan extends StatefulWidget {
  const MemberPlan({super.key});

  @override
  State<MemberPlan> createState() => _MemberPlanState();
}

class _MemberPlanState extends State<MemberPlan> {
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: Text('Not Authenticated', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Plan', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                    Text('Your fitness journey', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Lottie + Plan Banner Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.15), const Color(0xFF7C3AED).withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Lottie.asset(
                        'assets/images/Fitness.json',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 40),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Active Member', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Your Fitness Plan', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: Text('Track. Train. Transform.', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Quick Actions', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(height: 12),

              // Quick Actions row
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _ActionCard(
                      icon: Icons.fitness_center_rounded,
                      label: 'Workout',
                      color: AppColors.primary,
                      onTap: () => _WorkoutDietModal.show(context, uid: _uid!, type: 'workout'),
                    ),
                    const SizedBox(width: 12),
                    _ActionCard(
                      icon: Icons.restaurant_menu_rounded,
                      label: 'Diet',
                      color: const Color(0xFF10B981),
                      onTap: () => _WorkoutDietModal.show(context, uid: _uid!, type: 'diet'),
                    ),
                    const SizedBox(width: 12),
                    _ActionCard(
                      icon: Icons.timer_outlined,
                      label: 'Timer',
                      color: const Color(0xFFF59E0B),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimerScreen())),
                    ),
                    const SizedBox(width: 12),
                    _ActionCard(
                      icon: Icons.music_note_rounded,
                      label: 'Music',
                      color: const Color(0xFF3B82F6),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logs title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Your Logs', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(height: 12),

              // Workout logs
              _WorkoutDietList(uid: _uid!, collection: 'workouts', title: 'Workouts'),
              const SizedBox(height: 16),

              // Diet logs
              _WorkoutDietList(uid: _uid!, collection: 'diets', title: 'Diet'),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────── SMALL ACTION CARD ───────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withValues(alpha: 0.2),
        child: Container(
          width: 80,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.divider)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 7),
              Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────── WORKOUT / DIET LOG LIST (plain Widget, not Sliver) ───────────────
class _WorkoutDietList extends StatelessWidget {
  final String uid;
  final String collection;
  final String title;

  const _WorkoutDietList({required this.uid, required this.collection, required this.title});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(data['day'] ?? '', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(data['text'] ?? '', style: GoogleFonts.inter(color: Colors.white, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────── WORKOUT / DIET MODAL ───────────────
class _WorkoutDietModal {
  static void show(BuildContext context, {required String uid, required String type}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkoutDietSheet(uid: uid, type: type),
    );
  }
}

class _WorkoutDietSheet extends StatefulWidget {
  final String uid;
  final String type;
  const _WorkoutDietSheet({required this.uid, required this.type});

  @override
  State<_WorkoutDietSheet> createState() => _WorkoutDietSheetState();
}

class _WorkoutDietSheetState extends State<_WorkoutDietSheet> {
  String _selectedDay = 'Monday';
  final _textCtrl = TextEditingController();
  bool _saving = false;

  final _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final collection = widget.type == 'workout' ? 'workouts' : 'diets';
      await FirebaseFirestore.instance.collection(collection).add({
        'userId': widget.uid,
        'day': _selectedDay,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.type == 'workout' ? 'Workout' : 'Diet'} saved!', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWorkout = widget.type == 'workout';
    final color = isWorkout ? AppColors.primary : const Color(0xFF10B981);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(color: Color(0xFF141414), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(isWorkout ? Icons.fitness_center_rounded : Icons.restaurant_menu_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Add ${isWorkout ? 'Workout' : 'Diet'}', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),

          Text('SELECT DAY', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              itemBuilder: (_, i) {
                final isSelected = _days[i] == _selectedDay;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = _days[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? color : AppColors.divider),
                    ),
                    child: Text(_days[i].substring(0, 3), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.textSecondary)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Text('PLAN', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          TextField(
            controller: _textCtrl,
            maxLines: 3,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: isWorkout ? 'e.g. Push-ups 3x12, Bench Press 4x8...' : 'e.g. Oats + Banana breakfast, Chicken rice lunch...',
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color, width: 1.5)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
