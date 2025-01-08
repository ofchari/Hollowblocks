import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vetri_hollowblock/view/screens/employee/employee.dart';
import 'package:vetri_hollowblock/view/screens/file_upload.dart';
import 'package:vetri_hollowblock/view/screens/materials/material_details.dart';
import 'package:vetri_hollowblock/view/screens/todo.dart';
import 'package:vetri_hollowblock/view/screens/project_forms/update_project_form.dart';
import '../widgets/subhead.dart';
import 'reports/all_reports.dart'; // Custom widget to style your text


class TabsPages extends StatefulWidget {
  const TabsPages({super.key, required this.projectName});
  final String projectName;

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
    _tabController = TabController(length: 6, vsync: this); // Number of tabs
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
          return Text("Please make sure your device is in portrait view");
        }
      },
    );
  }

  Widget _smallBuildLayout() {
    return Scaffold(
      backgroundColor: const Color(0xfff1f2f4),
      appBar: AppBar(
        backgroundColor: const Color(0xfff1f2f4),
        toolbarHeight: 80.h,
        centerTitle: true,
        title: Subhead(
          text: "User Tabs",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Update Project'),
            Tab(text: 'Employee',),
            Tab(text: 'Material',),
            Tab(text: 'Files Upload',),
            Tab(text: 'Todo'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Each tab's content
          UpdateProjectForm(projectName: '${widget.projectName}'),
          Employee(),
          MaterialScreen(),
          FileUpload(),
          Todo(),
          AllReports(),
        ],
      ),
    );
  }
}
