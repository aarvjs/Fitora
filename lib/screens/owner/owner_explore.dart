import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitora/core/constants/app_colors.dart';
import 'package:fitora/widgets/custom_app_bar.dart';
import 'package:fitora/widgets/image_slider_widget.dart';
import 'package:fitora/widgets/product_card.dart';
import 'package:fitora/widgets/add_product_modal.dart';
import 'package:fitora/widgets/membership_plan_modal.dart';

class OwnerExplore extends StatefulWidget {
  const OwnerExplore({super.key});

  @override
  State<OwnerExplore> createState() => _OwnerExploreState();
}

class _OwnerExploreState extends State<OwnerExplore> {
  // Mock data for Products
  final List<Map<String, dynamic>> _allProducts = [
    {
      'id': '1',
      'name': 'Whey Protein',
      'price': '4500',
      'imageUrl': 'https://plus.unsplash.com/premium_photo-1664302152996-03fcb53a0dd5?auto=format&fit=crop&q=80&w=150',
    },
    {
      'id': '2',
      'name': 'Creatine',
      'price': '1200',
      'imageUrl': 'https://images.unsplash.com/photo-1593095948071-474c5cc2989d?auto=format&fit=crop&q=80&w=150',
    },
    {
      'id': '3',
      'name': 'Power Belt',
      'price': '850',
      'imageUrl': 'https://images.unsplash.com/photo-1600881333168-2ef49b341f30?auto=format&fit=crop&q=80&w=150',
    },
    {
      'id': '4',
      'name': 'Gym Gloves',
      'price': '450',
      'imageUrl': 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&q=80&w=150',
    },
  ];

  Future<void> _handleSaveProduct(String name, String price, File? image) async {
    // Mock save logic
    await Future.delayed(const Duration(seconds: 1)); // simulate upload/save

    setState(() {
      _allProducts.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'price': price,
        'imageUrl': '', // mock local won't show the picked image directly without real upload
      });
    });

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Product added globally! (Mock)', style: GoogleFonts.inter()),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showAddModal() {
    AddProductModal.show(context, onSave: _handleSaveProduct);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomAppBar(
              title: 'Explore',
              subtitle: 'Manage gym products & supplements',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Slider
                    const ImageSliderWidget(),
                    const SizedBox(height: 32),

                    // Add Product Horizonal Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Quick Actions',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
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
                          _buildActionCard('Plans', Icons.card_membership_rounded, const Color(0xFF10B981), () {
                            MembershipPlanModal.show(context);
                          }),
                          const SizedBox(width: 12),
                          _buildActionCard('Timer', Icons.timer_outlined, const Color(0xFFF59E0B), () {
                            Navigator.pushNamed(context, '/timer');
                          }),
                          const SizedBox(width: 12),
                          _buildActionCard('Music', Icons.music_note_rounded, const Color(0xFF3B82F6), () {
                            Navigator.pushNamed(context, '/music');
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    // All Products Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'All Products',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _allProducts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text(
                                'No Products Yet',
                                style: GoogleFonts.inter(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.75, // Taller cards
                            ),
                            itemCount: _allProducts.length,
                            itemBuilder: (ctx, idx) {
                              final p = _allProducts[idx];
                              return ProductCard(
                                name: p['name'],
                                price: p['price'],
                                imageUrl: p['imageUrl'],
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
