import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:share_plus/share_plus.dart';

class ReportsReceived extends StatefulWidget {
  const ReportsReceived({super.key});

  @override
  State<ReportsReceived> createState() => _ReportsReceivedState();
}

class _ReportsReceivedState extends State<ReportsReceived> {
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
    final url =
        'https://vetri.regenterp.com/api/resource/Material%20Received?fields=[%22party_name%22,%22material_name%22,%22quantity%22,%22date%22]';
    final token = "f1178cbff3f9a07:f1d2a24b5a005b7";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'token $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body)['data'];
        setState(() {
          materialData = data.cast<Map<String, dynamic>>();
          filteredData = List.from(materialData)
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
        sheet
            .getRangeByIndex(i + 2, 3)
            .setNumber(double.tryParse(row["quantity"].toString()) ?? 0.0);
        sheet.getRangeByIndex(i + 2, 4).setText(row["date"] ?? "");
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final directory = Directory('/storage/emulated/0/Download/Material Received Report');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final String path = '${directory.path}/MaterialReceivedReport.xlsx';
      final File file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles([XFile(path)], text: "Material Received Report");
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
                filterField('party_name'),
                filterField('material_name'),
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
                    dataRowHeight: 40, // Reduce row height
                    columnSpacing: 17, // Reduce column spacing
                    columns: [
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
                      DataColumn(label: Text("Date",style: GoogleFonts.dmSans(
                        textStyle: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),))),
                    ],
                    rows: filteredData
                        .map((data) => DataRow(
                      cells: [
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
                        DataCell(Text(data['date'] ?? '',textAlign: TextAlign.center,
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