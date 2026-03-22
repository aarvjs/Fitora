import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitora/core/constants/app_colors.dart';
import 'package:fitora/widgets/custom_app_bar.dart';
import 'package:fitora/widgets/search_bar_widget.dart';
import 'package:fitora/widgets/member_card.dart';

class OwnerMembers extends StatefulWidget {
  const OwnerMembers({super.key});

  @override
  State<OwnerMembers> createState() => _OwnerMembersState();
}

class _OwnerMembersState extends State<OwnerMembers> {
  String _searchQuery = "";

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Member', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to remove this member from your gym? They will lose access to the member dashboard.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeDelete(docId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Remove', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDelete(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Member successfully removed.', style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing member: $e', style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: uid == null 
        ? const Center(child: Text('Not Authenticated', style: TextStyle(color: Colors.white)))
        : FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, ownerSnap) {
            
            final isOwnerLoading = ownerSnap.connectionState == ConnectionState.waiting;
            final ownerData = ownerSnap.data?.data() as Map<String, dynamic>?;
            final gymId = ownerData?['gymId'] as String?;

            return Column(
              children: [
                CustomAppBar(
                  title: 'Members',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isOwnerLoading ? 'LOADING...' : (gymId ?? 'UNKNOWN'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SearchBarWidget(
                    hintText: 'Search by name or phone...',
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                Expanded(
                  child: isOwnerLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : gymId == null
                          ? Center(child: Text('Failed to load Gym Data', style: GoogleFonts.inter(color: AppColors.textSecondary)))
                          : StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .where('gymId', isEqualTo: gymId)
                                  .where('role', isEqualTo: 'member')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                                }
                                if (snapshot.hasError) {
                                  return Center(child: Text('Error loading members', style: GoogleFonts.inter(color: AppColors.textSecondary)));
                                }

                                final docs = snapshot.data?.docs ?? [];

                                // Filter members locally by search query
                                final searchLower = _searchQuery.toLowerCase();
                                final filteredDocs = docs.where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final name = (data['name'] as String?)?.toLowerCase() ?? '';
                                  final phone = (data['phone'] as String?)?.toLowerCase() ?? '';
                                  return name.contains(searchLower) || phone.contains(searchLower);
                                }).toList();

                                if (filteredDocs.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 72,
                                          height: 72,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.group_off_rounded, color: AppColors.primary, size: 32),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _searchQuery.isNotEmpty ? 'No matches found' : 'No Members Yet',
                                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                                        ),
                                        if (_searchQuery.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              'Share your Gym ID to invite members',
                                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                                  itemCount: filteredDocs.length,
                                  itemBuilder: (ctx, idx) {
                                    final d = filteredDocs[idx];
                                    final data = d.data() as Map<String, dynamic>;
                                    
                                    // Calculate joined text
                                    final createdAt = data['createdAt'] as Timestamp?;
                                    String joinedText = 'Unknown';
                                    if (createdAt != null) {
                                      final joined = createdAt.toDate();
                                      final diff = DateTime.now().difference(joined);
                                      if (diff.inDays == 0) {
                                        joinedText = '1D';
                                      } else if (diff.inDays < 30) {
                                        joinedText = '${diff.inDays}D';
                                      } else {
                                        final months = diff.inDays ~/ 30;
                                        if (months < 12) {
                                          joinedText = '${months}M';
                                        } else {
                                          final years = diff.inDays ~/ 365;
                                          joinedText = '${years}Y';
                                        }
                                      }
                                    }

                                    return MemberCard(
                                      name: data['name'] ?? 'Unknown Member',
                                      phone: data['phone'] ?? 'No Phone',
                                      joinedText: joinedText,
                                      imageUrl: data['avatarUrl'] ?? data['profileImage'] ?? '',
                                      onDelete: () => _confirmDelete(d.id),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }
}
