import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';
import 'package:http/http.dart' as http;
import '../universal_key_api/api_url.dart';
import '../widgets/buttons.dart';
import '../widgets/subhead.dart';

class Todo extends StatefulWidget {
  const Todo({super.key});

  @override
  State<Todo> createState() => _TodoState();
}

class _TodoState extends State<Todo> {
  late double height;
  late double width;
  TextEditingController dateController = TextEditingController();
  List<String> partyName = []; // List to hold party names
  String? selectedParty;
  List<String> project = []; // List to hold project names
  String? selectedProject;
  bool isLoading = false;
  List<Map<String, String>> tasks = []; // List to store tasks after posting


  final description = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPartyName();
    fetchProject();
  }

  /// API to fetch party names
  Future<void> fetchPartyName() async {
    final String url =
        "$apiUrl/Party?fields=[%22party_name%22]&limit_page_length=50000";
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          partyName = List<String>.from(
              data['data'].map((party) => party['party_name'])); // Extract names
        });
      } else {
        print("Failed to fetch party names. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching party names: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// API to fetch project names
  Future<void> fetchProject() async {
    final String url = "$apiUrl/Project%20Form";
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          project = List<String>.from(
              data['data'].map((proj) => proj['name'])); // Extract project names
        });
      } else {
        print("Failed to fetch project names. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching project names: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }
      /// Post method for Todo ///
  Future<void> MobileDocument(BuildContext context) async {
    HttpClient client = HttpClient();
    client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    final data = {
      'doctype': 'To Do',
      'assigne': selectedParty,
      'project': selectedProject,
      'due_date': dateController.text,
      'description': description.text,
    };

    final url = '$apiUrl/To Do'; // Replace with your actual API URL
    final body = jsonEncode(data);
    print(data);

    try {
      final response = await ioClient.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        Get.snackbar("Todo", "Document Added Successfully", colorText: Colors.white, backgroundColor: Colors.green, snackPosition: SnackPosition.BOTTOM);

        // Add task to the tasks list
        setState(() {
          tasks.add({
            'assigne': selectedParty ?? '',
            'project': selectedProject ?? '',
            'due_date': dateController.text,
            'description': description.text,
          });

          // Clear fields after successful submission
          selectedParty = null;
          selectedProject = null;
          dateController.clear();
          description.clear();
        });
      } else {
        String message = 'Request failed with status: ${response.statusCode}';
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
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
    /// Define Sizes
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
            text: "To Do",
            color: Colors.black,
            weight: FontWeight.w500,
          ),
        ),
        body: SizedBox(
          width: width.w,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showDropdown(
                            title: "Select Assignee",
                            options: partyName,
                            onSelected: (value) {
                              setState(() => selectedParty = value);
                            },
                          );
                        },
                        child: Container(
                          height: height / 17.h,
                          width: width / 3.5.w,
                          decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10.r)),
                          child: Center(
                            child: MyText(
                              text: selectedParty ?? "Assignee",
                              color: Colors.white,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            dateController.text =
                                DateFormat('yyyy-MM-dd').format(pickedDate);
                          }
                        },
                        child: Container(
                          height: height / 17.h,
                          width: width / 3.5.w,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Center(
                            child: MyText(
                              text: dateController.text.isEmpty
                                  ? "Due Date"
                                  : dateController.text,
                              color: Colors.white,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showDropdown(
                            title: "Select Project",
                            options: project,
                            onSelected: (value) {
                              setState(() => selectedProject = value);
                            },
                          );
                        },
                        child: Container(
                          height: height / 17.h,
                          width: width / 3.5.w,
                          decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10.r)),
                          child: Center(
                            child: MyText(
                              text: selectedProject ?? "Project",
                              color: Colors.white,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),
                Align(
                  alignment: Alignment.topLeft,
                  child: Text('    Description:',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w500, fontSize: 16)),
                ),
                SizedBox(height: 10.h),
                Container(
                  height: height / 7.h,
                  width: width / 1.13.w,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey.shade500),
                      borderRadius: BorderRadius.circular(6.r)),
                  child: TextFormField(
                    controller: description,
                    style: GoogleFonts.dmSans(
                        textStyle: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black)),
                    decoration: InputDecoration(
                        hintText: "     ",
                        hintStyle: GoogleFonts.sora(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                        border: InputBorder.none),
                  ),
                ),
                SizedBox(height: 30.h),
                GestureDetector(
                  onTap: (){
                    MobileDocument(context);
                  },
                  child: Buttons(
                      height: height / 15.h,
                      width: width / 1.5,
                      radius: BorderRadius.circular(10.r),
                      color: Colors.blue,
                      text: "Save"),
                ),
                SizedBox(height: 10.h,),
                // Display the tasks
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w), // Card with margin
                      elevation: 4, // Add shadow effect
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r), // Rounded corners for a modern look
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w), // Padding inside the tile
                        leading: Icon(
                          Icons.check_box, // Check box icon for the task
                          color: Colors.green, // Color of the icon
                          size: 28.r, // Icon size
                        ),
                        title: Text(
                          task['description'] ?? 'No description',
                          style: GoogleFonts.dmSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black, // Text color for the title
                          ),
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 6.h), // Padding for the subtitle
                          child: Text(
                            'Assigne: ${task['assigne'] ?? 'No Assignee'}\n'
                                'Project: ${task['project'] ?? 'No Project'}\n'
                                'Due Date: ${task['due_date'] ?? 'No Due Date'}',
                            style: GoogleFonts.sora(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[700], // Subtle grey color for the subtitle text
                            ),
                          ),
                        ),
                        trailing: IconButton(onPressed: (){
                          setState(() {
                            tasks.removeAt(index);
                          });
                        }, icon: Icon(Icons.delete,color: Colors.red,)),
                        onTap: () {
                          // Optionally add an onTap event to open details or perform an action
                        },
                      ),
                    );
                  },
                )

              ],
            ),
          ),
        ));
  }

  /// Function to show dropdown dialog
  void _showDropdown({
    required String title,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          height: 300.h,
          width: 300.w,
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(options[index]),
              onTap: () {
                onSelected(options[index]);
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }
}
