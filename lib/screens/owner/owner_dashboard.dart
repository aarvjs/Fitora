import 'package:flutter/material.dart';
import 'package:fitora/widgets/bottom_nav.dart';
import 'package:fitora/screens/owner/owner_home.dart';
import 'package:fitora/screens/owner/owner_members.dart';
import 'package:fitora/screens/owner/owner_explore.dart';
import 'package:fitora/screens/owner/owner_trainers.dart';
import 'package:fitora/screens/owner/owner_profile.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _currentIndex = 0;

  static const _screens = [
    OwnerHome(),
    OwnerMembers(),
    OwnerExplore(),
    OwnerTrainers(),
    OwnerProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: OwnerBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
