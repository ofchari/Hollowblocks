import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vetri_hollowblock/view/screens/dashboard.dart';
import 'package:vetri_hollowblock/view/screens/employee/employee.dart';
import 'package:vetri_hollowblock/view/screens/file_upload.dart';
import 'package:vetri_hollowblock/view/screens/materials/material_details.dart';
import 'package:vetri_hollowblock/view/screens/todo.dart';
import 'package:vetri_hollowblock/view/screens/project_forms/update_project_form.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';
import '../widgets/subhead.dart';
import 'reports/all_reports.dart'; // Custom widget to style your text


class TabsPages extends StatefulWidget {
  const TabsPages({super.key, required this.projectName, this.initialTabIndex = 0});
  final String projectName;
  final int initialTabIndex; // New parameter for initial tab index

  @override
  State<TabsPages> createState() => _TabsPagesState();
}

class _TabsPagesState extends State<TabsPages> with TickerProviderStateMixin {
  late double height;
  late double width;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this, initialIndex: widget.initialTabIndex);
  }

          /// Will Pop Scope Logic //
  /// wiil popscope logic //
  Future<bool> popScopes(BuildContext context) async {
    return await Get.dialog(
      AlertDialog(
        title: const Text("Are Sure Want to exit? "),
        titleTextStyle: GoogleFonts.poppins(
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.green,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Get.offAll(() => const Dashboard());  // Navigate to BottomNavigation and replace the current page
            },
            child: const Text("Yes", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade500),
            onPressed: () {
              Navigator.pop(context);  // Just close the dialog and stay on the current page
            },
            child: const Text("No", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        height = constraints.maxHeight;
        width = constraints.maxWidth;

        if (width <= 1000) {
          return _smallBuildLayout();
        } else {
          return const Center(child: Text("Please make sure your device is in portrait view"));
        }
      },
    );
  }

  Widget _smallBuildLayout() {
    return WillPopScope(
      onWillPop: ()=>popScopes(context),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xfff1f2f4),
        appBar: AppBar(
          backgroundColor: Colors.blue,
          toolbarHeight: 80.h,
          centerTitle: true,
          title: Subhead(
            text: "User Tabs",
            color: Colors.white,
            weight: FontWeight.w500,
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.blue,
            labelStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.black),
            tabs: const [
              Tab(child: MyText(text: "Update Project", color: Colors.white, weight: FontWeight.w500),),
              Tab(child: MyText(text: "Employee", color: Colors.white, weight: FontWeight.w500),),
              Tab(child: MyText(text: "Material", color: Colors.white, weight: FontWeight.w500),),
              Tab(child: MyText(text: "Files Upload", color: Colors.white, weight: FontWeight.w500),),
              Tab(child: MyText(text: "Todo", color: Colors.white, weight: FontWeight.w500),),
              Tab(child: MyText(text: "Reports", color: Colors.white, weight: FontWeight.w500),),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            UpdateProjectForm(projectName: widget.projectName),
            Employee(),
            MaterialScreen(),
            FileUpload(),
            Todo(),
            AllReports(),
          ],
        ),
      ),
    );
  }
}


