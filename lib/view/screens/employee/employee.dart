import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:vetri_hollowblock/view/screens/employee/employee_add.dart';
import 'package:vetri_hollowblock/view/widgets/buttons.dart';
import 'dart:convert';
import '../../universal_key_api/api_url.dart';
import '../../widgets/text.dart';

class Employee extends StatefulWidget {
  const Employee({super.key, required this.work, required this.projectName});
  final String projectName;
  final String work;

  @override
  State<Employee> createState() => _EmployeeState();
}

class _EmployeeState extends State<Employee> {
  late double height;
  late double width;

  List<String> employeeNames = [];
  double? employeeDaySalary;
  String? selectedEmployee;
  String attendanceStatus = "Mark Attendance";
  List<dynamic> attendanceList = [];
  List<dynamic> presentEmployees = [];
  List<dynamic> absentEmployees = [];
  bool isLoading = false;
  String? selectedShift;
  DateTime? selectedDate;
  int presentCount = 0;
  int absentCount = 0;

  final inTimeController = TextEditingController();
  final outTimeController = TextEditingController();
  final daySalaryController = TextEditingController();

  String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  List<Map<String, dynamic>> employeeData = [];
  final List<String> shifts = ["1 Shift", "1/2 Shift", "1 1/2 Shift"];
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    fetchEmployeeNames();
    fetchAttendanceData();
  }

  @override
  void dispose() {
    _mounted = false;
    inTimeController.dispose();
    outTimeController.dispose();
    daySalaryController.dispose();
    super.dispose();
  }

  Future<void> fetchEmployeeNames() async {
    final String url = "$apiUrl/Construction%20Employee?fields=[%22name%22,%22day_salary%22]";
    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'token $apiKey',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
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
      setState(() => isLoading = false);
    }
  }

  void calculateSalary() {
    if (selectedEmployee == null || selectedShift == null) return;
    final employeeInfo = employeeData.firstWhere(
          (emp) => emp['name'] == selectedEmployee,
      orElse: () => {'day_salary': 0.0},
    );
    final baseSalary = employeeInfo['day_salary'];
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

  Future<void> fetchAttendanceData() async {
    if (!_mounted) return;
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String url =
        "https://vetri.regenterp.com/api/method/regent.sales.client.get_mobile_employee_attendance?name=${widget.projectName}&date=$today";

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'token $apiKey',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200 && _mounted) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('message') && data['message'] is List) {
          final List<dynamic> attendanceData = data['message'];
          setState(() {
            attendanceList = attendanceData.where((attendance) => attendance['date'] == today).toList();
            presentEmployees = attendanceList
                .where((attendance) => attendance['attendance'] == 'Present')
                .map((attendance) => attendance['employee'].toString())
                .toList();
            presentCount = presentEmployees.length;
            absentEmployees = attendanceList
                .where((attendance) => attendance['attendance'] == 'Absent')
                .map((attendance) => attendance['employee'].toString())
                .toList();
            absentCount = absentEmployees.length;
          });
        } else {
          setState(() {
            attendanceList = [];
            presentEmployees = [];
            absentEmployees = [];
            presentCount = 0;
            absentCount = 0;
          });
        }
      } else {
        print("Failed to fetch attendance data. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching attendance data: $e");
    }
  }

  void showEmployeeList(BuildContext context, List<dynamic> employees, String status) {
    if (!mounted || employees.isEmpty) {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
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
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.5)),
                  ),
                ),
                Text("$status Employees (${employees.length})",
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                SizedBox(height: 10.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          title: Text(employees[index], style: TextStyle(fontWeight: FontWeight.w500)),
                          leading: CircleAvatar(
                            backgroundColor: status == "Present" ? Colors.green : Colors.red,
                            child: Icon(status == "Present" ? Icons.check : Icons.close, color: Colors.white),
                          ),
                          onTap: () {
                            var matchingRecords = attendanceList
                                .where((record) =>
                            record['employee'] == employees[index] && record['attendance'] == status)
                                .toList();
                            if (matchingRecords.isNotEmpty) {
                              var latestRecord = matchingRecords.first;
                              setState(() {
                                selectedEmployee = employees[index];
                                attendanceStatus = status;
                                selectedDate =
                                latestRecord['date'] != null ? DateTime.parse(latestRecord['date']) : DateTime.now();
                                formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
                                selectedShift = latestRecord['shift'];
                                inTimeController.text = latestRecord['in_time'] ?? '';
                                outTimeController.text = latestRecord['out_time'] ?? '';
                                final employeeInfo = employeeData.firstWhere(
                                      (emp) => emp['name'] == selectedEmployee,
                                  orElse: () => {'day_salary': 0.0},
                                );
                                if (selectedShift != null && selectedShift!.isNotEmpty) {
                                  double baseSalary = employeeInfo['day_salary'];
                                  double calculatedSalary = baseSalary;
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
                                  }
                                  daySalaryController.text = calculatedSalary.toStringAsFixed(2);
                                } else {
                                  daySalaryController.text = employeeInfo['day_salary'].toStringAsFixed(2);
                                }
                              });
                            }
                            Navigator.of(context).pop();
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

  void _showShiftDropdown(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Text('Select Shift', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Container(
            padding: EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: selectedShift,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Shift Options',
                contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  selectedShift = newValue;
                  calculateSalary();
                });
                Navigator.pop(context);
              },
              items: shifts.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> MobileDocument(BuildContext context) async {
    bool validateFields() {
      if (selectedEmployee == null ||
          selectedEmployee!.isEmpty ||
          attendanceStatus == "Mark Attendance" ||
          selectedDate == null ||
          daySalaryController.text.isEmpty) {
        Get.snackbar("Validation Error", "Please fill all required fields",
            colorText: Colors.white, backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
      if (attendanceStatus == "Present" && (selectedShift == null || selectedShift!.isEmpty)) {
        Get.snackbar("Validation Error", "Please select a shift for Present status",
            colorText: Colors.white, backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
      return true;
    }

    if (!validateFields()) return;

    HttpClient client = HttpClient();
    client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    final data = {
      'doctype': 'Employee Attendance',
      'employee': selectedEmployee?.trim(),
      'attendance': attendanceStatus,
      'date': DateFormat('yyyy-MM-dd').format(selectedDate!),
      'shift': selectedShift,
      'in_time': inTimeController.text.trim(),
      'out_time': outTimeController.text.trim(),
      'day_salary': daySalaryController.text.trim(),
      'project_form': widget.projectName,
    };

    final url = '$apiUrl/Employee Attendance';
    final body = jsonEncode(data);

    try {
      final response = await ioClient.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        Get.snackbar("Success", "Attendance recorded successfully",
            colorText: Colors.white, backgroundColor: Colors.green, snackPosition: SnackPosition.BOTTOM);
        await fetchAttendanceData();
        setState(() {
          selectedEmployee = null;
          attendanceStatus = "Mark Attendance";
          selectedDate = null;
          selectedShift = null;
          inTimeController.clear();
          outTimeController.clear();
          daySalaryController.clear();
        });
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
              ElevatedButton(child: Text('OK'), onPressed: () => Navigator.of(context).pop()),
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
            ElevatedButton(child: Text('OK'), onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      );
    }
  }

  Future<void> updateEmployeeAttendance(BuildContext context) async {
    bool validateFields() {
      if (selectedEmployee == null ||
          selectedEmployee!.isEmpty ||
          selectedDate == null ||
          attendanceStatus == "Mark Attendance" ||
          daySalaryController.text.isEmpty) {
        showSnackbar("Validation Error", "Please fill all required fields.");
        return false;
      }
      if (attendanceStatus == "Present" &&
          (selectedShift == null || selectedShift!.isEmpty || inTimeController.text.isEmpty || outTimeController.text.isEmpty)) {
        showSnackbar("Validation Error", "Please fill shift, in-time, and out-time for Present status.");
        return false;
      }
      return true;
    }

    if (!validateFields()) return;

    String formattedSelectedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
    var existingRecord = attendanceList.firstWhere(
          (record) =>
      record['employee'] == selectedEmployee &&
          DateFormat('yyyy-MM-dd').format(DateTime.parse(record['date'])) == formattedSelectedDate,
      orElse: () => null,
    );

    if (existingRecord == null) {
      print("No existing record found. Creating a new one.");
      MobileDocument(context);
      return;
    }

    String recordName = existingRecord['name'] ?? "";
    if (recordName.isEmpty) {
      showSnackbar("Update Error", "Cannot find the record ID for update.");
      return;
    }

    final String url = Uri.encodeFull('$apiUrl/Employee Attendance/$recordName');
    final Map<String, dynamic> data = {
      'attendance': attendanceStatus,
      'shift': selectedShift,
      'in_time': inTimeController.text.trim(),
      'out_time': outTimeController.text.trim(),
      'day_salary': daySalaryController.text.trim(),
    };

    HttpClient client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    IOClient ioClient = IOClient(client);

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    try {
      final response = await ioClient.put(Uri.parse(url), headers: headers, body: jsonEncode(data));
      if (response.statusCode == 200) {
        await fetchAttendanceData();
        showSnackbar("Employee", "Attendance Updated Successfully", isSuccess: true);
        setState(() {
          selectedEmployee = null;
          attendanceStatus = "Mark Attendance";
          selectedDate = null;
          selectedShift = null;
          inTimeController.clear();
          outTimeController.clear();
          daySalaryController.clear();
        });
      } else {
        String errorMessage = 'Update failed with status: ${response.statusCode}';
        if (response.statusCode == 417) {
          final serverMessages = json.decode(response.body)['_server_messages'];
          errorMessage = serverMessages ?? errorMessage;
        }
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(errorMessage),
            actions: [ElevatedButton(child: Text('OK'), onPressed: () => Navigator.of(context).pop())],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('An error occurred: $e'),
          actions: [ElevatedButton(child: Text('OK'), onPressed: () => Navigator.of(context).pop())],
        ),
      );
    }
  }

  void showSnackbar(String title, String message, {bool isSuccess = false}) {
    Get.snackbar(
      title,
      message,
      colorText: Colors.white,
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;

    return Scaffold(
      body: SizedBox(
        width: width.w,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 30.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => showEmployeeList(context, presentEmployees, "Present"),
                    child: Container(
                      height: height / 15.h,
                      width: width / 2.4.w,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 20),
                          SizedBox(width: 8.w),
                          MyText(text: "Present: $presentCount", color: Colors.white, weight: FontWeight.w500),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 5.w),
                  GestureDetector(
                    onTap: () => showEmployeeList(context, absentEmployees, "Absent"),
                    child: Container(
                      height: height / 15.h,
                      width: width / 2.4.w,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, color: Colors.white, size: 20),
                          SizedBox(width: 8.w),
                          MyText(text: "Absent: $absentCount", color: Colors.white, weight: FontWeight.w500),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) setState(() => selectedDate = pickedDate);
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
                      text: selectedDate != null
                          ? DateFormat('dd-MM-yyyy').format(selectedDate!)
                          : "Select Date",
                      color: Colors.black,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
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
                    ? Center(child: CircularProgressIndicator())
                    : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: MyText(text: "Select Employee", color: Colors.black, weight: FontWeight.w400),
                    value: selectedEmployee,
                    items: [
                      ...employeeNames.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: MyText(text: name, color: Colors.black, weight: FontWeight.w500),
                        );
                      }),
                      DropdownMenuItem(
                        value: "add_employee",
                        child: Row(
                          children: [
                            Icon(Icons.add, color: Colors.blue),
                            SizedBox(width: 10.w),
                            MyText(text: "Add Employee", color: Colors.blue, weight: FontWeight.w500),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == "add_employee") {
                        Get.to(EmployeeAdd(work: widget.work, projectName: widget.projectName));
                      } else {
                        setState(() {
                          selectedEmployee = value;
                          selectedShift = null;
                          daySalaryController.clear();
                          final employeeInfo = employeeData.firstWhere(
                                (emp) => emp['name'] == value,
                            orElse: () => {'day_salary': 0.0},
                          );
                          daySalaryController.text = employeeInfo['day_salary'].toStringAsFixed(2);
                        });
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
                    builder: (BuildContext context) {
                      return Container(
                        padding: EdgeInsets.all(20.0),
                        height: height / 4.h,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText(text: "Mark Attendance", color: Colors.black, weight: FontWeight.bold),
                            SizedBox(height: 20.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => attendanceStatus = "Present");
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
                                  ),
                                  child: Text("Present", style: TextStyle(color: Colors.white)),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => attendanceStatus = "Absent");
                                    Navigator.pop(context);
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
                  height: height / 10.h,
                  width: width / 1.2.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  child: Center(
                      child: MyText(text: attendanceStatus, color: Colors.black, weight: FontWeight.w500)),
                ),
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () => _showShiftDropdown(context),
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
                      text: selectedShift ?? "Shift basics",
                      color: Colors.black,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
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
                      textAlign: TextAlign.center,
                      controller: daySalaryController,
                      decoration: InputDecoration(
                        hintText: "Day Salary",
                        hintStyle: GoogleFonts.dmSans(
                            textStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.black)),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (pickedTime != null) {
                        setState(() => inTimeController.text = pickedTime.format(context));
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
                          text: inTimeController.text.isEmpty ? "In Time" : inTimeController.text,
                          color: Colors.black,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (pickedTime != null) {
                        final inTime = _parseTimeOfDay(inTimeController.text);
                        if (inTime != null &&
                            (pickedTime.hour < inTime.hour ||
                                (pickedTime.hour == inTime.hour && pickedTime.minute <= inTime.minute))) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Out Time cannot be less than or equal to In Time"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          setState(() => outTimeController.text = pickedTime.format(context));
                        }
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
                          text: outTimeController.text.isEmpty ? "Out Time" : outTimeController.text,
                          color: Colors.black,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () {
                  if (selectedEmployee == null || selectedEmployee!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Please select an employee.", style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    String formattedSelectedDate =
                    selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : "";
                    bool recordExists = attendanceList.any((record) =>
                    record['employee'] == selectedEmployee &&
                        record['date'] == formattedSelectedDate);
                    if (recordExists) {
                      print("Updating existing record");
                      updateEmployeeAttendance(context);
                    } else {
                      print("Creating new record");
                      MobileDocument(context);
                    }
                  }
                },
                child: Buttons(
                  height: height / 15.h,
                  width: width / 1.5,
                  radius: BorderRadius.circular(10.r),
                  color: Colors.blue,
                  text: "Save & Submit",
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  TimeOfDay? _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(RegExp(r'[: ]'));
      if (parts.length == 3) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = parts[2].toLowerCase();
        return TimeOfDay(hour: period == 'pm' && hour != 12 ? hour + 12 : hour, minute: minute);
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
