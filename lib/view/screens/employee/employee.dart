import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:vetri_hollowblock/view/screens/employee/employee_add.dart';
import 'package:vetri_hollowblock/view/widgets/buttons.dart';
import 'dart:convert'; // For JSON decoding
import '../../universal_key_api/api_url.dart';
import '../../widgets/subhead.dart';
import '../../widgets/text.dart';

class Employee extends StatefulWidget {
  const Employee({super.key ,required this.work});
  final String work; //

  @override
  State<Employee> createState() => _EmployeeState();
}

class _EmployeeState extends State<Employee> {
  late double height;
  late double width;

  List<String> employeeNames = []; // List to hold employee names
  double? employeeDaySalary;
  String? selectedEmployee; // Currently selected employee
  String attendanceStatus = "Mark Attendance"; // State to hold attendance status
  List<dynamic> attendanceList = [];
  List<dynamic> presentEmployees = [];
  List<dynamic> absentEmployees = [];
  bool isLoading = false; // Loading indicator for dropdown
  String? selectedShift; // Initially no shift selected (null)
  String selectedDate = "Date"; // Default text before any date is selected,
  bool _mounted = true; // Add this flag to check if widget is mounted
  DateTime chooseDate = DateTime.now(); // Store the selected date


  int presentCount = 0; // Count of present employees
  int absentCount = 0; // Count of absent employees

  /// Textediting Controller ///
  final inTimeController = TextEditingController();
  final outTimeController = TextEditingController();
  final daySalaryController = TextEditingController();

  /// Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: chooseDate,
      firstDate: DateTime(2000), // Earliest selectable date
      lastDate: DateTime(2101), // Latest selectable date
    );
    if (picked != null && picked != chooseDate) {
      setState(() {
        chooseDate = picked; // Update the selected date
      });
    }
  }

  // List of shifts
  final List<String> shifts = ["1 Shift", "1/2 Shift","1 1/2 Shift"];

  @override
  void initState() {
    super.initState();
    fetchEmployeeNames();
    fetchAttendanceData();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }


// Add this to your class-level variables
  List<Map<String, dynamic>> employeeData = [];
  // Fetch employee names from the API
  // Modify fetchEmployeeNames to include day salary
  Future<void> fetchEmployeeNames() async {
    final String url = "$apiUrl/Construction%20Employee?fields=[%22name%22,%22day_salary%22]";

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
          // Store full employee data including name and day salary
          employeeData = (data['data'] as List).map((employee) => {
            'name': employee['name'],
            'day_salary': double.tryParse(employee['day_salary'].toString()) ?? 0.0
          }).toList();

          employeeNames = employeeData.map((emp) => emp['name'] as String).toList();
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


  // Method to calculate salary based on shift
  void calculateSalary() {
    if (selectedEmployee == null || selectedShift == null) return;

    // Find the base day salary for the selected employee
    final employeeInfo = employeeData.firstWhere(
          (emp) => emp['name'] == selectedEmployee,
      orElse: () => {'day_salary': 0.0},
    );

    final baseSalary = employeeInfo['day_salary'];

    // Calculate salary based on shift
    double calculatedSalary;
    switch (selectedShift) {
      case '1 Shift':
        calculatedSalary = baseSalary;
        break;
      case '1/2 Shift':
        calculatedSalary = baseSalary / 2;
        break;
      case '1 1/2 Shift':
        calculatedSalary = baseSalary * 1.5;
        break;
      default:
        calculatedSalary = 0.0;
    }

    setState(() {
      daySalaryController.text = calculatedSalary.toStringAsFixed(2);
    });
  }


  // Modify onChanged in the employee dropdown

  // Updated fetchAttendanceData with mounted check
  Future<void> fetchAttendanceData() async {
    if (!_mounted) return; // Check if the widget is still mounted

    final String url =
        "$apiUrl/Employee%20Attendance?fields=[%22attendance%22,%22employee%22,%22date%22]";
    final String today = DateTime.now().toIso8601String().substring(0, 10); // Get today's date in YYYY-MM-DD format

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 && _mounted) {
        final data = json.decode(response.body);
        setState(() {
          // Filter attendance data for today
          final todayAttendance = (data['data'] as List)
              .where((attendance) => attendance['date'] == today)
              .toList();

          attendanceList = todayAttendance;

          // Update present employees list and count
          presentEmployees = todayAttendance
              .where((attendance) => attendance['attendance'] == 'Present')
              .map((attendance) => attendance['employee'].toString())
              .toList();
          presentCount = presentEmployees.length;

          // Update absent employees list and count
          absentEmployees = todayAttendance
              .where((attendance) => attendance['attendance'] == 'Absent')
              .map((attendance) => attendance['employee'].toString())
              .toList();
          absentCount = absentEmployees.length;
        });
      } else {
        print("Failed to fetch attendance data. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching attendance data: $e");
    }
  }



  void showEmployeeList(BuildContext context, List<dynamic> employees, String status) {
    if (!mounted) return;

    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No $status employees found for today'),
          backgroundColor: status == 'Present' ? Colors.green : Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                Text(
                  "$status Employees (${employees.length})",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          title: Text(
                            employees[index],
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: status == "Present" ? Colors.green : Colors.red,
                            child: Icon(
                              status == "Present" ? Icons.check : Icons.close,
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            // Find the most recent attendance record for this employee
                            var latestRecord = attendanceList.lastWhere(
                                  (record) =>
                              record['employee'] == employees[index] &&
                                  record['attendance'] == status,
                              orElse: () => null,
                            );

                            // Debug print to check the exact structure of the record
                            print('Latest Record: $latestRecord');
                            print('Record Keys: ${latestRecord?.keys}');

                            setState(() {
                              selectedEmployee = employees[index];
                              attendanceStatus = status;

                              // If a record exists, use its details
                              var matchingRecords = attendanceList.where(
                                      (record) =>
                                  record['employee'] == employees[index] &&
                                      record['attendance'] == status
                              ).toList();

                        // Sort records by date in descending order and take the first one
                              var latestRecord = matchingRecords.isNotEmpty
                                  ? matchingRecords.reduce((a, b) =>
                              DateTime.parse(a['date']).isAfter(DateTime.parse(b['date'])) ? a : b)
                                  : null;

                              if (latestRecord != null) {
                                setState(() {
                                  selectedEmployee = employees[index];
                                  attendanceStatus = status;

                                  // Populate all fields from the latest record
                                  selectedDate = latestRecord['date'];
                                  selectedShift = latestRecord['shift'];
                                  inTimeController.text = latestRecord['in_time'] ?? '';
                                  outTimeController.text = latestRecord['out_time'] ?? '';

                                  // Recalculate salary if needed
                                  calculateSalary();
                                });
                              }

                              // Explicitly calculate salary for the selected employee
                              final employeeInfo = employeeData.firstWhere(
                                    (emp) => emp['name'] == selectedEmployee,
                                orElse: () => {'day_salary': 0.0},
                              );

                              // Set the base day salary
                              daySalaryController.text = employeeInfo['day_salary'].toStringAsFixed(2);

                              // If a shift is selected, recalculate salary
                              if (selectedShift != null) {
                                calculateSalary();
                              }
                            });

                            Navigator.of(context).pop(); // Close the bottom sheet
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                // Modify shift dropdown onChanged
                onChanged: (String? newValue) {
                  setState(() {
                    selectedShift = newValue; // Update the selected shift
                    calculateSalary(); // Calculate salary when shift is selected
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
    // Add validation function
    // Add validation function
    bool validateFields() {
      // Special validation for Absent status
      if (attendanceStatus == "Absent") {
        if (selectedEmployee == null ||
            selectedEmployee!.isEmpty ||
            attendanceStatus == "Mark Attendance" ||
            selectedDate == "Date" ||
            // selectedShift == null ||
            // selectedShift!.isEmpty ||
            daySalaryController.text.isEmpty
        ) {
          Get.snackbar(
            "Validation Error",
            "Please fill all the required fields",
            colorText: Colors.white,
            backgroundColor: Colors.red,
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }
      } else {
        // Normal validation for other attendance statuses
        if (selectedEmployee == null ||
            selectedEmployee!.isEmpty ||
            attendanceStatus == "Mark Attendance" ||
            selectedDate == "Date" ||
            selectedShift == null ||
            selectedShift!.isEmpty ||
            daySalaryController.text.isEmpty ||
            inTimeController.text.isEmpty ||
            outTimeController.text.isEmpty) {
          Get.snackbar(
            "Validation Error",
            "Please fill all the required fields",
            colorText: Colors.white,
            backgroundColor: Colors.red,
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }
      }
      return true;
    }

    // Validate fields before proceeding
    if (!validateFields()) {
      return;
    }

    HttpClient client = HttpClient();
    client.badCertificateCallback =
    ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    final data = {
      'doctype': 'Employee Attendance',
      'employee': selectedEmployee?.trim(),
      'attendance': attendanceStatus,
      'date': DateTime.parse(selectedDate).toIso8601String(),
      'shift': selectedShift,
      'in_time': inTimeController.text.trim(),
      'out_time': outTimeController.text.trim(),
      'day_salary': daySalaryController.text.trim(),
    };

    final url = '$apiUrl/Employee Attendance';
    final body = jsonEncode(data);
    print(data);

    // Open Hive box for storing submission data
    var box = await Hive.openBox('submissionBox');
    String? lastSubmission = box.get('lastSubmission');

    if (lastSubmission != null) {
      final lastSubmissionData = jsonDecode(lastSubmission);
      final storedEmployee = lastSubmissionData['employee']?.trim();
      final storedDate = lastSubmissionData['date'];

      // Normalize current input
      final normalizedEmployee = selectedEmployee?.trim();
      final normalizedDate = DateTime.parse(selectedDate).toIso8601String();

      if (storedEmployee == normalizedEmployee && storedDate == normalizedDate) {
        Get.snackbar(
          "Duplicate Entry",
          "This data has already been submitted.",
          colorText: Colors.white,
          backgroundColor: Colors.orange,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    try {
      final response =
      await ioClient.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        // Save current submission as the last submission
        await box.put(
          'lastSubmission',
          jsonEncode({
            'employee': selectedEmployee?.trim(),
            'date': DateTime.parse(selectedDate).toIso8601String(),
          }),
        );

        await fetchAttendanceData();

        Get.snackbar(
          "Employee",
          "Document Posted Successfully",
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Reset the form
        setState(() {
          selectedEmployee = null;
          attendanceStatus = "Mark Attendance";
          selectedDate = "Date";
          selectedShift = null;
        });
        inTimeController.clear();
        outTimeController.clear();
        daySalaryController.clear();
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
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xfff1f2f4),
        toolbarHeight: 80.h,
        centerTitle: true,
        title: Subhead(
          text: "Employee Attendance",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
              onTap: () => _selectDate(context), // Call date picker on tap
              child: MyText(
                text: chooseDate != null // Check if selectedDate is null
                    ? DateFormat('dd-MM-yyyy').format(chooseDate!)
                    : 'Select Date', // Show 'Select Date' if null
                color: Colors.black,
                weight: FontWeight.w500,
              ),
            ),
          ),
        ],

      ),
      body: SizedBox(
        width: width.w,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      showEmployeeList(context, presentEmployees, "Present");
                    },
                    child: Container(
                      height: height / 15.h,
                      width: width / 2.4.w,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 20),
                          SizedBox(width: 8.w),
                          MyText(
                            text: "Present: $presentCount",
                            color: Colors.white,
                            weight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 5.w),
                  GestureDetector(
                    onTap: () {
                      showEmployeeList(context, absentEmployees, "Absent");
                    },
                    child: Container(
                      height: height / 15.h,
                      width: width / 2.4.w,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, color: Colors.white, size: 20),
                          SizedBox(width: 8.w),
                          MyText(
                            text: "Absent: $absentCount",
                            color: Colors.white,
                            weight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                          Get.to(EmployeeAdd(work: '',));
                        } else {
                          setState(() {
                            selectedEmployee = value;
                            // Reset shift and salary when new employee is selected
                            selectedShift = null;
                            daySalaryController.clear();

                            // Automatically find and set the day salary for the selected employee
                            final employeeInfo = employeeData.firstWhere(
                                  (emp) => emp['name'] == value,
                              orElse: () => {'day_salary': 0.0},
                            );

                            // Optional: If you want to show the base salary before shift calculation
                            daySalaryController.text = employeeInfo['day_salary'].toStringAsFixed(2);
                          });
                        }
                      }

                  ),
                ),
              ),
              SizedBox(height: 20.h,),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                ),
                builder: (BuildContext context) {
                  return Container(
                    padding: EdgeInsets.all(20.0),
                    height: height/4.h,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: "Mark Attendance",
                          color: Colors.black,
                          weight: FontWeight.bold,
                        ),
                        SizedBox(height: 20.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                showEmployeeList(context, presentEmployees, "Present");
                                setState(() {
                                  attendanceStatus = "Present";
                                });
                                Navigator.pop(context); // Close the modal
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
                              ),
                              child: Text("Present", style: TextStyle(color: Colors.white)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                showEmployeeList(context, absentEmployees, "Absent");
                                setState(() {
                                  attendanceStatus = "Absent";
                                });
                                Navigator.pop(context); // Close the modal
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
                              ),
                              child: Text("Absent", style: TextStyle(color: Colors.white)),
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
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              height: height/10.h,
              width: width/1.2.w,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(7.0),
              ),
              child: Center(
                child: MyText(text: attendanceStatus, color: Colors.black, weight: FontWeight.w500)
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
              GestureDetector(
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
                    child: TextField(
                      controller: daySalaryController,
                      enabled: false, // Make it read-only
                      decoration: InputDecoration(
                        hintText: "                         Day Salary",
                        hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
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
                onTap: () {
                  if (selectedEmployee == null || selectedEmployee!.isEmpty) {
                    // Show an error message if no employee is selected
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Please select an employee.",
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    // Proceed with submission if validation passes
                    MobileDocument(context);
                  }
                },
                child: Buttons(
                  height: height / 15.h,
                  width: width / 1.5,
                  radius: BorderRadius.circular(10.r),
                  color: Colors.blue,
                  text: "Submit",
                ),
              ),
              SizedBox(height: 20.h,),
          
                ]
          ),
        )
      ),
    );
  }
}