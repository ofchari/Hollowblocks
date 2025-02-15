import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:vetri_hollowblock/view/screens/common_reports/reports_all.dart';
import 'package:vetri_hollowblock/view/screens/dashboard.dart';
import 'package:vetri_hollowblock/view/screens/masters_all/master_all.dart';
import 'package:vetri_hollowblock/view/screens/todo.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int selectedIndex = 1;

  final  List<Widget> _screens = [
    ReportsCommon(),
    Dashboard(),
    MasterAll(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: 12), // Adds space between navigation bar and body
        decoration: BoxDecoration(
          color: Colors.white, // Ensuring a clean background
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Adds inner padding
          child: GNav(
            backgroundColor: Colors.white,
            rippleColor: Colors.grey.shade300, // Softer ripple effect
            hoverColor: Colors.grey.shade200,
            haptic: true,
            tabBorderRadius: 10, // More rounded look
            tabActiveBorder: Border.all(color: Colors.purple, width: 1),
            tabBorder: Border.all(color: Colors.grey.shade400, width: 1),
            tabShadow: [
              // BoxShadow(
              //   color: Colors.grey.withOpacity(0.2),
              //   blurRadius: 10,
              //   spreadRadius: 2,
              // )
            ],
            curve: Curves.fastOutSlowIn,
            duration: Duration(milliseconds: 400), // Smoother animation
            gap: 6,
            color: Colors.grey[600],
            activeColor: Colors.purple,
            iconSize: 18, // Slightly larger icons for better readability
            tabBackgroundColor: Colors.purple.withOpacity(0.1),
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            selectedIndex: selectedIndex,
            onTabChange: (value) {
              setState(() {
                selectedIndex = value; // Update selected tab
              });
            },
            tabs: [
              GButton(
                icon: Icons.inventory_outlined,
                text: 'Reports',
              ),
              GButton(
                icon: Icons.home_work_outlined,
                text: 'Projects',
              ),
              GButton(
                icon: Icons.data_exploration_outlined,
                text: 'Masters',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
