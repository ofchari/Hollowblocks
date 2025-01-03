import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetri_hollowblock/view/screens/project_details.dart';
import 'package:vetri_hollowblock/view/screens/project_form.dart';
import 'package:vetri_hollowblock/view/widgets/subhead.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';

import 'login.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late double height;
  late double width;

  // List to store projects
  List<String> projectList = [];

  @override
  void initState() {
    super.initState();
    _loadProjects(); // Load saved projects when the app starts
  }

  // Load projects from SharedPreferences
  Future<void> _loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      projectList = prefs.getStringList('projectList') ?? [];
    });
  }

  // Save projects to SharedPreferences
  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('projectList', projectList);
  }

  // Navigate to the ProjectForm and get the project name
  Future<void> _navigateToProjectForm() async {
    final projectName = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProjectForm()),
    );
    if (projectName != null && projectName.isNotEmpty) {
      setState(() {
        projectList.add(projectName);
      });
      _saveProjects(); // Save the updated list
    }
  }
         /// Logout Logicto clear the user data //
  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved preferences
    Get.offAll(() => const Login()); // Navigate to login screen
  }

  // Delete a project
  void _deleteProject(int index) {
    setState(() {
      projectList.removeAt(index);
    });
    _saveProjects(); // Save the updated list
  }

  @override
  Widget build(BuildContext context) {
    /// Define Sizes
    var size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      height = constraints.maxHeight;
      width = constraints.maxWidth;
      if (width <= 450) {
        return _smallBuildLayout();
      } else {
        return const Text("Please make sure your device is in portrait view");
      }
    });
  }

  Widget _smallBuildLayout() {
    return Scaffold(
      backgroundColor: const Color(0xfff1f2f4),
      appBar: AppBar(
        backgroundColor: const Color(0xfff1f2f4),
        toolbarHeight: 80.h,
        centerTitle: true,
        leading: GestureDetector(
          onTap: (){
            Get.offAll(_handleLogout(context));
          },
            child: Icon(Icons.logout)),
        title: Subhead(
          text: "Dashboard",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: _navigateToProjectForm,
          )
        ],
      ),
      body: SizedBox(
        width: width.w,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20.h),
              if (projectList.isEmpty)
                GestureDetector(
                  onTap: _navigateToProjectForm,
                  child: Container(
                    height: height / 10.h,
                    width: width / 1.2.w,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                    child: Center(
                      child: MyText(
                        text: "Add Project",
                        color: Colors.white,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: projectList.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(7.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.to(() => ProjectDetails());
                            },
                            child: MyText(
                              text: projectList[index],
                              color: Colors.white,
                              weight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProject(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
