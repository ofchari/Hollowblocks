import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:share_plus/share_plus.dart';

class MaterialPurchaseReport extends StatefulWidget {
  const MaterialPurchaseReport({super.key,required this.projectName});
  final String projectName;

  @override
  State<MaterialPurchaseReport> createState() => _MaterialPurchaseReportState();
}

class _MaterialPurchaseReportState extends State<MaterialPurchaseReport> {
  late double height;
  late double width;

  List<Map<String, dynamic>> materialData = [];
  List<Map<String, dynamic>> filteredData = [];
  bool isLoading = true;

  final Map<String, TextEditingController> searchControllers = {
    'party_name': TextEditingController(),
    'material': TextEditingController(),
    'reference_no': TextEditingController(),
    'quantity': TextEditingController(),
    'date': TextEditingController(),
  };

  String selectedDate = "";

  final dateController = TextEditingController();

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
    final encodedProjectName = Uri.encodeComponent(widget.projectName);
    final url =
        'https://vetri.regenterp.com/api/method/regent.sales.client.get_mobile_material_purchased?name=$encodedProjectName';
    final token = "f1178cbff3f9a07:f1d2a24b5a005b7";

    try {
      final response = await http.get(Uri.parse(url), headers: {'Authorization': 'token $token'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Safely extract 'message' field and handle null case
        if (responseData.containsKey('message') && responseData['message'] != null) {
          final List<dynamic> data = responseData['message'];

          setState(() {
            materialData = data.cast<Map<String, dynamic>>();
            filteredData = List.from(materialData)
              ..sort((a, b) => (b['date'] ?? "").compareTo(a['date'] ?? ""));
            isLoading = false;
          });
        } else {
          // Handle case when message is null
          setState(() {
            materialData = [];
            filteredData = [];
            isLoading = false;
          });
          print("Error: API response 'message' is null or missing.");
        }
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

  Future<void> _downloadExcelFile(List<Map<String, dynamic>> data) async {
    try {
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];

      const List<String> headers = [
        "Party Name",
        "Material",
        "Reference No",
        "Quantity",
        "Unit Rate",
        "GST",
        "Additional Discount",
        "Sub Total",
        "Total",
        "Date",
        "Additional Notes"
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      }

      for (int i = 0; i < data.length; i++) {
        final row = data[i];
        sheet.getRangeByIndex(i + 2, 1).setText(row["party_name"] ?? "");
        sheet.getRangeByIndex(i + 2, 2).setText(row["material"] ?? "");
        sheet.getRangeByIndex(i + 2, 3).setText(row["reference_no"] ?? "");
        sheet.getRangeByIndex(i + 2, 4).setNumber(double.tryParse(row["quantity"].toString()) ?? 0.0);
        sheet.getRangeByIndex(i + 2, 5).setNumber(double.tryParse(row["unit_rate"].toString()) ?? 0.0);
        sheet.getRangeByIndex(i + 2, 6).setNumber(double.tryParse(row["gst"].toString()) ?? 0.0);
        sheet.getRangeByIndex(i + 2, 7).setNumber(double.tryParse(row["additional_discount"].toString()) ?? 0.0);
        sheet.getRangeByIndex(i + 2, 8).setNumber(double.tryParse(row["sub_total"].toString()) ?? 0.0);
        sheet.getRangeByIndex(i + 2, 9).setNumber(double.tryParse(row["total"].toString()) ?? 0.0);
        sheet.getRangeByIndex(i + 2, 10).setText(row["date"] ?? "");
        sheet.getRangeByIndex(i + 2, 11).setText(row["add_notes"] ?? "");
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final directory = Directory('/storage/emulated/0/Download/Material Purchase Report');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final String path = '${directory.path}/MaterialPurchaseReport.xlsx';
      final File file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles([XFile(path)], text: "Material Purchase Report");
    } catch (e) {
      debugPrint("Error generating or sharing Excel file: $e");
    }
  }

  /// Date format change methods //
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
          "Material Purchase Report",
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
                filterField('material'),
                filterField('reference_no'),
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
                    dataRowHeight: 40,
                    columnSpacing: 17,
                    columns: _buildDataColumns(),
                    rows: filteredData.map((data) => _buildDataRow(data)).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _buildDataColumns() {
    final columns = [
      "Date",
      "Party Name",
      "Material",
      "Reference No",
      "Quantity",
      "Total",
      "Unit Rate",
      "GST",
      "Add. Discount",
      "Sub Total",
    ];

    return columns.map((column) => DataColumn(
      label: Text(
        column,
        style: GoogleFonts.dmSans(
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    )).toList();
  }

  DataRow _buildDataRow(Map<String, dynamic> data) {
    final cells = [
      formatDate(data['date'] ?? ''),
      data['party_name'] ?? '',
      data['material'] ?? '',
      data['reference_no'] ?? '',
      data['quantity']?.toString() ?? '',
      data['total']?.toString() ?? '',
      data['unit_rate']?.toString() ?? '',
      data['gst']?.toString() ?? '',
      data['additional_discount']?.toString() ?? '',
      data['sub_total']?.toString() ?? '',


    ];

    return DataRow(
      cells: cells.map((cell) => DataCell(
        Text(
          cell,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            textStyle: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      )).toList(),
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
            labelText: label.replaceAll('_', ' ').capitalize(),
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
    return split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}