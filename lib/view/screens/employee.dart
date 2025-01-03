import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:vetri_hollowblock/view/screens/employee_add.dart';
import 'package:vetri_hollowblock/view/widgets/buttons.dart';
import 'dart:convert'; // For JSON decoding

import '../universal_key_api/api_url.dart';
import '../widgets/subhead.dart';
import '../widgets/text.dart';

class Employee extends StatefulWidget {
  const Employee({super.key});

  @override
  State<Employee> createState() => _EmployeeState();
}

class _EmployeeState extends State<Employee> {
  late double height;
  late double width;

  List<String> employeeNames = []; // List to hold employee names
  String? selectedEmployee; // Currently selected employee
  String attendanceStatus = "Mark Attendance"; // State to hold attendance status
  bool isLoading = false; // Loading indicator for dropdown

  @override
  void initState() {
    super.initState();
    fetchEmployeeNames();
  }

  // Fetch employee names from the API
  Future<void> fetchEmployeeNames() async {
    final String url = "$apiUrl/Construction%20Employee";

    setState(() {
      isLoading = true;
    });

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
        print(response.body);

        setState(() {
          employeeNames = List<String>.from(
            data['data'].map((employee) => employee['name']), // Adjust the key if API structure differs
          );
        });
      } else {
        print("Failed to fetch employees. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching employees: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
                 /// Post method for Employee //
  Future<void> MobileDocument(BuildContext context) async {
    HttpClient client = HttpClient();
    client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    final data = {
      'doctype': 'Employee Attendance',
      'employee': selectedEmployee,
      'attendance': attendanceStatus,
    };

    final url = '$apiUrl/Employee Attendance'; // Replace with your actual API URL
    final body = jsonEncode(data);
    print(data);

    try {
      // Use Uri.parse() to convert the string URL into a Uri object
      final response = await ioClient.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        Get.snackbar("Employee", " Document Posted Successfully",colorText: Colors.white,backgroundColor: Colors.green,snackPosition: SnackPosition.BOTTOM);
        Navigator.pop(context);
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
    /// Define Sizes //
    var size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        height = constraints.maxHeight;
        width = constraints.maxWidth;
        if (width <= 450) {
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
          text: "Employee Attendance",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
      ),
      body: SizedBox(
        width: width.w,
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              height: height / 10.h,
              width: width / 1.2.w,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(7.r),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: MyText(
                    text: "Select Employee",
                    color: Colors.black,
                    weight: FontWeight.w400,
                  ),
                  value: selectedEmployee,
                  items: [
                    ...employeeNames.map((name) {
                      return DropdownMenuItem(
                        value: name,
                        child: MyText(
                          text: name,
                          color: Colors.black,
                          weight: FontWeight.w500,
                        ),
                      );
                    }),
                    DropdownMenuItem(
                      value: "add_employee",
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Colors.blue),
                          SizedBox(width: 10.w),
                          MyText(
                            text: "Add Employee",
                            color: Colors.blue,
                            weight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == "add_employee") {
                      // Navigate to Add Employee page
                      Get.to(EmployeeAdd());
                    } else {
                      setState(() {
                        selectedEmployee = value;
                      });
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 20.h,),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                  ),
                  builder: (BuildContext context) {
                    return Container(
                      padding: EdgeInsets.all(20.w),
                      height: height / 4.h,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText(
                            text: "Mark Attendance",
                            color: Colors.black,
                            weight: FontWeight.bold,
                          ),
                          SizedBox(height: 20.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    attendanceStatus = "Present";
                                  });
                                  Navigator.pop(context); // Close the popup
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 30.w,
                                    vertical: 10.h,
                                  ),
                                ),
                                child: MyText(
                                  text: "Present",
                                  color: Colors.white,
                                  weight: FontWeight.w500,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    attendanceStatus = "Absent";
                                  });
                                  Navigator.pop(context); // Close the popup
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 30.w,
                                    vertical: 10.h,
                                  ),
                                ),
                                child: MyText(
                                  text: "Absent",
                                  color: Colors.white,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                height: height / 10.h,
                width: width / 1.2.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(7.r),
                ),
                child: Center(
                  child: MyText(
                    text: attendanceStatus, // Show the current attendance status
                    color: Colors.black,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h,),
            GestureDetector(
              onTap: (){
                MobileDocument(context);
              },
                child: Buttons(height: height/15.h, width: width/1.5, radius: BorderRadius.circular(10.r), color: Colors.blue, text: "Submit"))



          ],
        ),
      ),
    );
  }
}
