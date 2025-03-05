import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:share_plus/share_plus.dart';


class ReportsEmployee extends StatefulWidget {
  const ReportsEmployee({super.key});

  @override
  State<ReportsEmployee> createState() => _ReportsEmployeeState();
}

class _ReportsEmployeeState extends State<ReportsEmployee> {
  late double height;
  late double width;

  List<Map<String, dynamic>> attendanceData = [];
  List<Map<String, dynamic>> filteredData = [];
  bool isLoading = true;

  // Define controllers for search fields
  final Map<String, TextEditingController> searchControllers = {
    'attendance': TextEditingController(),
    'employee': TextEditingController(),
    'shift': TextEditingController(),
  };

  String selectedDate = ""; // For storing the selected date

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  @override
  void dispose() {
    // Dispose controllers
    for (var controller in searchControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> fetchAttendanceData() async {
    final url =
        'https://vetri.regenterp.com/api/resource/Employee%20Attendance?fields=[%22attendance%22,%22employee%22,%22shift%22,%22date%22,%22in_time%22,%22out_time%22,%22day_salary%22]';
    final token = "f1178cbff3f9a07:f1d2a24b5a005b7";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'token $token'}, // Corrected headers
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body)['data'];
        setState(() {
          attendanceData = data.cast<Map<String, dynamic>>();
          filteredData = List.from(attendanceData)
            ..sort((a, b) => (b['date'] ?? "").compareTo(a['date'] ?? ""));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterData() {
    setState(() {
      filteredData = attendanceData.where((data) {
        bool matches = true;

        // Filter for attendance, employee, and shift
        searchControllers.forEach((key, controller) {
          final searchValue = controller.text.toLowerCase();
          final dataValue = data[key]?.toString().toLowerCase() ?? '';
          if (searchValue.isNotEmpty && !dataValue.contains(searchValue)) {
            matches = false;
          }
        });

        // Filter for date
        if (selectedDate.isNotEmpty &&


            !(data['date']?.toString() ?? "").contains(selectedDate)) {
          matches = false;
        }

        return matches;
      }).toList()
        ..sort((a, b) => (b['date'] ?? "").compareTo(a['date'] ?? ""));
    });
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        filterData(); // Trigger the filter after date selection
      });
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return false;
  }

  Future<void> _downloadExcelFile(List<Map<String, dynamic>> data) async {
    try {
      // Step 1: Create an Excel Workbook
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];

      // Step 2: Add Headers
      const List<String> headers = [
        "Attendance",
        "Date",
        "Employee",
        "Shift",
        "Day Salary",
        "In Time",
        "Out Time",
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      }

      // Step 3: Add Data Rows
      for (int i = 0; i < data.length; i++) {
        final row = data[i];
        sheet.getRangeByIndex(i + 2, 1).setText(row["attendance"] ?? "");
        sheet.getRangeByIndex(i + 2, 2).setText(row["date"] ?? "");
        sheet.getRangeByIndex(i + 2, 3).setText(row["employee"] ?? "");
        sheet.getRangeByIndex(i + 2, 4).setText(row["shift"] ?? "");
        sheet
            .getRangeByIndex(i + 2, 5)
            .setNumber(row["day_salary"] != null ? double.parse(row["day_salary"].toString()) : 0.0);
        sheet.getRangeByIndex(i + 2, 6).setText(row["in_time"] ?? "");
        sheet.getRangeByIndex(i + 2, 7).setText(row["out_time"] ?? "");
      }

      // Step 4: Save the Excel File
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      // Create directory if it doesn't exist
      final directory = Directory('/storage/emulated/0/Download/Employee Attendance Report');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final String path = '${directory.path}/EmployeeAttendanceReport.xlsx';
      final File file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      // Step 5: Share the File
      await Share.shareXFiles([XFile(path)], text: "Employee Attendance Report");
    } catch (e) {
      debugPrint("Error generating or sharing Excel file: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xff967e64),
        title: Text(
          "  Employee Attendance Report",
          style: GoogleFonts.outfit(
            textStyle: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _downloadExcelFile(filteredData); // Pass your filteredData here
            },
            icon: const Icon(Icons.download, color: Colors.white),
          ),

        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(
            height: 10.h,
          ),
          // Search filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Attendance Filter
                filterField('attendance'),
                // Date Filter (Date Picker with Clear Button)
                SizedBox(
                  width: 120,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: selectDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: "Date",
                                labelStyle: GoogleFonts.outfit(
                                  textStyle: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              child: Text(
                                selectedDate.isNotEmpty
                                    ? selectedDate
                                    : "Select Date",
                                style: GoogleFonts.outfit(
                                  textStyle: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (selectedDate
                            .isNotEmpty) // Show clear button only if a date is selected
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                selectedDate = ""; // Clear the selected date
                                filterData(); // Trigger filter update
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                // Employee Filter
                filterField('employee'),
                // Shift Filter
                filterField('shift'),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    dataRowHeight: 40, // Reduce row height
                    columnSpacing: 17, // Reduce column spacing
                    columns: [
                      DataColumn(
                          label: Text("Attendance",
                              style: GoogleFonts.dmSans(
                                textStyle: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ))),
                      DataColumn(
                          label: Text("Date",
                              style: GoogleFonts.outfit(
                                textStyle: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ))),
                      DataColumn(
                          label: Text("Employee",
                              style: GoogleFonts.outfit(
                                textStyle: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ))),
                      DataColumn(
                          label: Text("Shift",
                              style: GoogleFonts.outfit(
                                textStyle: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ))),
                      DataColumn(
                          label: Text(" Salary",
                              style: GoogleFonts.outfit(
                                textStyle: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ))),
                      DataColumn(
                          label: Text("In Time",
                              style: GoogleFonts.outfit(
                                textStyle: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ))),
                      DataColumn(
                          label: Text("Out Time",
                              style: GoogleFonts.outfit(
                                textStyle: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ))),
                    ],
                    rows: filteredData
                        .asMap()
                        .entries
                        .map(
                          (entry) => DataRow(
                        color:
                        WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) {
                            // Alternate row colors: Green for odd, Blue for even
                            return entry.key % 2 == 0
                                ? Colors.white
                                : Colors.grey.shade200;
                          },
                        ),
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 5, // Small dot size
                                  backgroundColor: entry.value["attendance"] == "Present"
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                SizedBox(width: 8), // Add some spacing between dot and text
                                Text(entry.value["attendance"] ?? "",
                                    style: GoogleFonts.dmSans(
                                      textStyle: TextStyle(
                                        fontSize: 14.2.sp,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                      ),
                                    )),
                              ],
                            ),
                          ),

                          DataCell(
                            Text(
                              entry.value["date"] != null
                                  ? DateFormat('dd-MM-yyyy').format(
                                  DateTime.parse(
                                      entry.value["date"]))
                                  : "",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                textStyle: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(entry.value["employee"] ?? "",
                              style: GoogleFonts.dmSans(
                                textStyle: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ))),
                          DataCell(
                              Text(entry.value["shift"] ?? "",
                                  style: GoogleFonts.dmSans(
                                    textStyle: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ))),
                          DataCell(
                            Text(
                              entry.value["day_salary"] != null
                                  ? entry.value["day_salary"].toStringAsFixed(2) // Format to 2 decimal places
                                  : "", // Default to an empty string if null
                              style: GoogleFonts.dmSans(
                                textStyle: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),

                          DataCell(
                            Align(
                              alignment: Alignment
                                  .centerLeft, // Align text to the left
                              child: Text(
                                entry.value["in_time"] ?? "",
                                style: GoogleFonts.outfit(
                                  textStyle: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                              Text(entry.value["out_time"] ?? "",
                                  style: GoogleFonts.dmSans(
                                    textStyle: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ))),
                        ],
                      ),
                    )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget filterField(String label) {
    return SizedBox(
      width: 120.w,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: searchControllers[label],
          onChanged: (value) => filterData(),
          decoration: InputDecoration(
            labelText: label.capitalize(),
            labelStyle: GoogleFonts.outfit(
              textStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}