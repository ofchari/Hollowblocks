import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:vetri_hollowblock/view/screens/project_forms/project_form.dart';
import 'package:vetri_hollowblock/view/screens/tabs_pages.dart';
import 'package:vetri_hollowblock/view/screens/todo.dart';
import 'package:vetri_hollowblock/view/widgets/heading.dart';
import 'package:vetri_hollowblock/view/widgets/subhead.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';
import '../universal_key_api/api_url.dart';
import 'common_reports/reports_all.dart';
import 'login.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late double height;
  late double width;
  List<Map<String, dynamic>> projectList = [];
  Map<String, dynamic> selectedFilters = {};
  Map<String, List<String>> dropdownData = {};
  Map<String, Map<String, dynamic>> projectAmounts = {};
  final SessionManager sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    _loadProjectsFromApi(); // Fetch projects from the API
    _fetchFilterFields(); // Fetch filter fields
  }

  Future<void> _navigateToProjectForm() async {
    final projectName = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProjectForm()),
    );
    if (projectName != null && projectName.isNotEmpty) {
      // Immediately reload projects from API
      await _loadProjectsFromApi();
    }
  }

  // Save new project to the API
  Future<void> _saveProjectToApi(String projectName) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/Project Form/$projectName'),
        // Replace with your actual API URL to add project
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

  // Add new method to fetch in/out amounts
  Future<void> _fetchProjectAmounts(String projectName) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
      ((X509Certificate cert, String host, int port) => true);
      IOClient ioClient = IOClient(client);

      final response = await ioClient.get(
        Uri.parse('https://vetri.regenterp.com/api/method/regent.sales.client.get_mobile_in_out_amt?name=$projectName'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
          'Content-Type': 'application/json',
        },
      );

      print("Response for $projectName:");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData.containsKey('message') && responseData['message'] is List && responseData['message'].isNotEmpty) {
          // Get the first item from the array
          final data = responseData['message'][0];

          if (mounted) {
            setState(() {
              projectAmounts[projectName] = {
                'in_amount': (data['in_amount'] ?? 0.0).toStringAsFixed(2),
                'out_amount': (data['out_amount'] ?? 0.0).toStringAsFixed(2),
              };
            });
            print("Updated amounts for $projectName: ${projectAmounts[projectName]}");
          }
        } else {
          print('Invalid response format for $projectName: $responseData');
          // Set default values if the response format is invalid
          if (mounted) {
            setState(() {
              projectAmounts[projectName] = {
                'in_amount': '0.00',
                'out_amount': '0.00',
              };
            });
          }
        }
      } else {
        print('Error fetching amounts for $projectName: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error fetching amounts for $projectName: $e');
      print('Stack trace: $stackTrace');
      // Set default values in case of error
      if (mounted) {
        setState(() {
          projectAmounts[projectName] = {
            'in_amount': '0.00',
            'out_amount': '0.00',
          };
        });
      }
    }
  }


  Future<void> MobileDocument(BuildContext context, String projectName) async {
    HttpClient client = HttpClient();
    client.badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    final url =
        '$apiUrl/Project Form/$projectName'; // Use project name (or ID) here
    print("Delete URL: $url");

    try {
      // Use Uri.parse() to convert the string URL into a Uri object
      final response = await ioClient.delete(Uri.parse(url), headers: headers);

      if (response.statusCode == 202) {
        // HTTP 200 for successful deletion (or 202 depending on your API response)
        // Update the local projectList to remove the deleted project
        setState(() {
          projectList
              .remove(projectName); // Remove the deleted project from the list
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

  Future<void> _fetchFilterFields() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$apiUrl/Project Form?fields=["work","work_type","scheme_name","scheme_group","work_group","agency_name","district","block","village"]'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('data') && data['data'] is List) {
          final List<dynamic> filterData = data['data'];
          print(
              'Filter data fetched successfully: ${data['data']}'); // Add debug logs

          // Collect unique field values for dropdowns
          Map<String, Set<String>> tempDropdownData = {
            'work': {},
            'work_type': {},
            'scheme_name': {},
            'scheme_group': {},
            'work_group': {},
            'agency_name': {},
            'district': {},
            'block': {},
            'village': {},
            // 'Construction Status': {},
          };

          for (var item in filterData) {
            tempDropdownData.forEach((key, value) {
              if (item[key] != null) value.add(item[key]);
            });
          }

          if (mounted) {
            setState(() {
              dropdownData = tempDropdownData
                  .map((key, value) => MapEntry(key, value.toList()));
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching filter fields: $e');
    }
  }

  Future<void> _loadProjectsFromApi({Map<String, dynamic>? filters}) async {
    try {
      // Create proper filter string for API
      String filterString = '';
      if (filters != null && filters.isNotEmpty) {
        // Convert filters to the format expected by your API
        List<List<dynamic>> filterList = [];
        filters.forEach((key, value) {
          if (value != null) {
            filterList.add([key, "=", value]);
          }
        });
        if (filterList.isNotEmpty) {
          filterString = '&filters=${json.encode(filterList)}';
        }
      }

      // Updated URL construction with proper filter format
      final url =
          Uri.parse('$apiUrl/Project Form?fields=["name","work","scheme_name","scheme_group","work_group","agency_name","district","block","village"]$filterString');
      print('Request URL: $url'); // Debug log

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
        },
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('data') && data['data'] is List) {
          final List<dynamic> projectListData = data['data'];
          if (mounted) {
            setState(() {
              projectList = projectListData.map((project) {
                return {
                  "name": project['name'] ?? "",
                  "work": project['work'] ?? "",
                  "scheme_name": project['scheme_name'] ?? "",
                  "scheme_group": project['scheme_group'] ?? "",
                  "work_group": project['work_group'] ?? "",
                  "agency_name": project['agency_name'] ?? "",
                  "district": project['district'] ?? "",
                  "block": project['block'] ?? "",
                  "village": project['village'] ?? "",
                  // "Construction Status": project['Construction Status'] ?? "",
                };
              }).toList();

              // Fetch amounts for each project
              for (var project in projectList) {
                _fetchProjectAmounts(project['name']);
              }
            });
          }
        }
      } else {
        print(
            'Error: Failed to load projects. Status code: ${response.statusCode}');
        print(
            'Response body: ${response.body}'); // Add this to see error details
        if (mounted) {
          Get.snackbar(
            "Error",
            "Failed to load projects: ${response.statusCode}",
            colorText: Colors.white,
            backgroundColor: Colors.red,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      print('Error loading projects: $e');
      if (mounted) {
        Get.snackbar(
          "Error",
          "Failed to load projects: $e",
          colorText: Colors.white,
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Widget _buildFilterDropdown(String fieldName) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Select ${fieldName.replaceAll('_', ' ').capitalize}',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            ),
            value: selectedFilters[fieldName],
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text('All ${fieldName.replaceAll('_', ' ').capitalize}'),
              ),
              ...?dropdownData[fieldName]?.map((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                if (value == null) {
                  selectedFilters.remove(fieldName);
                } else {
                  selectedFilters[fieldName] = value;
                }
              });
            },
          ),
        ),
      ),
    );
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
        return const Text("Please make sure your device is in portrait view");
      }
    });
  }

  Widget _smallBuildLayout() {
    return Scaffold(
      drawer: Drawer( // Adding Drawer
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader( // Header Section
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage("assets/hollow.jpg"),fit: BoxFit.cover),
                  ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CircleAvatar(
                  //   radius: 30,
                  //   backgroundColor: Colors.white,
                  //   child: Icon(Icons.person, size: 40, color: Colors.blue),
                  // ),
                  SizedBox(height: 80),
                  MyText(text: "Vetri", color: Colors.black, weight: FontWeight.w500),
                  MyText(text: "kbscontruction@gmail.com", color: Colors.black, weight: FontWeight.w500),
                ],
              ),
            ),
            _drawerItem(icon: Icons.home, text: "Home", onTap: () {
              Navigator.pop(context);
            }),
            _drawerItem(icon: Icons.data_exploration, text: "Reports", onTap: () {
              Get.to(ReportsCommon());
            }),
            _drawerItem(icon: Icons.note_alt_sharp, text: "To Do", onTap: () {
              Get.to(Todo());
            }),
            _drawerItem(icon: Icons.logout, text: "Logout", onTap: () {
              sessionManager.logout(); // Call the logout method
            }),
          ],
        ),
      ),

      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 80.h,
        centerTitle: true,
        // title: Subhead(
        //   text: "Dashboard",
        //   color: Colors.black,
        //   weight: FontWeight.w500,
        // ),
        actions: [
          Padding(
            padding:  EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: Row(
                children: [
                  const Icon(Icons.add, color: Colors.blue,size: 20,),
                  Text("Project",style: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 16.5.sp,fontWeight: FontWeight.w500,color: Colors.blue)),)
                ],
              ),
              onPressed: _navigateToProjectForm,
            ),
          ),
        ],
      ),
        body: RefreshIndicator(
          onRefresh: () async {
            await _loadProjectsFromApi();
            return Future.value();
          },
          child: SizedBox(
            width: width.w,
            child: Column(
              children: [
                // Action Buttons Row
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double buttonWidth = (constraints.maxWidth - 40.w) / 3; // Auto-adjust width
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            title: "Material",
                            color: Colors.lightGreen.shade700,
                            icon: Icons.touch_app_rounded,
                            onTap: () => Get.to(ReportsCommon()),
                            width: buttonWidth, // Adjusted Width
                          ),
                          _buildActionButton(
                            title: "Reports",
                            color: Color(0xff947be4),
                            icon: Icons.insert_chart_outlined,
                            onTap: () => Get.to(ReportsCommon()),
                            width: buttonWidth, // Adjusted Width
                          ),
                          _buildActionButton(
                            title: "To Do",
                            color: Color(0xff01ab9d),
                            icon: Icons.checklist,
                            onTap: () => Get.to(Todo()),
                            width: buttonWidth, // Adjusted Width
                          ),
                        ],
                      );
                    },
                  ),
                ),

                SizedBox(height: 10.h), // Add spacing if needed
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0), // Reduced unnecessary padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Heading(text: "   Projects", color: Colors.black, weight: FontWeight.w600), // Removed unnecessary spaces
                      IconButton(
                        icon: Icon(Icons.filter_list, color: Colors.grey), // Removed unnecessary Row
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r), // Smooth rounded corners
                                ),
                                title: Center(
                                  child: Subhead(text: "Apply Filters", color: Colors.black, weight: FontWeight.w500)
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start, // Align dropdowns properly
                                    children: dropdownData.keys.map((field) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(vertical: 6.h), // Better spacing
                                        child: _buildFilterDropdown(field),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                actions: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Clear Button
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: Colors.grey[300], // Subtle color
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            selectedFilters.clear();
                                          });
                                          Navigator.of(context).pop();
                                          _loadProjectsFromApi();
                                        },
                                        icon: Icon(Icons.clear, size: 18.sp),
                                        label: Text("Clear", style: TextStyle(fontSize: 14.sp)),
                                      ),

                                      // Apply Button
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.blue, // Highlight apply button
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _loadProjectsFromApi(filters: selectedFilters);
                                        },
                                        icon: Icon(Icons.check, size: 18.sp),
                                        label: Text("Apply", style: TextStyle(fontSize: 14.sp)),
                                      ),
                                    ],
                                  ),
                                ],
                              );

                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
// Project List or Placeholder
                Expanded(
                  child: projectList.isEmpty
                      ? GestureDetector(
                    onTap: _navigateToProjectForm,
                    child: Padding(
                      padding: EdgeInsets.all(16), // Used a standard padding
                      child: Container(
                        height: height / 4,
                        width: width / 1.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: AssetImage("assets/hollow.jpg"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  )
                      : ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 3), // Reduce extra spacing
                    itemCount: projectList.length,
                    itemBuilder: (context, index) {
                      final project = projectList[index];
                      return _buildProjectCard(project);
                    },
                  ),
                ),

              ],
            ),
          ),
        ),
    );
  }
         /// Drawer Help logic method //
  Widget _drawerItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue                    ),
      title: Text(text, style: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 16.sp,fontWeight: FontWeight.w500,color: Colors.black))),
      onTap: onTap,
    );
  }

  // Method to create action buttons (Reports & To-Do)
  Widget _buildActionButton({
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    double? width, // Allow dynamic width
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100.h, // Reduced height to fit better
        width: width ?? 120.w, // Use dynamic width if provided
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column( // Changed to Column for better layout
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26.sp),
            SizedBox(height: 4.h), // Added spacing
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.figtree(
                textStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update _buildProjectCard to display the amounts
  Widget _buildProjectCard(Map<String, dynamic> project) {
    final amounts = projectAmounts[project['name']] ?? {'in_amount': '0.00', 'out_amount': '0.00'};

    print("Building card for ${project['name']} with amounts: $amounts");

    // Format the amounts to include commas for thousands
    final formattedInAmount = NumberFormat('#,##,##0.00').format(double.parse(amounts['in_amount']!));
    final formattedOutAmount = NumberFormat('#,##,##0.00').format(double.parse(amounts['out_amount']!));

    return GestureDetector(
      onTap: () {
        print("Navigating with project name: ${project['name']}");
        Get.to(() => TabsPages(
          projectName: project['name'],
          work: project['work'],
        ));
      },
      child: Container(
        height: 120.h,
        margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project['work'] ?? '',
                    style: GoogleFonts.figtree(
                      textStyle: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey),
                  onPressed: () {
                    _showBottomSheet(project);
                  },
                ),
              ],
            ),
            Divider(
              color: Colors.grey.shade200,
            ),
            SizedBox(height: 4.3.h,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_downward, color: Colors.green, size: 24),
                      SizedBox(width: 6.w),
                      MyText(
                        text: "In ₹$formattedInAmount",
                        color: Colors.green,
                        weight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 24,
                  width: 1.5,
                  color: Colors.grey[400], // Adds a subtle divider
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.red, size: 24),
                      SizedBox(width: 6.w),
                      MyText(
                        text: "Out ₹$formattedOutAmount",
                        color: Colors.red,
                        weight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              ],
            )

          ],
        ),
      ),
    );
  }

             /// Show Bottom Sheet for Delete Option ///
  void _showBottomSheet(Map<String, dynamic> project) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            SizedBox(height: 12.h),

            // Title
            Subhead(text: "Project Options", color: Colors.black, weight: FontWeight.w500),
            Divider(),

            // Project Form Option
            ListTile(
              leading: Icon(Icons.article, color: Colors.blue),
              title: Text("Project Form",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 16.sp,fontWeight: FontWeight.w500,color: Colors.black))),
              onTap: () {
                Get.back(); // Close BottomSheet
                Get.to(() => ProjectForm()); // Navigate to Project Form
              },
            ),

            // Project Settings Option
            ListTile(
              leading: Icon(Icons.settings, color: Colors.green),
              title: Text("Project Settings",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 16.sp,fontWeight: FontWeight.w500,color: Colors.black))),
              onTap: () {
                Get.back(); // Close BottomSheet
                // Get.to(() => ProjectSettingsPage(project: project)); // Navigate to Project Settings
              },
            ),

            // Delete Project Option (Highlighted)
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text("Delete Project",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 16.sp,fontWeight: FontWeight.w500,color: Colors.black))),
              onTap: () {
                Get.back(); // Close BottomSheet
                MobileDocument(Get.context!, project['name']); // Call delete function
              },
            ),

            SizedBox(height: 10.h),
          ],
        ),
      ),
      isScrollControlled: true, // Allows it to take proper height
      backgroundColor: Colors.transparent, // Removes default background
    );
  }
}
