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

              // Logs title with hint
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: Text('Your Logs', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
                    Text('Hold to delete', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Workout logs (Horizontal row starting with image)
              _WorkoutDietList(uid: _uid!, collection: 'workouts', title: 'Workouts', imageUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=400&q=80'),
              
              const SizedBox(height: 24),

              // Diet logs (Horizontal row starting with image)
              _WorkoutDietList(uid: _uid!, collection: 'diets', title: 'Diet', imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=400&q=80'),
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

// ─────────────── WORKOUT / DIET LOG LIST (Horizontal Card Style) ───────────────
class _WorkoutDietList extends StatelessWidget {
  final String uid;
  final String collection;
  final String title;
  final String imageUrl;

  const _WorkoutDietList({required this.uid, required this.collection, required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isWorkout = collection == 'workouts';
    // Green accent color applied across both types as requested
    const accentColor = Color(0xFF10B981);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).where('userId', isEqualTo: uid).snapshots(),
      builder: (context, snap) {
        final isLoading = snap.connectionState == ConnectionState.waiting;
        final docs = snap.data?.docs ?? [];
        
        // Sort client-side by createdAt descending
        docs.sort((a, b) {
          final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return SizedBox(
          height: 140, // Height for compact horizontal cards
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: isLoading ? 2 : (docs.isEmpty ? 2 : docs.length + 1), // +1 for the header image card
            itemBuilder: (context, index) {
              
              // 1. The Header Image Card
              if (index == 0) {
                return Container(
                  width: 120, // Compact header card
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      title,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                  ),
                );
              }

              // 2. Loading State Placeholder
              if (isLoading && index == 1) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Center(child: CircularProgressIndicator(color: accentColor)),
                );
              }

              // 3. Empty State Card
              if (docs.isEmpty && index == 1) {
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isWorkout ? Icons.fitness_center_rounded : Icons.restaurant_menu_rounded, color: AppColors.textMuted, size: 24),
                      const SizedBox(height: 8),
                      Text('No $title added. Tap above to add.', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.3), textAlign: TextAlign.center),
                    ],
                  ),
                );
              }

              // 4. Actual Data Cards
              final doc = docs[index - 1]; // Offset index by 1 because of header card
              final data = doc.data() as Map<String, dynamic>;
              
              return GestureDetector(
                onLongPress: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.backgroundCard,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text('Delete $title', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800)),
                      content: Text('Delete this log?', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted))),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w700))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirebaseFirestore.instance.collection(collection).doc(doc.id).delete();
                  }
                },
                child: Container(
                  width: 160, // Smaller, compact width
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.surface, AppColors.surface.withValues(alpha: 0.5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5), // Beautiful green accent border
                    boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                            child: Text(data['day'] ?? '', style: GoogleFonts.inter(color: accentColor, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                          const Spacer(),
                          const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted, size: 14),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Text(
                          data['text'] ?? '',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, height: 1.4),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
