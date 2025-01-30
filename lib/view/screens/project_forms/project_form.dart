import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:vetri_hollowblock/view/screens/employee/employee.dart';
import 'package:vetri_hollowblock/view/screens/pdf_view.dart';
import 'package:vetri_hollowblock/view/screens/project_details.dart';
import 'package:http/http.dart'as http;
import 'package:vetri_hollowblock/view/screens/project_forms/project_form_dropdown.dart';
import 'package:vetri_hollowblock/view/universal_key_api/api_url.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../widgets/buttons.dart';
import '../../widgets/subhead.dart';
import '../dashboard.dart';
import 'package:path_provider/path_provider.dart';

class ProjectForm extends StatefulWidget {
  const ProjectForm({super.key});

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  final ProjectFormController controller = Get.put(ProjectFormController());
  late double height;
  late double width;

  String? selectedWorkType;
  String? selectedSchema;
  String? selectedSchemaGroupName;
  String? selectedWorkGroupName;
  String? selectedAgencyName;
  String? selectedLevelName;
  String? selectedDistrictName;
  String? selectedBlockName;
  String? selectedVillageName;
  String? selectedStatus;

  // Text controllers for date fields
 final TextEditingController Nameoftheworkr = TextEditingController();
  TextEditingController financialYearController = TextEditingController();
 final TextEditingController cuurentstage = TextEditingController();
 final TextEditingController initalamount = TextEditingController();
 final TextEditingController depositamount = TextEditingController();
  final TextEditingController _lastVisitedDateController = TextEditingController();
  final TextEditingController _asDateController = TextEditingController();
  final TextEditingController _vsDateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();



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
            child: pw.Text('Vetri Company Details',
                style: pw.TextStyle(fontSize: 20)),
          ),

          // Table for Data
          pw.Table.fromTextArray(
            headers: ['Field', 'Value'],
            data: [
              ['Name of Work', Nameoftheworkr.text],
              ['Work Type', selectedWorkType ?? ''],
              ['Scheme Name', selectedSchema ?? ''],
              ['Scheme Group Name', selectedSchemaGroupName ?? ''],
              ['Work Group Name', selectedWorkGroupName ?? ''],
              ['Agency Name', selectedAgencyName ?? ''],
              ['Level Name', selectedLevelName ?? ''],
              ['Financial Year', financialYearController.text],
              ['District', selectedDistrictName ?? ''],
              ['Block', selectedBlockName ?? ''],
              ['Village', selectedVillageName ?? ''],
              ['Current Stage', selectedStatus ?? ''],
              ['Estimate Amount', initalamount.text],
              ['Deposit Amount', depositamount.text],
              ['Remarks', remarksController.text],
              ['As Date', _asDateController.text],
              ['Work Order Date', _lastVisitedDateController.text],
              ['Project Duration', _vsDateController.text],

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
      'level': selectedLevelName,
      'financial_year': financialYearController.text,
      'district': selectedDistrictName,
      'block': selectedBlockName,
      'village': selectedVillageName,
      'current_stage': selectedStatus,
      'estimate_amount': initalamount.text,
      'deposite_amount': depositamount.text,
      'work_order_date': _vsDateController.text,
      'as_date': _asDateController.text,
      'project_duration': _lastVisitedDateController.text,
      'remarks': remarksController.text,
    };

    final url = '$apiUrl/Project Form';
    final body = jsonEncode(data);

    try {
      final response = await ioClient.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        // Use Get.snackbar since you're using GetX
        Get.snackbar(
          "Project Form",
          "Document Posted Successfully",
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );
        return; // Just return without navigation
      } else {
        String message = 'Request failed with status: ${response.statusCode}';
        if (response.statusCode == 417) {
          final serverMessages = json.decode(response.body)['_server_messages'];
          message = serverMessages ?? message;
        }
        throw Exception(message); // Throw the error to be handled by the caller
      }
    } catch (e) {
      rethrow; // Rethrow the error to be handled by the caller
    }
  }

@override
  void initState() {
    // TODO: implement initState
    super.initState();
  // Initialize text controllers with values from GetX controller
  Nameoftheworkr.text = controller.workName.value;
    // Add listener to update controller when text changes
    Nameoftheworkr.addListener(() {
      if (Nameoftheworkr.text != controller.workName.value) {
        controller.updateWorkName(Nameoftheworkr.text);
      }
    });
  financialYearController.text = controller.financialYear.value;
  initalamount.text = controller.initialAmount.value;
  depositamount.text = controller.depositAmount.value;
  _lastVisitedDateController.text = controller.lastVisitedDate.value;
  _asDateController.text = controller.asDate.value;
  _vsDateController.text = controller.tsDate.value;
  remarksController.text = controller.tsDate.value;

  // Set initial dropdown values
  selectedWorkType = controller.workType.value;
  selectedSchema = controller.schemaName.value;
  selectedSchemaGroupName = controller.schemaGroupName.value;
  selectedWorkGroupName = controller.workGroupName.value;
  selectedAgencyName = controller.agencyName.value;
  selectedLevelName = controller.levelName.value;
  selectedDistrictName = controller.districtName.value;
  selectedBlockName = controller.blockName.value;
  selectedVillageName = controller.villageName.value;
  selectedStatus = controller.status.value;
}


  @override
  void dispose() {
    Nameoftheworkr.removeListener(() {
      controller.workName.value = Nameoftheworkr.text;
    });
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
        if (width <= 1000) {
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
                onAddNewRoute: () async {
                  final result = await Get.toNamed('/worktype');
                  return result;
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
                },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black,overflow: TextOverflow.ellipsis,)),
                onAddNewRoute: () async {
                 final result = await Get.toNamed('/scheme'); // Use GetX to navigate to the "Add Work Type" page
                  return result;
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
                onAddNewRoute: () async{
                  final result = await Get.toNamed('/schemegroup'); // Use GetX to navigate to the "Add Work Type" page
                  return result;
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
                onAddNewRoute: () async{
                  final result = await Get.toNamed('/workgroup'); // Use GetX to navigate to the "Add Work Type" page
                  return result;
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
                onAddNewRoute: () async{
                  final result = await Get.toNamed('/agency'); // Use GetX to navigate to the "Add Work Type" page
                  return result;
                },
              ),
              SizedBox(height: 30.h,),
              _buildDropdownField(
                apiUrl: "$apiUrl/Level",
                hintText: "   Level Name",
                selectedValue: selectedLevelName,
                onChanged: (value) {
                  setState(() {
                    selectedLevelName = value;
                    print(selectedLevelName);
                  });
                },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
                onAddNewRoute: () async{
                  final result = await Get.toNamed('/level'); // Use GetX to navigate to the "Add Work Type" page
                  return result;
                },
              ),
              SizedBox(height: 30.h),
              _buildFinancialYearDropdown(
                  controller: financialYearController
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
                onAddNewRoute: () async{
                  final result = await Get.toNamed('/district'); // Use GetX to navigate to the "Add Work Type" page
                  return result;
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
                onAddNewRoute: () async{
                  final result = await Get.toNamed('/block'); // Use GetX to navigate to the "Add Work Type" page
                  return result;
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
                onAddNewRoute: () async{
                  final result = await Get.toNamed('/village'); // Use GetX to navigate to the "Add Work Type" page
                  return result;
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
                onAddNewRoute: () async{
                  final result = await Get.toNamed('/status'); // Use GetX to navigate to the "Add Work Type" page
                  return result;
                },
              ),
              SizedBox(height: 30.h),
              _buildTextField(
                controller: initalamount,
                hintText: "   Estimate Amount",
                icon: Icons.currency_rupee,
              ),
              SizedBox(height: 30.h),
              _buildTextField(
                controller: depositamount,
                hintText: "   Deposit Amount",
                icon: Icons.currency_rupee,
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
                hintText: "   Work Order Date",
                icon: Icons.calendar_month_outlined,
                controller: _vsDateController,
                isDateField: true,
              ),
              SizedBox(height: 30.h,),
              // SizedBox(height: 30.h),
              _buildTextField(
                hintText: "   Project Duration",
                icon: Icons.calendar_month_rounded,
                controller: _lastVisitedDateController,
                isDateField: true,
              ),
              SizedBox(height: 30.h,),
              // SizedBox(height: 30.h),
              _buildTextField(
                controller: remarksController,
                hintText: "   Remakrs",
                icon: Icons.remember_me,
              ),
              SizedBox(height: 10.h),
              // Button for generating and previewing PDF
              GestureDetector(
                onTap: () async {
                  if (Nameoftheworkr.text.isEmpty) {
                    Get.snackbar(
                      "Validation Error",
                      "Name of Work is required.",
                      colorText: Colors.white,
                      backgroundColor: Colors.red,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }

                  try {
                    final pdfFile = await generateProfessionalPdf();

                    // Show PDF preview and wait for confirmation
                    final confirmed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfPreviewScreen(
                          pdfFile: pdfFile,
                          projectName: Nameoftheworkr.text,
                        ),
                      ),
                    );

                    // If user confirmed, submit the document
                    if (confirmed == true) {
                      try {
                        await MobileDocument(context);

                        // Clear navigation stack and go to Dashboard
                        Get.offAll(() => Dashboard(), transition: Transition.noTransition);

                        Get.snackbar(
                          "Success",
                          "Project added successfully",
                          colorText: Colors.white,
                          backgroundColor: Colors.green,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } catch (e) {
                        Get.snackbar(
                          "Error",
                          "Failed to add project: $e",
                          colorText: Colors.white,
                          backgroundColor: Colors.red,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    }
                  } catch (e) {
                    // Show error dialog only if we're not in the middle of navigation
                    if (context.mounted) {
                      await showDialog(
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

  // Form Validation Function
  bool validateMandatoryFields() {
    if (Nameoftheworkr.text.isEmpty) return false;
    return true;

  }


  /// Dropdown field //

  Widget _buildDropdownField({
    required String apiUrl,
    required String hintText,
    required TextStyle hintStyle,
    required String? selectedValue,
    required Function(String?) onChanged,
    required Function onAddNewRoute,
  }) {
    return DropdownField(
      apiUrl: apiUrl,
      hintText: hintText,
      hintStyle: hintStyle,
      selectedValue: selectedValue,
      onChanged: (String? value) async {
        if (value == "add_new") {
          // Navigate and wait for result
          final result = await onAddNewRoute();
          if (result != null) {
            _updateStateAndController(hintText.trim(), result);
            onChanged(result);
          }
        } else {
          _updateStateAndController(hintText.trim(), value);
          onChanged(value);
        }
      },
      onAddNewRoute: onAddNewRoute,
    );
  }

  void _updateStateAndController(String fieldType, String? value) {
    setState(() {
      switch (fieldType) {
        case "Work Type":
          selectedWorkType = value;
          controller.workType.value = value;
          break;
        case "Scheme Name":
          selectedSchema = value;
          controller.schemaName.value = value;
          break;
        case "Scheme Group":
          selectedSchemaGroupName = value;
          controller.schemaGroupName.value = value;
          break;
        case "Work Group":
          selectedWorkGroupName = value;
          controller.workGroupName.value = value;
          break;
        case "Agency Name":
          selectedAgencyName = value;
          controller.agencyName.value = value;
          break;
        case "Level Name":
          selectedLevelName = value;
          controller.levelName.value = value;
          break;
        case "District":
          selectedDistrictName = value;
          controller.districtName.value = value;
          break;
        case "Block":
          selectedBlockName = value;
          controller.blockName.value = value;
          break;
        case "Village":
          selectedVillageName = value;
          controller.villageName.value = value;
          break;
        case "Status":
          selectedStatus = value;
          controller.status.value = value;
          break;
      }
    });
  }


/// Finanaical dropdown //
  Widget _buildFinancialYearDropdown({
    required TextEditingController controller,
  }) {
    List<String> financialYears = [
      "23-24",
      "24-25",
      "25-26",
      "26-27",
      "27-28",
      "28-29",
      "29-30"
    ];

    FocusNode _focusNode = FocusNode();

    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          // Show the dropdown when the field gets focus
          _showFinancialYearDropdown(financialYears);
        }
      },
      child: GestureDetector(
        onTap: () {
          // Trigger the dropdown when user taps on the field
          _showFinancialYearDropdown(financialYears);
        },
        child: Container(
          height: height / 15.2.h, // Adjusted for better height
          width: width / 1.09.w, // Adjusted for better width
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: Colors.grey.shade500,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w), // Adjust padding for a neat look
            child: Align(
              alignment: Alignment.center, // Center the text vertically and horizontally
              child: TextFormField(
                controller: controller,
                focusNode: _focusNode,
                style: GoogleFonts.dmSans(
                  textStyle: TextStyle(
                    fontSize: 16.sp, // Adjust font size for better readability
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero, // No left padding for better alignment
                  hintText: "   Financial Year", // Placeholder text
                  hintStyle: GoogleFonts.sora(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  border: InputBorder.none, // Remove borders for cleaner look
                  isDense: true, // Make the field compact
                ),
                readOnly: true, // Makes the field read-only, so users can only select the dropdown
              ),
            ),
          ),
        ),
      ),
    );
  }

// Function to show the financial year dropdown
  void _showFinancialYearDropdown(List<String> financialYears) async {
    String? selectedYear = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Financial Year", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Container(
            width: 300, // Set a fixed width for the dropdown
            height: 250, // Set a fixed height for the dropdown container
            child: DropdownButton<String>(
              value: financialYearController.text.isEmpty ? null : financialYearController.text,
              isExpanded: true, // Makes the dropdown take up all available width
              onChanged: (String? newValue) {
                // Update the controller when a value is selected
                financialYearController.text = newValue!;
                Navigator.pop(context, newValue); // Close the dialog and return the selected value
              },
              items: financialYears.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    // If a financial year was selected, update the field value
    if (selectedYear != null) {
      setState(() {
        financialYearController.text = selectedYear; // Set the selected financial year to the controller
      });
    }
  }



  // Update your _buildTextField method
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    bool isDateField = false,
  }) {
    return Container(
      height: height / 15.2.h,
      width: width / 1.09.w,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.grey.shade500),
      ),
      child: TextFormField(
        textAlign: TextAlign.start,
        style: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
        controller: controller,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 10.w),
          border: InputBorder.none,
          hintText: hintText,
          prefixIcon: icon != null ? Icon(icon) : null,
        ),
        readOnly: isDateField,
        onTap: isDateField ? () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            controller.text = DateFormat('yyyy-MM-dd').format(date);
            // Update GetX controller if this is a date field
                  if (controller == _lastVisitedDateController) {
                    this.controller.lastVisitedDate.value = controller.text;
                  } else if (controller == _asDateController) {
                    this.controller.asDate.value = controller.text;
                  } else if (controller == _vsDateController) {
                    this.controller.tsDate.value = controller.text;
                  }
                }
        } : null,
        onChanged: (value) {
          // Update GetX controller based on which text field changed
          if (controller == Nameoftheworkr) {
            this.controller.workName.value = value;
          } else if (controller == initalamount) {
            this.controller.initialAmount.value = value;
          } else if (controller == depositamount) {
            this.controller.depositAmount.value = value;
          }else if (controller == financialYearController) {
            this.controller.financialYear.value = value;
          }
        },
      ),
    );
  }
}


class ProjectFormController extends GetxController {

  void updateWorkName(String value) {
    workName.value = value;
    print("Updated work name to: $value"); // For debugging
  }
  // Observable variables
  var workName = ''.obs;
  var workType = Rxn<String>();
  var schemaName = Rxn<String>();
  var schemaGroupName = Rxn<String>();
  var workGroupName = Rxn<String>();
  var agencyName = Rxn<String>();
  var levelName = Rxn<String>();
  var financialYear = ''.obs;
  var districtName = Rxn<String>();
  var blockName = Rxn<String>();
  var villageName = Rxn<String>();
  var status = Rxn<String>();
  var initialAmount = ''.obs;
  var depositAmount = ''.obs;
  var lastVisitedDate = ''.obs;
  var asDate = ''.obs;
  var tsDate = ''.obs;
  var remarks = ''.obs;
}