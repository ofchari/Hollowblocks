import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:vetri_hollowblock/view/screens/common_reports/reports_all.dart';
import 'package:vetri_hollowblock/view/screens/dashboard.dart';
import 'package:vetri_hollowblock/view/screens/masters_all/master_all.dart';

class BottomNavigation extends StatefulWidget {

   const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  final List<Widget> _screens = [
    ReportsCommon(),
    Dashboard(),
    MasterAll(),
  ];

  @override
  Widget build(BuildContext context) {
    final BottomNavigationController navController = Get.put(BottomNavigationController());

    return Obx(() => Scaffold(
      body: IndexedStack(
        index: navController.selectedIndex.value,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: GNav(
            backgroundColor: Colors.white,
            rippleColor: Colors.grey.shade300,
            hoverColor: Colors.grey.shade200,
            haptic: true,
            tabBorderRadius: 10,
            tabActiveBorder: Border.all(color: Colors.purple, width: 1),
            tabBorder: Border.all(color: Colors.grey.shade400, width: 1),
            curve: Curves.fastOutSlowIn,
            duration: const Duration(milliseconds: 400),
            gap: 6,
            color: Colors.grey[600],
            activeColor: Colors.purple,
            iconSize: 18,
            tabBackgroundColor: Colors.purple.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            selectedIndex: navController.selectedIndex.value,
            onTabChange: (index) {
              navController.updateIndex(index);
            },
            tabs:  [
              GButton(icon: Icons.inventory_outlined, text: 'Reports'),
              GButton(icon: Icons.home_work_outlined, text: 'Projects'),
              GButton(icon: Icons.data_exploration_outlined, text: 'Masters'),
            ],
          ),
        ),
      ),
    ));
  }
}

class BottomNavigationController extends GetxController {
  var selectedIndex = 1.obs; // Default index (Dashboard)

  void updateIndex(int index) {
    selectedIndex.value = index;
  }
}

