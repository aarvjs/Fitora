import 'package:flutter/material.dart';
import 'package:fitora/widgets/bottom_nav.dart';
import 'package:fitora/screens/member/member_home.dart';
import 'package:fitora/screens/member/member_explore.dart';
import 'package:fitora/screens/member/member_trainers.dart';
import 'package:fitora/screens/member/member_plan.dart';
import 'package:fitora/screens/member/member_profile.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  int _currentIndex = 0;

  static const _screens = [
    MemberHome(),
    MemberExplore(),
    MemberTrainers(),
    MemberPlan(),
    MemberProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: MemberBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
