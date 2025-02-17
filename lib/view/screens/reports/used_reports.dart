import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:share_plus/share_plus.dart';

class MaterialUsedReport extends StatefulWidget {
  const MaterialUsedReport({super.key,required this.projectName});
  final String projectName;

  @override
  State<MaterialUsedReport> createState() => _MaterialUsedReportState();
}

class _MaterialUsedReportState extends State<MaterialUsedReport> {
  late double height;
  late double width;

  List<Map<String, dynamic>> materialData = [];
  List<Map<String, dynamic>> filteredData = [];
  bool isLoading = true;

  final Map<String, TextEditingController> searchControllers = {
    'material': TextEditingController(),
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
    for (var controller in searchControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> fetchMaterialData() async {
    // ✅ URL for fetching material data
    final encodedProjectName = Uri.encodeComponent(widget.projectName);
    final url = 'https://vetri.regenterp.com/api/method/regent.sales.client.get_mobile_material_used?name=$encodedProjectName';

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

  void filterData() {
    setState(() {
      filteredData = materialData.where((data) {
        bool matches = true;

        searchControllers.forEach((key, controller) {
          final searchValue = controller.text.toLowerCase();
          final dataValue = data[key]?.toString().toLowerCase() ?? '';
          if (searchValue.isNotEmpty && !dataValue.contains(searchValue)) {
            matches = false;
          }
        });

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
        filterData();
      });
    }
  }

  Future<void> _downloadExcelFile(List<Map<String, dynamic>> data) async {
    try {
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];

      const List<String> headers = [
        "Material",
        "Quantity",
        "Date",
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      }

      for (int i = 0; i < data.length; i++) {
        final row = data[i];
        sheet.getRangeByIndex(i + 2, 1).setText(row["material"] ?? "");
        sheet
            .getRangeByIndex(i + 2, 2)
            .setNumber(double.tryParse(row["quantity"].toString()) ?? 0.0);
        sheet.getRangeByIndex(i + 2, 3).setText(row["date"] ?? "");
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final directory = Directory('/storage/emulated/0/Download/Material Used');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final String path = '${directory.path}/MaterialUsedReport.xlsx';
      final File file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles([XFile(path)], text: "Material Used Report");
    } catch (e) {
      debugPrint("Error generating or sharing Excel file: $e");
    }
  }
      /// Date Format changes //
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
          "Material Used Report",
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
                filterField('material'),
                filterField('quantity'),
                filterField('date'),
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
                    dataRowHeight: 40,
                    columnSpacing: 17,
                    columns: [
                      DataColumn(
                        label: Text(
                          "Material",
                          style: GoogleFonts.dmSans(
                            textStyle: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Quantity",
                          style: GoogleFonts.dmSans(
                            textStyle: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Date",
                          style: GoogleFonts.dmSans(
                            textStyle: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows: filteredData
                        .map(
                          (data) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              data['material'] ?? '',
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
                          DataCell(
                            Text(
                              data['quantity']?.toString() ?? '',
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
                          DataCell(
                            Text(
                              formatDate(data['date'] ?? ''),
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