import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetri_hollowblock/view/screens/project_form.dart';
import 'package:vetri_hollowblock/view/screens/update_project_form.dart';
import 'package:vetri_hollowblock/view/widgets/subhead.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';

import '../universal_key_api/api_url.dart';
import 'login.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late double height;
  late double width;
  List<String> projectList = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      projectList = prefs.getStringList('projectList') ?? [];
    });
  }

  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('projectList', projectList);
  }

  Future<void> _navigateToProjectForm() async {
    final projectName = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProjectForm()),
    );
    if (projectName != null && projectName.isNotEmpty) {
      setState(() {
        projectList.add(projectName);
      });
      _saveProjects();
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAll(() => const Login());
  }

  void _deleteProject(int index) {
    setState(() {
      projectList.removeAt(index);
    });
    _saveProjects();
  }

  @override
  Widget build(BuildContext context) {
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
          onTap: () {
            _handleLogout(context);
          },
          child: const Icon(Icons.logout),
        ),
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
        child: projectList.isEmpty
            ? GestureDetector(
          onTap: _navigateToProjectForm,
          child: Padding(
            padding: EdgeInsets.only(top: 30.0, left: 15.w, right: 15.w),
            child: Container(
              height: height / 4.h,
              width: width / 2.w,
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/hollow.jpg"),
                    fit: BoxFit.cover),
                borderRadius: BorderRadius.circular(7.r),
              ),
            ),
          ),
        )
            : SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20.h),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projectList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      Get.to(() => UpdateProjectForm(projectName: projectList[index]));
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(7.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MyText(
                            text: projectList[index],
                            color: Colors.white,
                            weight: FontWeight.w500,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProject(index),
                          ),
                        ],
                      ),
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
