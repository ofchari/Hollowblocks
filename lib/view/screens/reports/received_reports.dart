import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:share_plus/share_plus.dart';

class MaterialReceivedReport extends StatefulWidget {
  const MaterialReceivedReport({super.key,required this.projectName});
  final String projectName;

  @override
  State<MaterialReceivedReport> createState() => _MaterialReceivedReportState();
}

class _MaterialReceivedReportState extends State<MaterialReceivedReport> {
  late double height;
  late double width;

  List<Map<String, dynamic>> materialData = [];
  List<Map<String, dynamic>> filteredData = [];
  bool isLoading = true;

  // Define controllers for search fields
  final Map<String, TextEditingController> searchControllers = {
    'party_name': TextEditingController(),
    'material_name': TextEditingController(),
    'quantity': TextEditingController(),
    'date': TextEditingController(),
  };

  String selectedDate = "";

  @override
  void initState() {
    super.initState();
    fetchMaterialData();
  }

  @override
  void dispose() {
    // Dispose controllers
    for (var controller in searchControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> fetchMaterialData() async {
    // ✅ URL for fetching material data
    final encodedProjectName = Uri.encodeComponent(widget.projectName);
    final url = 'https://vetri.regenterp.com/api/method/regent.sales.client.get_mobile_material_received?name=$encodedProjectName';

                   // ✅ Authentication Token
    final token = "f1178cbff3f9a07:f1d2a24b5a005b7";

    print('Fetching purchased data from: $url'); // Debug log

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'token $token'},
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        final List data;
        print(response.body);

        // ✅ Handling response structure
        data = decodedResponse['message'] ?? [];

        setState(() {
          materialData = data.cast<Map<String, dynamic>>();
          filteredData = List.from(materialData)
            ..sort((a, b) => (b['date'] ?? "").compareTo(a['date'] ?? ""));
          isLoading = false;
        });

        if (data.isEmpty) {
          print('⚠️ No data found for the current query.');
        }
      } else {
        setState(() {
          isLoading = false;
        });
        print("❌ Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      print("❌ Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }



  // Future<void> selectDate() async {
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime(2000),
  //     lastDate: DateTime(2100),
  //   );
  //   if (picked != null) {
  //     setState(() {
  //       selectedDate =
  //       "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
  //       filterData();
  //     });
  //   }
  //
  // }



  Future<void> _downloadExcelFile(List<Map<String, dynamic>> data) async {
    try {
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];

      const List<String> headers = [
        "Party Name",
        "Material Name",
        "Quantity",
        "Date",
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      }

      for (int i = 0; i < data.length; i++) {
        final row = data[i];
        sheet.getRangeByIndex(i + 2, 1).setText(row["party_name"] ?? "");
        sheet.getRangeByIndex(i + 2, 2).setText(row["material_name"] ?? "");
        sheet.getRangeByIndex(i + 2, 3).setNumber(double.tryParse(row["quantity"].toString()) ?? 0.0);
        sheet.getRangeByIndex(i + 2, 4).setText(row["date"] ?? "");
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      // ✅ Get App-Specific Storage Directory
      final Directory? directory = await getExternalStorageDirectory();
      if (directory == null) throw Exception("Storage directory not found");

      // ✅ Ensure directory exists
      final String folderPath = '${directory.path}/Material_Reports';
      final Directory newDir = Directory(folderPath);
      if (!await newDir.exists()) {
        await newDir.create(recursive: true);
      }

      // ✅ Save the file inside the app’s allowed storage
      final String filePath = '$folderPath/MaterialReceivedReport.xlsx';
      final File file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      // ✅ Share the file
      await Share.shareXFiles([XFile(filePath)], text: "Material Received Report");
    } catch (e) {
      debugPrint("Error generating or sharing Excel file: $e");
    }
  }


  void filterData() {
    setState(() {
      filteredData = materialData.where((data) {
        bool matches = true;

        // Handle text-based filters
        searchControllers.forEach((key, controller) {
          final searchValue = controller.text.toLowerCase();
          final dataValue = data[key]?.toString().toLowerCase() ?? '';
          if (searchValue.isNotEmpty && !dataValue.contains(searchValue)) {
            matches = false;
          }
        });

        // Handle date filter
        if (dateController.text.isNotEmpty) {
          try {
            final filterDate = dateController.text; // in yyyy-MM-dd format
            final dataDate = data['date']?.toString().split(' ')[0] ?? ''; // Get only the date part

            if (dataDate != filterDate) {
              matches = false;
            }
          } catch (e) {
            print('Error comparing dates: $e');
            matches = false;
          }
        }

        return matches;
      }).toList()
        ..sort((a, b) => (b['date'] ?? "").compareTo(a['date'] ?? ""));
    });
  }

  // Update the build method's date filter field
  Widget buildDateFilter() {
    return SizedBox(
      width: 200,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: dateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Select Date',
            labelStyle: GoogleFonts.outfit(
              textStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );

            if (pickedDate != null) {
              setState(() {
                dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                filterData(); // Call filterData immediately when date is selected
              });
            }
          },
        ),
      ),
    );
  }
      //// Date format change method //
  String formatDate(String dateString) {
    try {
      // Parse the date string to a DateTime object
      DateTime date = DateTime.parse(dateString);
      // Format the date as 'dd-MM-yyyy'
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      // If there's an error parsing the date, return an empty string
      return '';
    }
  }

final dateController = TextEditingController();

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
          "Material Received Report",
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
              await _downloadExcelFile(filteredData);
            },
            icon: const Icon(Icons.download, color: Colors.white),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(height: 10.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildDateFilter(),
                filterField('party_name'),
                filterField('material_name'),
                // filterField('quantity'),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    dataRowHeight: 40, // Reduce row height
                    columnSpacing: 17, // Reduce column spacing
                    columns: [
                      DataColumn(label: Text("Date",style: GoogleFonts.dmSans(
                        textStyle: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),))),
                      DataColumn(label: Text("Party Name",style: GoogleFonts.dmSans(
                        textStyle: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),)),),
                      DataColumn(label: Text("Material Name",style: GoogleFonts.dmSans(
                        textStyle: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),))),
                      DataColumn(label: Text("Quantity",style: GoogleFonts.dmSans(
                        textStyle: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),))),

                    ],
                    rows: filteredData
                        .map((data) => DataRow(
                      cells: [
                        DataCell(Text( formatDate(data['date'] ?? ''),textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            textStyle: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),)),
                        DataCell(Text(data['party_name'] ?? '',textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            textStyle: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        ),
                        DataCell(Text(data['material_name'] ?? '',textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            textStyle: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),)),
                        DataCell(Text(data['quantity']?.toString() ?? '',textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            textStyle: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),)),

                      ],
                    ))
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