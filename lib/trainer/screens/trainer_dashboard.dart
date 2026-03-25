import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'trainer_home_screen.dart';
import 'trainer_global_feed_screen.dart';
import 'trainer_activity_screen.dart';
import 'trainer_profile_screen.dart';

class TrainerDashboard extends StatefulWidget {
  const TrainerDashboard({super.key});

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TrainerHomeScreen(),
    const TrainerGlobalFeedScreen(),
    const SizedBox.shrink(), // Placeholder for Center Post Button to maintain index layout
    const TrainerActivityScreen(),
    const TrainerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/trainer-post-create');
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 10,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(icon: Icons.home_rounded, label: 'Home', index: 0),
              _buildTabItem(icon: Icons.public, label: 'Feed', index: 1),
              const SizedBox(width: 48), // spacing for the center FAB
              _buildTabItem(icon: Icons.history, label: 'Activity', index: 3),
              _buildTabItem(icon: Icons.person_rounded, label: 'Profile', index: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : const Color(0xFFAAAAAA);
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(color: color, fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)
            ),
          ],
        ),
      ),
    );
  }
}
