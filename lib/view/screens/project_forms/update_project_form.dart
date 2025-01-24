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

class UpdateProjectForm extends StatefulWidget {
  const UpdateProjectForm({super.key,    required this.projectName,});
  final String projectName;


  @override
  State<UpdateProjectForm> createState() => _UpdateProjectFormState();
}

class _UpdateProjectFormState extends State<UpdateProjectForm>  with AutomaticKeepAliveClientMixin  {
  late double height;
  late double width;
  bool isLoading = true;
  Map<String, dynamic> projectDetails = {};
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




 /// Fetch project details from the API
  Future<void> _fetchProjectData() async {
    try {
      print('Fetching project data for: ${widget.projectName}');
      final response = await http.get(
        Uri.parse('$apiUrl/Project Form/${Uri.encodeComponent(widget.projectName)}'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Check if the response contains data
        if (responseData.containsKey('data') && responseData['data'] != null) {
          final projectInfo = responseData['data'];

          setState(() {
            projectDetails = projectInfo;
            // Safely set text controller values with null checks
            Nameoftheworkr.text = projectInfo['name']?.toString() ?? '';
            selectedWorkType = projectInfo['work_type']?.toString() ?? '';
            selectedSchema = projectInfo['scheme_name']?.toString() ?? '';
            selectedSchemaGroupName = projectInfo['scheme_group']?.toString() ?? '';
            selectedWorkGroupName = projectInfo['work_group']?.toString() ?? '';
            financialYearController.text = projectInfo['financial_year']?.toString() ?? '';
            selectedAgencyName = projectInfo['agency_name']?.toString() ?? '';
            selectedLevelName = projectInfo['level']?.toString() ?? '';
            selectedBlockName = projectInfo['block']?.toString() ?? '';
            selectedVillageName = projectInfo['village']?.toString() ?? '';
            selectedDistrictName = projectInfo['district']?.toString() ?? '';
            selectedStatus = projectInfo['current_stage']?.toString() ?? '';
            initalamount.text = projectInfo['estimate_amount']?.toString() ?? '';
            depositamount.text = projectInfo['deposite_amount']?.toString() ?? '';
            _lastVisitedDateController.text = projectInfo['work_order_date']?.toString() ?? '';
            _asDateController.text = projectInfo['as_date']?.toString() ?? '';
            _vsDateController.text = projectInfo['project_duration']?.toString() ?? '';
            remarksController.text = projectInfo['remarks']?.toString() ?? '';
            isLoading = false;
          });

          print('State updated successfully with project data');
        } else {
          throw Exception('No data found in response');
        }
      } else {
        throw Exception('Failed to load project details: ${response.statusCode}');
      }
    } catch (error) {
      print('Error in _fetchProjectData: $error');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching project details: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // Function to call API to fetch the project details
  Future<Map<String, dynamic>> fetchProjectDetails(String projectName) async {
    try {
      final encodedProjectName = Uri.encodeComponent(projectName);
      print('Encoded project name: $encodedProjectName'); // Debug: Log encoded name
      print('API URL: $apiUrl/Project Form/$encodedProjectName'); // Debug: Log URL

      final response = await http.get(
        Uri.parse('$apiUrl/Project Form/$encodedProjectName'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
        },
      );

      print('Response status code: ${response.statusCode}'); // Debug: Log status code
      print('Response body: ${response.body}'); // Debug: Log response body

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load project details: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in fetchProjectDetails: $e'); // Debug: Log errors
      throw Exception('Error fetching project details: $e');
    }
  }

  /// Post method for Project Form //
  Future<void> MobileDocument(BuildContext context) async {
    try {
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
        'deposit_amount': depositamount.text,
        'work_order_date': _vsDateController.text,
        'as_date': _asDateController.text,
        'project_duration': _lastVisitedDateController.text,
        'remarks': remarksController.text,
      };

      final url = '$apiUrl/Project Form/${Uri.encodeComponent(widget.projectName)}';
      final response = await ioClient.put(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(data)
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Get.snackbar(
            "Success",
            "Project updated successfully",
            colorText: Colors.white,
            backgroundColor: Colors.green,
            snackPosition: SnackPosition.BOTTOM,
          );
          // Navigate back to dashboard after successful update
          Get.off(() => const Dashboard());
        }
      } else {
        throw Exception('Failed to update project: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          "Error",
          "Failed to update project: $e",
          colorText: Colors.white,
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchProjectData();
    fetchProjectDetails;
    print(Nameoftheworkr.text);
    print(financialYearController.text);
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
    super.build(context);
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
          text: "Update Project Form",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
      ),
      body: SizedBox(
        width: width.w,
        child: SingleChildScrollView(
          // scrollDirection: Axis.vertical,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                        child: Text("  Name of the work :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
                  _buildTextField(
                    controller: Nameoftheworkr,
                    hintText: "   Name of the work",
                    icon: Icons.drive_file_rename_outline,
              
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Work Type :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
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
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Scheme Name :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
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
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Scheme Group:",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
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
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Work Group :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
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
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Agency Name :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
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
                  SizedBox(height: 30.h,),
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Level :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
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
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Finanaical Year :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
                  _buildFinancialYearDropdown(
                      controller: financialYearController
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Districts :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
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
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Block :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
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
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Village :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
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
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Status :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
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
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Estimate Amount :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
                  _buildTextField(
                    controller: initalamount,
                    hintText: "   Estimate Amount",
                    icon: Icons.currency_rupee,
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Deposit Amount :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
                  _buildTextField(
                    controller: depositamount,
                    hintText: "   Deposit Amount",
                    icon: Icons.currency_rupee,
                  ),
                  // SizedBox(height: 30.h),
                  // _buildTextField(
                  //   hintText: "   Last Visited Date",
                  //   icon: Icons.date_range,
                  //   controller: _lastVisitedDateController,
                  //   isDateField: true,
                  // ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  As Date :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
                  _buildTextField(
                    hintText: "   As Date",
                    icon: Icons.date_range,
                    controller: _asDateController,
                    isDateField: true,
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Work Order Date :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
                  _buildTextField(
                    hintText: "   work Order Date",
                    icon: Icons.date_range,
                    controller: _vsDateController,
                    isDateField: true,
                  ),
                  SizedBox(height: 30.h,),
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Project Duration:",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
                  _buildTextField(
                    hintText: "   Project Duration",
                    icon: Icons.date_range,
                    controller: _lastVisitedDateController,
                    isDateField: true,
                  ),
                  SizedBox(height: 30.h,),
                  Padding(
                    padding:  EdgeInsets.only(left: 12.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text("  Remarks :",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15,fontWeight: FontWeight.w500,color: Colors.black)),)),
                  ),
                  SizedBox(height: 9.5.h,),
                  _buildTextField(
                    controller: remarksController,
                    hintText: "   Remarks",
                    icon: Icons.remember_me,
                  ),
                  SizedBox(height: 10.h),
                  // Button for generating and previewing PDF
                  GestureDetector(
                    onTap: () async {
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
        ),
      ),
    );
  }

  // Form Validation Function
  bool validateMandatoryFields() {
    if (Nameoftheworkr.text.isEmpty) return false;
    return true;

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

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

