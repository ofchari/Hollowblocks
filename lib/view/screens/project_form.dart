import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:vetri_hollowblock/view/screens/employee.dart';
import 'package:vetri_hollowblock/view/screens/pdf_view.dart';
import 'package:vetri_hollowblock/view/screens/project_details.dart';
import 'package:http/http.dart'as http;
import 'package:vetri_hollowblock/view/screens/project_form_dropdown.dart';
import 'package:vetri_hollowblock/view/universal_key_api/api_url.dart';
import 'package:pdf/widgets.dart' as pw;
import '../widgets/buttons.dart';
import '../widgets/subhead.dart';
import 'dashboard.dart';
import 'package:path_provider/path_provider.dart';

class ProjectForm extends StatefulWidget {
  const ProjectForm({super.key});

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  late double height;
  late double width;

  String? selectedWorkType;
  String? selectedSchema;
  String? selectedSchemaGroupName;
  String? selectedWorkGroupName;
  String? selectedAgencyName;
  String? selectedDistrictName;
  String? selectedBlockName;
  String? selectedVillageName;
  String? selectedStatus;

  // Text controllers for date fields
 final TextEditingController Nameoftheworkr = TextEditingController();
 final TextEditingController Financial = TextEditingController();
 final TextEditingController cuurentstage = TextEditingController();
 final TextEditingController initalamount = TextEditingController();
  final TextEditingController _lastVisitedDateController = TextEditingController();
  final TextEditingController _asDateController = TextEditingController();
  final TextEditingController _vsDateController = TextEditingController();


              /// PDF Generate logic //
  Future<File> generateProfessionalPdf() async {
    final pdf = pw.Document();

    // Use default font or system font
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Project Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 12)),
              ],
            ),
          ),

          // Logo and Title
          pw.Container(
            alignment: pw.Alignment.center,
            margin: pw.EdgeInsets.symmetric(vertical: 20),
            child: pw.Text('Company Details',
                style: pw.TextStyle(fontSize: 20)),
          ),

          // Table for Data
          pw.Table.fromTextArray(
            headers: ['Field', 'Value'],
            data: [
              ['Name of Work', Nameoftheworkr.text],
              ['Financial Year', Financial.text],
              ['Current Stage', cuurentstage.text],
              ['Initial Amount', initalamount.text],
              ['Last Visited Date', _lastVisitedDateController.text],
              ['As Date', _asDateController.text],
              ['Vs Date', _vsDateController.text],
              ['Work Type', selectedWorkType ?? ''],
              ['Scheme Name', selectedSchema ?? ''],
              ['Scheme Group', selectedSchemaGroupName ?? ''],
              ['Work Group', selectedWorkGroupName ?? ''],
              ['Agency Name', selectedAgencyName ?? ''],
              ['District', selectedDistrictName ?? ''],
              ['Block', selectedBlockName ?? ''],
              ['Village', selectedVillageName ?? ''],
            ],
            border: pw.TableBorder.all(),
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(fontSize: 10),
          ),

          // Footer
          pw.Container(
            alignment: pw.Alignment.center,
            margin: pw.EdgeInsets.only(top: 50),
            child: pw.Text(
              'Thank you for choosing our service!',
              style: pw.TextStyle(
                  fontSize: 12, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: pw.EdgeInsets.only(top: 1 * PdfPageFormat.cm),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 12),
          ),
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/professional_project_report.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }
              /// Post method for Project Form //
  Future<void> MobileDocument(BuildContext context) async {
    HttpClient client = HttpClient();
    client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    final data = {
      'doctype': 'Project Form',
      'work': Nameoftheworkr.text,
      'work_type': selectedWorkType,
      'scheme_name': selectedSchema,
      'scheme_group': selectedSchemaGroupName,
      'work_group': selectedWorkGroupName,
      'agency_name': selectedAgencyName,
      'financial_year': Financial.text,
      'district': selectedDistrictName,
      'block': selectedBlockName,
      'village': selectedVillageName,
      'current_stage': selectedStatus,
      'initial_amount': initalamount.text,
      'last_visited_date': _lastVisitedDateController.text,
      'as_date': _asDateController.text,
      'vs_date': _vsDateController.text,

    };

    final url = '$apiUrl/Project Form'; // Replace with your actual API URL
    final body = jsonEncode(data);
    print(data);

    try {
      // Use Uri.parse() to convert the string URL into a Uri object
      final response = await ioClient.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        Get.snackbar(
          "Project Form",
          "Document Posted Successfully",
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );
        Navigator.of(context).pop(Nameoftheworkr.text); // Return project name to Dashboard
      }
      else {
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
  void initState() {
    // TODO: implement initState
    super.initState();
    print(Nameoftheworkr.text);
    print(Financial.text);
    print(cuurentstage.text);
    print(initalamount.text);

  }

  @override
  void dispose() {
    _lastVisitedDateController.dispose();
    _asDateController.dispose();
    _vsDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define Sizes //
    var size = MediaQuery.of(context).size;
    height = size.height.h;
    width = size.width.w;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        height = constraints.maxHeight;
        width = constraints.maxWidth;
        if (width <= 450) {
          return _smallBuildLayout();
        } else {
          return Text("Please make sure your device is in portrait view");
        }
      },
    );
  }

  // Your existing layout and form fields remain the same
  Widget _smallBuildLayout() {
    return Scaffold(
      backgroundColor: const Color(0xfff1f2f4),
      appBar: AppBar(
        backgroundColor: const Color(0xfff1f2f4),
        toolbarHeight: 80.h,
        centerTitle: true,
        title: Subhead(
          text: "Add Project Form",
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
              _buildTextField(
                controller: Nameoftheworkr,
                hintText: "   Name of the work",
                icon: Icons.drive_file_rename_outline,

              ),
              SizedBox(height: 30.h),
              _buildDropdownField(
                apiUrl: "$apiUrl/Work%20Type",
                hintText: "   Work Type",
                selectedValue: selectedWorkType,
                onChanged: (value) {
                  setState(() {
                    selectedWorkType = value;
                    print(selectedWorkType);
                  });

                }, hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
                onAddNewRoute: () {
                  Get.toNamed('/worktype'); // Use GetX to navigate to the "Add Work Type" page
                },
              ),
              SizedBox(height: 30.h),
              _buildDropdownField(
                apiUrl: "$apiUrl/Scheme",
                hintText: "   Scheme Name",

                selectedValue: selectedSchema,
                onChanged: (value) {
                  setState(() {
                    selectedSchema = value;
                    print(selectedSchema);
                  });
                },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
                onAddNewRoute: () {
                  Get.toNamed('/scheme'); // Use GetX to navigate to the "Add Work Type" page
                },
              ),
              SizedBox(height: 30.h),
              _buildDropdownField(
                apiUrl: "$apiUrl/Scheme Group",
                hintText: "   Scheme Group",
                selectedValue: selectedSchemaGroupName,
                onChanged: (value) {
                  setState(() {
                    selectedSchemaGroupName = value;
                    print(selectedSchemaGroupName);
                  });
                },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
                onAddNewRoute: () {
                  Get.toNamed('/schemegroup'); // Use GetX to navigate to the "Add Work Type" page
                },
              ),
              SizedBox(height: 30.h),
              _buildDropdownField(
                apiUrl: "$apiUrl/Work Group",
                hintText: "   Work Group",
                selectedValue: selectedWorkGroupName,
                onChanged: (value) {
                  setState(() {
                    selectedWorkGroupName = value;
                    print(selectedWorkGroupName);
                  });
                },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
                onAddNewRoute: () {
                  Get.toNamed('/workgroup'); // Use GetX to navigate to the "Add Work Type" page
                },
              ),
              SizedBox(height: 30.h),
              _buildDropdownField(
                apiUrl: "$apiUrl/Agency",
                hintText: "   Agency Name",
                selectedValue: selectedAgencyName,
                onChanged: (value) {
                  setState(() {
                    selectedAgencyName = value;
                    print(selectedAgencyName);
                  });
                },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
                onAddNewRoute: () {
                  Get.toNamed('/agency'); // Use GetX to navigate to the "Add Work Type" page
                },
              ),
              SizedBox(height: 30.h),
              _buildTextField(
                hintText: "   Financial year",
                icon: Icons.date_range,
                controller: Financial,
                isDateField: true,
              ),
              SizedBox(height: 30.h),
              _buildDropdownField(
                apiUrl: "$apiUrl/District",
                hintText: "   District",
                selectedValue: selectedDistrictName,
                onChanged: (value) {
                  setState(() {
                    selectedDistrictName = value;
                    print(selectedDistrictName);
                  });
                },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
                onAddNewRoute: () {
                  Get.toNamed('/district'); // Use GetX to navigate to the "Add Work Type" page
                },
              ),
              SizedBox(height: 30.h),
              _buildDropdownField(
                apiUrl: "$apiUrl/Block",
                hintText: "   Block",
                selectedValue: selectedBlockName,
                onChanged: (value) {
                  setState(() {
                    selectedBlockName = value;
                    print(selectedBlockName);
                  });
                },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
                onAddNewRoute: () {
                  Get.toNamed('/block'); // Use GetX to navigate to the "Add Work Type" page
                },
              ),
              SizedBox(height: 30.h),
              _buildDropdownField(
                apiUrl: "$apiUrl/Village",
                hintText: "   Village",
                selectedValue: selectedVillageName,
                onChanged: (value) {
                  setState(() {
                    selectedVillageName = value;
                    print(selectedVillageName);
                  });
                },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
                onAddNewRoute: () {
                  Get.toNamed('/village'); // Use GetX to navigate to the "Add Work Type" page
                },
              ),
              SizedBox(height: 30.h),
              _buildDropdownField(
                apiUrl: "$apiUrl/Construction Status",
                hintText: "   Status",
                selectedValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                    print(selectedStatus);
                  });
                },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
                onAddNewRoute: () {
                  Get.toNamed('/status'); // Use GetX to navigate to the "Add Work Type" page
                },
              ),
              SizedBox(height: 30.h),
              _buildTextField(
                controller: initalamount,
                hintText: "   Initial Amount",
                icon: Icons.monetization_on,
              ),
              SizedBox(height: 30.h),
              _buildTextField(
                hintText: "   Last Visited Date",
                icon: Icons.date_range,
                controller: _lastVisitedDateController,
                isDateField: true,
              ),
              SizedBox(height: 30.h),
              _buildTextField(
                hintText: "   As Date",
                icon: Icons.date_range,
                controller: _asDateController,
                isDateField: true,
              ),
              SizedBox(height: 30.h),
              _buildTextField(
                hintText: "   Vs Date",
                icon: Icons.date_range,
                controller: _vsDateController,
                isDateField: true,
              ),
              SizedBox(height: 10.h),
              // GestureDetector(
              //   onTap: () async {
              //     final pdfFile = await generateProfessionalPdf();
              //     // Navigate to the PDF preview screen
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => PdfPreviewScreen(pdfFile: pdfFile),
              //       ),
              //     );
              //   },
              //   child: Buttons(
              //     height: height / 20.h,
              //     width: width / 2.5.w,
              //     radius: BorderRadius.circular(10.r),
              //     color: Colors.blue,
              //     text: "Submit",
              //   ),
              // ),

              GestureDetector(
                onTap: () async {
                  // final pdfFile = await generateProfessionalPdf();
                  // Navigator.pop(context, Nameoftheworkr.text); // Return project name
                  MobileDocument(context);
                },
                child: Buttons(
                  height: height / 20.h,
                  width: width / 2.5.w,
                  radius: BorderRadius.circular(10.r),
                  color: Colors.blue,
                  text: "Submit",
                ),
              ),

              SizedBox(height: 20.h),

            ],
          ),
        ),
      ),
    );
  }

  /// Dropdown field //
  Widget _buildDropdownField({
    required String apiUrl,
    required String hintText,
    required TextStyle hintStyle,
    required String? selectedValue,
    required Function(String?) onChanged,
    required Function onAddNewRoute, // Pass the onAddNewRoute callback
  }) {
    return DropdownField(
      apiUrl: apiUrl,
      hintText: hintText,
      hintStyle: hintStyle,
      onChanged: onChanged,
      selectedValue: selectedValue,
      onAddNewRoute: onAddNewRoute, // Pass it to DropdownField
    );
  }



  // Updated _buildTextField method
  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    TextEditingController? controller,
    bool isDateField = false, // Boolean flag to identify date fields
  }) {
    return Container(
      height: height / 15.2.h,
      width: width / 1.09.w,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: Colors.grey.shade500,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        child: TextFormField(
          controller: controller,
          style: GoogleFonts.dmSans(
            textStyle: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.only(left: 20.0),
            prefixIconConstraints: BoxConstraints(
              minWidth: 24,minHeight: 24
            ),
            prefixIcon: Icon(icon, size: 16), // Icon size adjusted to 16
            hintText: hintText,
            hintStyle: GoogleFonts.sora(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            border: InputBorder.none,
          ),
          onTap: isDateField
              ? () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              controller?.text = DateFormat('yyyy-MM-dd').format(pickedDate);
            }
          }
              : null,
        ),
      ),
    );
  }
}
