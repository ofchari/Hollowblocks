import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetri_hollowblock/view/screens/employee/employee_add.dart';
import 'package:vetri_hollowblock/view/widgets/buttons.dart';
import 'dart:convert'; // For JSON decoding
import '../../universal_key_api/api_url.dart';
import '../../widgets/subhead.dart';
import '../../widgets/text.dart';

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
  String? selectedShift; // Initially no shift selected (null)
  String selectedDate = "Date"; // Default text before any date is selected,

  int presentCount = 0; // Count of present employees
  int absentCount = 0; // Count of absent employees

  /// Textediting Controller ///
  final inTimeController = TextEditingController();
  final outTimeController = TextEditingController();

  // List of shifts
  final List<String> shifts = ["1 Shift", "1/2 Shift"];

  @override
  void initState() {
    super.initState();
    fetchEmployeeNames();
    fetchAttendanceData();
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

  // Fetch the attendance data from the API to count present and absent employees
  Future<void> fetchAttendanceData() async {
    final String url = "$apiUrl/Employee%20Attendance?fields=[%22attendance%22]"; // API URL

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
        List<dynamic> attendanceList = data['data']; // List of attendance data

        setState(() {
          presentCount = attendanceList.where((attendance) => attendance['attendance'] == 'Present').toList().length;
          absentCount = attendanceList.where((attendance) => attendance['attendance'] == 'Absent').toList().length;
        });
      } else {
        print("Failed to fetch attendance data. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching attendance data: $e");
    }
  }

  /// Dropdown logic for shifts ///
  void _showShiftDropdown(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Rounded corners for the dialog
          ),
          title: Text(
            'Select Shift',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          content: Container(
            padding: EdgeInsets.all(12), // Padding for the dropdown container
            child: DropdownButtonFormField<String>(
              value: selectedShift, // Show the currently selected shift
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Shift Options',
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  selectedShift = newValue; // Update the selected shift
                });
                Navigator.pop(context); // Close the dialog
              },
              items: shifts.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog without selection
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.red, // Red color for the cancel button
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Post method for Employee
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
      'date': selectedDate.toString(),
      'shift': selectedShift,
      'in_time': inTimeController.text,
      'out_time': outTimeController.text,
    };

    final url = '$apiUrl/Employee Attendance'; // Replace with your actual API URL
    final body = jsonEncode(data);
    print(data);

    // Open Hive box for storing submission data
    var box = await Hive.openBox('submissionBox');

    String? lastSubmission = box.get('lastSubmission');

    if (lastSubmission != null) {
      final lastSubmissionData = jsonDecode(lastSubmission);
      if (lastSubmissionData['employee'] == selectedEmployee &&
          lastSubmissionData['date'] == selectedDate) {
        Get.snackbar(
          "Duplicate Entry",
          "This data has already been submitted.",
          colorText: Colors.white,
          backgroundColor: Colors.orange,
          snackPosition: SnackPosition.BOTTOM,
        );
        return; // Prevent duplicate submission
      }
    }

    try {
      final response = await ioClient.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        // Save the current submission to Hive
        await box.put('lastSubmission', jsonEncode({
          'employee': selectedEmployee,
          'date': selectedDate
        }));

        Get.snackbar(
          "Employee",
          "Document Posted Successfully",
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Clear input fields after successful submission
        setState(() {
          selectedEmployee = null;
          attendanceStatus = "Mark Attendance";
          selectedDate = "Date";
          selectedShift = null;
        });
        inTimeController.clear();
        outTimeController.clear();
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
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  height: height/15.h,
                  width: width/2.4.w,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(child: MyText(text: "Present : $presentCount", color: Colors.white, weight: FontWeight.w500)),
                ),
                SizedBox(width: 5.w,),
                Container(
                  height: height/15.h,
                  width: width/2.4.w,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(child: MyText(text: "Absent : $absentCount", color: Colors.white, weight: FontWeight.w500)),
                )
              ],
            ),
            SizedBox(height: 20.h,),
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
              onTap: () async {
                // Show the date picker
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                // Update the container's text with the selected date if a date is picked
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                  });
                }
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
                    text: selectedDate, // Display the selected date dynamically
                    color: Colors.black,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h,),
            GestureDetector(
              onTap: (){
                _showShiftDropdown(context);
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
                    text: selectedShift ?? "Shift basics", // Show the selected shift or default text // Show the current attendance status
                    color: Colors.black,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h,),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () async {
                    // Show the time picker
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      // If a time is selected, set it to the controller and update the UI
                      setState(() {
                        inTimeController.text = pickedTime.format(context); // Update the controller
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    height: height / 15.h,
                    width: width / 2.9.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                    child: Center(
                      child: MyText(
                        text: inTimeController.text.isEmpty
                            ? "In Time" // Default text when no time is selected
                            : inTimeController.text, // Display selected time
                        color: Colors.black,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () async {
                    // Show the time picker
                    // Show the time picker
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      // If a time is selected, set it to the controller and update the UI
                      setState(() {
                        outTimeController.text = pickedTime.format(context); // Update the controller
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    height: height / 15.h,
                    width: width / 2.9.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                    child: Center(
                      child: MyText(
                        text: outTimeController.text.isEmpty
                            ? "Out Time" // Default text when no time is selected
                            : outTimeController.text, // Display selected time // Show the selected shift or default text //
                        color: Colors.black,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
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