import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart'as http;
import 'package:vetri_hollowblock/view/screens/project_forms/project_form_dropdown.dart';
import 'package:vetri_hollowblock/view/universal_key_api/api_url.dart';
import '../../widgets/buttons.dart';
import '../../widgets/subhead.dart';

class UpdateProjectForm extends StatefulWidget {
  const UpdateProjectForm({super.key, required this.projectName,});
  final String projectName;


  @override
  State<UpdateProjectForm> createState() => _UpdateProjectFormState();
}

class _UpdateProjectFormState extends State<UpdateProjectForm> with AutomaticKeepAliveClientMixin {
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

  // Text controllers for fields
  final TextEditingController Nameoftheworkr = TextEditingController();
  TextEditingController financialYearController = TextEditingController();
  final TextEditingController cuurentstage = TextEditingController();
  final TextEditingController initalamount = TextEditingController();
  final TextEditingController depositamount = TextEditingController();
  final TextEditingController _lastVisitedDateController = TextEditingController();
  final TextEditingController _asDateController = TextEditingController();
  final TextEditingController _vsDateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  // Edit mode flags
  bool _isFullEditMode = false;
  bool _isStatusEditMode = false;

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

        if (responseData.containsKey('data') && responseData['data'] != null) {
          final projectInfo = responseData['data'];

          setState(() {
            projectDetails = projectInfo;
            Nameoftheworkr.text = projectInfo['work']?.toString() ?? '';
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

             /// Post method for Project Form
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
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isFullEditMode = false;
          _isStatusEditMode = false;
        });
        if (mounted) {
          Get.snackbar(
            "Success",
            "Project updated successfully",
            colorText: Colors.white,
            backgroundColor: Colors.green,
            snackPosition: SnackPosition.BOTTOM,
          );
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
    super.initState();
    _fetchProjectData();
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

  Widget _smallBuildLayout() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        toolbarHeight: 80.h,
        centerTitle: true,
        title: Subhead(
          text: "Update Project Form",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
        actions: [
          IconButton(
            icon: Icon(_isFullEditMode ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isFullEditMode = !_isFullEditMode;
                if (_isFullEditMode) {
                  _isStatusEditMode = false; // Disable status edit mode when full edit mode is on
                }
              });
            },
          ),
        ],
      ),
      body: SizedBox(
        width: width.w,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Name of the work :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildTextField(
                    controller: Nameoftheworkr,
                    hintText: "   Name of the work",
                    icon: Icons.drive_file_rename_outline,
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Work Type :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildDropdownField(
                    apiUrl: "$apiUrl/Work%20Type",
                    hintText: "   Work Type",
                    selectedValue: selectedWorkType,
                    onChanged: _isFullEditMode
                        ? (value) {
                      setState(() {
                        selectedWorkType = value;
                      });
                    }
                        : null,
                    hintStyle: GoogleFonts.dmSans(
                      textStyle: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    onAddNewRoute: () {
                      Get.toNamed('/worktype');
                    },
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Scheme Name :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildDropdownField(
                    apiUrl: "$apiUrl/Scheme",
                    hintText: "   Scheme Name",
                    selectedValue: selectedSchema,
                    onChanged: _isFullEditMode
                        ? (value) {
                      setState(() {
                        selectedSchema = value;
                      });
                    }
                        : null,
                    hintStyle: GoogleFonts.dmSans(
                      textStyle: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    onAddNewRoute: () {
                      Get.toNamed('/scheme');
                    },
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Scheme Group:",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildDropdownField(
                    apiUrl: "$apiUrl/Scheme Group",
                    hintText: "   Scheme Group",
                    selectedValue: selectedSchemaGroupName,
                    onChanged: _isFullEditMode
                        ? (value) {
                      setState(() {
                        selectedSchemaGroupName = value;
                      });
                    }
                        : null,
                    hintStyle: GoogleFonts.dmSans(
                      textStyle: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    onAddNewRoute: () {
                      Get.toNamed('/schemegroup');
                    },
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Work Group :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildDropdownField(
                    apiUrl: "$apiUrl/Work Group",
                    hintText: "   Work Group",
                    selectedValue: selectedWorkGroupName,
                    onChanged: _isFullEditMode
                        ? (value) {
                      setState(() {
                        selectedWorkGroupName = value;
                      });
                    }
                        : null,
                    hintStyle: GoogleFonts.dmSans(
                      textStyle: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    onAddNewRoute: () {
                      Get.toNamed('/workgroup');
                    },
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Agency Name :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildDropdownField(
                    apiUrl: "$apiUrl/Agency",
                    hintText: "   Agency Name",
                    selectedValue: selectedAgencyName,
                    onChanged: _isFullEditMode
                        ? (value) {
                      setState(() {
                        selectedAgencyName = value;
                      });
                    }
                        : null,
                    hintStyle: GoogleFonts.dmSans(
                      textStyle: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    onAddNewRoute: () {
                      Get.toNamed('/agency');
                    },
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Level :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildDropdownField(
                    apiUrl: "$apiUrl/Level",
                    hintText: "   Level Name",
                    selectedValue: selectedLevelName,
                    onChanged: _isFullEditMode
                        ? (value) {
                      setState(() {
                        selectedLevelName = value;
                      });
                    }
                        : null,
                    hintStyle: GoogleFonts.dmSans(
                      textStyle: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    onAddNewRoute: () async {
                      final result = await Get.toNamed('/level');
                      return result;
                    },
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Financial Year :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildFinancialYearDropdown(controller: financialYearController),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Districts :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildDropdownField(
                    apiUrl: "$apiUrl/District",
                    hintText: "   District",
                    selectedValue: selectedDistrictName,
                    onChanged: _isFullEditMode
                        ? (value) {
                      setState(() {
                        selectedDistrictName = value;
                      });
                    }
                        : null,
                    hintStyle: GoogleFonts.dmSans(
                      textStyle: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    onAddNewRoute: () {
                      Get.toNamed('/district');
                    },
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Block :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildDropdownField(
                    apiUrl: "$apiUrl/Block",
                    hintText: "   Block",
                    selectedValue: selectedBlockName,
                    onChanged: _isFullEditMode
                        ? (value) {
                      setState(() {
                        selectedBlockName = value;
                      });
                    }
                        : null,
                    hintStyle: GoogleFonts.dmSans(
                      textStyle: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    onAddNewRoute: () {
                      Get.toNamed('/block');
                    },
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Village :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildDropdownField(
                    apiUrl: "$apiUrl/Village",
                    hintText: "   Village",
                    selectedValue: selectedVillageName,
                    onChanged: _isFullEditMode
                        ? (value) {
                      setState(() {
                        selectedVillageName = value;
                      });
                    }
                        : null,
                    hintStyle: GoogleFonts.dmSans(
                      textStyle: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    onAddNewRoute: () {
                      Get.toNamed('/village');
                    },
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Status :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      _buildDropdownField(
                        apiUrl: "$apiUrl/Construction Status",
                        hintText: "   Status",
                        selectedValue: selectedStatus,
                        onChanged: ( _isStatusEditMode)
                            ? (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        }
                            : null,
                        hintStyle: GoogleFonts.dmSans(
                          textStyle: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        onAddNewRoute: () {
                          Get.toNamed('/status');
                        },
                      ),
                      Positioned(
                        right: 10,
                        child: IconButton(
                          icon: Icon(
                            _isStatusEditMode ? Icons.check : Icons.edit,
                            color: _isStatusEditMode ? Colors.green : Colors.blue,
                          ),
                          onPressed: () {
                            setState(() {
                              _isStatusEditMode = !_isStatusEditMode;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Estimate Amount :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildTextField(
                    controller: initalamount,
                    hintText: "   Estimate Amount",
                    icon: Icons.currency_rupee,
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Deposit Amount :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildTextField(
                    controller: depositamount,
                    hintText: "   Deposit Amount",
                    icon: Icons.currency_rupee,
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  As Date :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildTextField(
                    hintText: "   As Date",
                    icon: Icons.date_range,
                    controller: _asDateController,
                    isDateField: true,
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Work Order Date :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildTextField(
                    hintText: "   Work Order Date",
                    icon: Icons.date_range,
                    controller: _vsDateController,
                    isDateField: true,
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Project Duration:",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildTextField(
                    hintText: "   Project Duration",
                    icon: Icons.date_range,
                    controller: _lastVisitedDateController,
                    isDateField: true,
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "  Remarks :",
                        style: GoogleFonts.outfit(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 9.5.h),
                  _buildTextField(
                    controller: remarksController,
                    hintText: "   Remarks",
                    icon: Icons.remember_me,
                  ),
                  SizedBox(height: 10.h),
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

  /// Financial dropdown
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

    FocusNode focusNode = FocusNode();

    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus && _isFullEditMode) {
          _showFinancialYearDropdown(financialYears);
        }
      },
      child: GestureDetector(
        onTap: _isFullEditMode
            ? () {
          _showFinancialYearDropdown(financialYears);
        }
            : null,
        child: Container(
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
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Align(
              alignment: Alignment.center,
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: GoogleFonts.dmSans(
                  textStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  hintText: "   Financial Year",
                  hintStyle: GoogleFonts.sora(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                readOnly: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFinancialYearDropdown(List<String> financialYears) async {
    String? selectedYear = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Financial Year", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 300,
            height: 250,
            child: DropdownButton<String>(
              value: financialYearController.text.isEmpty ? null : financialYearController.text,
              isExpanded: true,
              onChanged: (String? newValue) {
                financialYearController.text = newValue!;
                Navigator.pop(context, newValue);
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

    if (selectedYear != null) {
      setState(() {
        financialYearController.text = selectedYear;
      });
    }
  }

  /// Dropdown field
  Widget _buildDropdownField({
    required String apiUrl,
    required String hintText,
    required TextStyle hintStyle,
    required String? selectedValue,
    required Function(String?)? onChanged,
    required Function onAddNewRoute,
  }) {
    return DropdownField(
      apiUrl: apiUrl,
      hintText: hintText,
      hintStyle: hintStyle,
      onChanged: (value) => onChanged?.call(value),
      selectedValue: selectedValue,
      onAddNewRoute: onAddNewRoute,
    );
  }

  /// Text field
  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    TextEditingController? controller,
    bool isDateField = false,
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
      child: TextFormField(
        controller: controller,
        readOnly: !_isFullEditMode,
        style: GoogleFonts.dmSans(
          textStyle: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: _isFullEditMode ? Colors.black : Colors.grey.shade700,
          ),
        ),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.only(left: 20.0),
          prefixIconConstraints: BoxConstraints(minWidth: 24, minHeight: 24),
          prefixIcon: Icon(icon, size: 16),
          hintText: hintText,
          hintStyle: GoogleFonts.sora(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          border: InputBorder.none,
        ),
        onTap: isDateField && _isFullEditMode
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
    );
  }

  @override
  bool get wantKeepAlive => true;
}

