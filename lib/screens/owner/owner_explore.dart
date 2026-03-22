import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitora/core/constants/app_colors.dart';
import 'package:fitora/widgets/custom_app_bar.dart';
import 'package:fitora/widgets/image_slider_widget.dart';
import 'package:fitora/widgets/product_card.dart';
import 'package:fitora/widgets/add_product_modal.dart';
import 'package:fitora/widgets/membership_plan_modal.dart';
import 'package:fitora/core/utils/cloudinary_upload.dart';

class OwnerExplore extends StatefulWidget {
  const OwnerExplore({super.key});

  @override
  State<OwnerExplore> createState() => _OwnerExploreState();
}

class _OwnerExploreState extends State<OwnerExplore> {
  String? _uid;
  String? _gymId;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingUser = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _uid = user.uid;
          _gymId = doc.data()?['gymId'] as String?;
          _loadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _handleSaveProduct(String name, String price, File? image) async {
    if (_uid == null || _gymId == null) return;

    String? imageUrl;
    if (image != null) {
      imageUrl = await CloudinaryService.uploadImage(image);
    }

    await FirebaseFirestore.instance.collection('products').add({
      'name': name,
      'price': price,
      'imageUrl': imageUrl ?? '',
      'gymId': _gymId,
      'ownerId': _uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Product added successfully!', style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _confirmDeleteProduct(String docId, String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Product', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text('Are you sure? This cannot be undone.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance.collection('products').doc(docId).delete();
    if (imageUrl.isNotEmpty) CloudinaryService.deleteImage(imageUrl);
  }

  Future<void> _confirmDeletePlan(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Plan', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text('Are you sure? Members won\'t see this plan anymore.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseFirestore.instance.collection('plans').doc(docId).delete();
  }

  void _showAddModal() {
    AddProductModal.show(context, onSave: _handleSaveProduct);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomAppBar(title: 'Explore', subtitle: 'Manage gym products & supplements'),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ImageSliderWidget(),
                    const SizedBox(height: 32),

                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text('Quick Actions', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 96,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          _buildActionCard('Add Product', Icons.add_circle_outline_rounded, AppColors.primary, _showAddModal),
                          const SizedBox(width: 12),
                          _buildActionCard('Add Plan', Icons.card_membership_rounded, const Color(0xFF10B981), () => MembershipPlanModal.show(context)),
                          const SizedBox(width: 12),
                          _buildActionCard('Timer', Icons.timer_outlined, const Color(0xFFF59E0B), () => Navigator.pushNamed(context, '/timer')),
                          const SizedBox(width: 12),
                          _buildActionCard('Music', Icons.music_note_rounded, const Color(0xFF3B82F6), () => Navigator.pushNamed(context, '/music')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Plans Section
                    if (_gymId != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                        child: Row(
                          children: [
                            Expanded(child: Text('Membership Plans', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
                            Text('Hold to delete', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _OwnerPlansRow(gymId: _gymId!, onDeletePlan: _confirmDeletePlan),
                      const SizedBox(height: 32),
                    ],

                    // Products Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: Row(
                        children: [
                          Expanded(child: Text('My Products', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
                          Text('Hold to delete', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (_uid == null)
                      const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                    else
                      StreamBuilder<QuerySnapshot>(
                        // No orderBy to avoid requiring a composite index — sort client-side
                        stream: FirebaseFirestore.instance
                            .collection('products')
                            .where('ownerId', isEqualTo: _uid)
                            .snapshots(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
                          }
                          if (snap.hasError) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text('Error loading products: ${snap.error}', style: GoogleFonts.inter(color: Colors.redAccent)),
                            );
                          }
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
                          if (docs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 48),
                                    const SizedBox(height: 12),
                                    Text('No Products Yet', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 15)),
                                    const SizedBox(height: 6),
                                    Text('Tap "Add Product" to get started', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                                  ],
                                ),
                              ),
                            );
                          }
                          return GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: docs.length,
                            itemBuilder: (ctx, idx) {
                              final doc = docs[idx];
                              final data = doc.data() as Map<String, dynamic>;
                              return ProductCard(
                                name: data['name'] ?? '',
                                price: data['price'] ?? '0',
                                imageUrl: data['imageUrl'] as String?,
                                onLongPress: () => _confirmDeleteProduct(doc.id, data['imageUrl'] ?? ''),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withValues(alpha: 0.15),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          width: 88,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────── OWNER PLANS ROW ───────────────
class _OwnerPlansRow extends StatelessWidget {
  final String gymId;
  final Future<void> Function(String docId) onDeletePlan;
  const _OwnerPlansRow({required this.gymId, required this.onDeletePlan});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('plans').where('gymId', isEqualTo: gymId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(height: 90, child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 10),
                  Text('No plans yet. Tap "Add Plan" to create one.', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          );
        }
        return SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              final doc = docs[idx];
              final data = doc.data() as Map<String, dynamic>;
              return GestureDetector(
                onLongPress: () => onDeletePlan(doc.id),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.85), const Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.card_membership_rounded, color: Colors.white70, size: 16),
                          const Spacer(),
                          const Icon(Icons.more_horiz_rounded, color: Colors.white38, size: 16),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['planName'] ?? 'Plan', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('₹${data['price'] ?? '0'}', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
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
