import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
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
    _loadProjectsFromApi(); // Fetch projects from the API
  }

  // Fetch project list from the API
// Fetch project list from the API
  Future<void> _loadProjectsFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/Project Form'), // Replace with your actual API URL to get projects
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}', // Use proper authorization headers if necessary
        },
      );

      if (response.statusCode == 200) {
        // Decode the response body
        final Map<String, dynamic> data = json.decode(response.body);
        print(response.body);

        // Check if the "data" field exists and is a list
        if (data.containsKey('data') && data['data'] is List) {
          final List<dynamic> projectListData = data['data'];

          setState(() {
            // Extract the project names from the list of project objects
            projectList = projectListData.map((project) => project['name'] as String).toList();
          });
        } else {
          print('Error: No projects found in the response');
        }
      } else {
        // Handle error when response status is not 200
        print('Error: Failed to load projects');
      }
    } catch (e) {
      // Handle any error that occurs during the API request
      print('Error: $e');
    }
  }


  Future<void> _navigateToProjectForm() async {
    final projectName = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProjectForm()),
    );
    if (projectName != null && projectName.isNotEmpty) {
      setState(() {
        projectList.add(projectName); // Add the new project to the list
      });
      _saveProjectToApi(projectName); // Optionally, save the project to the API as well
    }
  }

  // Save new project to the API
  Future<void> _saveProjectToApi(String projectName) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/addProject'), // Replace with your actual API URL to add project
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'project_name': projectName,
        }),
      );

      if (response.statusCode == 200) {
        print('Project added successfully');
      } else {
        print('Error: Failed to add project');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear the login status and username
    await prefs.remove('isLoggedIn');
    await prefs.remove('username');

    // Navigate back to the Login screen
    Get.offAll(Login()); // Using Get.offAll to remove the current screen and go to login screen
  }

  Future<void> MobileDocument(BuildContext context, String projectName) async {
    HttpClient client = HttpClient();
    client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    final url = '$apiUrl/Project Form/$projectName'; // Use project name (or ID) here
    print("Delete URL: " + url);

    try {
      // Use Uri.parse() to convert the string URL into a Uri object
      final response = await ioClient.delete(Uri.parse(url), headers: headers);

      if (response.statusCode == 202) { // HTTP 200 for successful deletion (or 202 depending on your API response)
        // Update the local projectList to remove the deleted project
        setState(() {
          projectList.remove(projectName); // Remove the deleted project from the list
        });

        Get.snackbar(
          "Project Form",
          "Deleted Successfully",
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );
        // Optionally, pop the current screen or refresh the data
        // Navigator.pop(context); // You may also use Get.back() if you're using GetX
      } else {
        String message = 'Request failed with status: ${response.statusCode}';
        if (response.statusCode == 417) {
          final serverMessages = json.decode(response.body)['_server_messages'];
          message = serverMessages ?? message;
        }
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(response.statusCode == 417 ? 'Message' : 'Error'),
            content: Text(message),
            actions: [
              ElevatedButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('An error occurred: $e'),
          actions: [
            ElevatedButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      height = constraints.maxHeight;
      width = constraints.maxWidth;
      if (width <= 1000) {
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
            _handleLogout();
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
            icon: Row(
              children: [
                const Icon(Icons.add, color: Colors.blue), // Icon// Space between icon and text
                MyText(text: "  Add Project", color: Colors.blue, weight: FontWeight.w500)
              ],
            ),
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
                            onPressed: (){
                              MobileDocument(context, projectList[index]);
                            },
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
