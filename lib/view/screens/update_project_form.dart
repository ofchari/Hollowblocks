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
//
// class UpdateProjectForm extends StatefulWidget {
//   const UpdateProjectForm({super.key,    required this.projectName,});
//   final String projectName;
//
//   @override
//   State<UpdateProjectForm> createState() => _UpdateProjectFormState();
// }
//
// class _UpdateProjectFormState extends State<UpdateProjectForm> {
//   late double height;
//   late double width;
//   bool isLoading = true;
//   Map<String, dynamic> projectDetails = {};
//   String? selectedWorkType;
//   String? selectedSchema;
//   String? selectedSchemaGroupName;
//   String? selectedWorkGroupName;
//   String? selectedAgencyName;
//   String? selectedDistrictName;
//   String? selectedBlockName;
//   String? selectedVillageName;
//   String? selectedStatus;
//
//   // Text controllers for date fields
//   final TextEditingController Nameoftheworkr = TextEditingController();
//   final TextEditingController Financial = TextEditingController();
//   final TextEditingController cuurentstage = TextEditingController();
//   final TextEditingController initalamount = TextEditingController();
//   final TextEditingController _lastVisitedDateController = TextEditingController();
//   final TextEditingController _asDateController = TextEditingController();
//   final TextEditingController _vsDateController = TextEditingController();
//
//
//
//
//   // Fetch project details from the API
//   Future<void> _fetchProjectData() async {
//     try {
//       final projectData = await fetchProjectDetails(widget.projectName);
//       setState(() {
//         projectDetails = projectData;
//         Nameoftheworkr.text = projectData['name'] ?? '';
//         selectedWorkType = projectData['work_type'] ?? '';
//         selectedSchema = projectData['scheme_name'] ?? '';
//         selectedSchemaGroupName = projectData['scheme_group'] ?? '';
//         selectedWorkGroupName = projectData['work_group'] ?? '';
//         Financial.text = projectData['financial_year'] ?? '';
//         selectedAgencyName = projectData['agency_name'] ?? '';
//         selectedBlockName = projectData['block'] ?? '';
//         selectedVillageName = projectData['village'] ?? '';
//         selectedDistrictName = projectData['district'] ?? '';
//         selectedStatus = projectData['current_stage'] ?? '';
//         initalamount.text = projectData['initial_amount'] ?? '';
//         _lastVisitedDateController.text = projectData['last_visited_date'] ?? '';
//         _asDateController.text = projectData['as_date'] ?? '';
//         _vsDateController.text = projectData['vs_date'] ?? '';
//         isLoading = false;
//       });
//     } catch (error) {
//       setState(() {
//         isLoading = false;
//       });
//       // Handle error (show a snackbar or error message)
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching project details')));
//     }
//   }
//
//   // Function to call API to fetch the project details
//   Future<Map<String, dynamic>> fetchProjectDetails(String projectName) async {
//     try {
//       final encodedProjectName = Uri.encodeComponent(projectName);
//       final response = await http.get(
//         Uri.parse('$apiUrl/Project Form/$encodedProjectName'),  // Make sure your API URL is correctly configured
//         headers: {
//           'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}', // Use correct API key
//         },
//       );
//
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       } else {
//         throw Exception('Failed to load project details');
//       }
//     } catch (e) {
//       throw Exception('Error fetching project details: $e');
//     }
//   }
//
//
//   /// PDF Generate logic //
//   Future<File> generateProfessionalPdf() async {
//     final pdf = pw.Document();
//
//     // Use default font or system font
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: pw.EdgeInsets.all(32),
//         build: (context) => [
//           // Header
//           pw.Header(
//             level: 0,
//             child: pw.Row(
//               mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//               children: [
//                 pw.Text('Project Report',
//                     style: pw.TextStyle(
//                         fontSize: 24, fontWeight: pw.FontWeight.bold)),
//                 pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
//                     style: pw.TextStyle(fontSize: 12)),
//               ],
//             ),
//           ),
//
//           // Logo and Title
//           pw.Container(
//             alignment: pw.Alignment.center,
//             margin: pw.EdgeInsets.symmetric(vertical: 20),
//             child: pw.Text('Vetri Company Details',
//                 style: pw.TextStyle(fontSize: 20)),
//           ),
//
//           // Table for Data
//           pw.Table.fromTextArray(
//             headers: ['Field', 'Value'],
//             data: [
//               ['Name of Work', Nameoftheworkr.text],
//               ['Work Type', selectedWorkType ?? ''],
//               ['Scheme Name', selectedSchema ?? ''],
//               ['Scheme Group Name', selectedSchemaGroupName ?? ''],
//               ['Work Group Name', selectedWorkGroupName ?? ''],
//               ['Agency Name', selectedAgencyName ?? ''],
//               ['Financial Year', Financial.text],
//               ['District', selectedDistrictName ?? ''],
//               ['Block', selectedBlockName ?? ''],
//               ['Village', selectedVillageName ?? ''],
//               ['Current Stage', selectedStatus ?? ''],
//               ['Initial Amount', initalamount.text],
//               ['Last Visited Date', _lastVisitedDateController.text],
//               ['As Date', _asDateController.text],
//               ['Ts Date', _vsDateController.text],
//
//             ],
//             border: pw.TableBorder.all(),
//             cellAlignment: pw.Alignment.centerLeft,
//             headerStyle: pw.TextStyle(
//                 fontSize: 12, fontWeight: pw.FontWeight.bold),
//             cellStyle: pw.TextStyle(fontSize: 10),
//           ),
//
//           // Footer
//           pw.Container(
//             alignment: pw.Alignment.center,
//             margin: pw.EdgeInsets.only(top: 50),
//             child: pw.Text(
//               'Thank you for choosing our service!',
//               style: pw.TextStyle(
//                   fontSize: 12, fontStyle: pw.FontStyle.italic),
//             ),
//           ),
//         ],
//         footer: (context) => pw.Container(
//           alignment: pw.Alignment.centerRight,
//           margin: pw.EdgeInsets.only(top: 1 * PdfPageFormat.cm),
//           child: pw.Text(
//             'Page ${context.pageNumber} of ${context.pagesCount}',
//             style: pw.TextStyle(fontSize: 12),
//           ),
//         ),
//       ),
//     );
//
//     final output = await getTemporaryDirectory();
//     final file = File("${output.path}/professional_project_report.pdf");
//     await file.writeAsBytes(await pdf.save());
//     return file;
//   }
//   /// Post method for Project Form //
//   Future<void> MobileDocument(BuildContext context) async {
//     HttpClient client = HttpClient();
//     client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
//     IOClient ioClient = IOClient(client);
//
//     final headers = {
//       'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
//       'Content-Type': 'application/json',
//     };
//
//     final data = {
//       'doctype': 'Project Form',
//       'work': Nameoftheworkr.text,
//       'work_type': selectedWorkType,
//       'scheme_name': selectedSchema,
//       'scheme_group': selectedSchemaGroupName,
//       'work_group': selectedWorkGroupName,
//       'agency_name': selectedAgencyName,
//       'financial_year': Financial.text,
//       'district': selectedDistrictName,
//       'block': selectedBlockName,
//       'village': selectedVillageName,
//       'current_stage': selectedStatus,
//       'initial_amount': initalamount.text,
//       'last_visited_date': _lastVisitedDateController.text,
//       'as_date': _asDateController.text,
//       'vs_date': _vsDateController.text,
//
//     };
//
//     final url = '$apiUrl/Project Form'; // Replace with your actual API URL
//     final body = jsonEncode(data);
//     print(data);
//
//     try {
//       // Use Uri.parse() to convert the string URL into a Uri object
//       final response = await ioClient.put(Uri.parse(url), headers: headers, body: body);
//
//       if (response.statusCode == 200) {
//         Get.snackbar(
//           "Project Form",
//           "Document Posted Successfully",
//           colorText: Colors.white,
//           backgroundColor: Colors.green,
//           snackPosition: SnackPosition.BOTTOM,
//         );
//         Navigator.of(context).pop(Nameoftheworkr.text); // Return project name to Dashboard
//       }
//       else {
//         String message = 'Request failed with status: ${response.statusCode}';
//         if (response.statusCode == 417) {
//           final serverMessages = json.decode(response.body)['_server_messages'];
//           message = serverMessages ?? message;
//         }
//         showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: Text(response.statusCode == 417 ? 'Message' : 'Error'),
//             content: Text(message),
//             actions: [
//               ElevatedButton(
//                 child: Text('OK'),
//                 onPressed: () => Navigator.of(context).pop(),
//               ),
//             ],
//           ),
//         );
//       }
//     } catch (e) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text('Error'),
//           content: Text('An error occurred: $e'),
//           actions: [
//             ElevatedButton(
//               child: Text('OK'),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//           ],
//         ),
//       );
//     }
//   }
//
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     print(Nameoftheworkr.text);
//     print(Financial.text);
//     print(cuurentstage.text);
//     print(initalamount.text);
//   }
//
//   @override
//   void dispose() {
//     _lastVisitedDateController.dispose();
//     _asDateController.dispose();
//     _vsDateController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Define Sizes //
//     var size = MediaQuery.of(context).size;
//     height = size.height.h;
//     width = size.width.w;
//
//     return LayoutBuilder(
//       builder: (BuildContext context, BoxConstraints constraints) {
//         height = constraints.maxHeight;
//         width = constraints.maxWidth;
//         if (width <= 450) {
//           return _smallBuildLayout();
//         } else {
//           return Text("Please make sure your device is in portrait view");
//         }
//       },
//     );
//   }
//
//   // Your existing layout and form fields remain the same
//   Widget _smallBuildLayout() {
//     return Scaffold(
//       backgroundColor: const Color(0xfff1f2f4),
//       appBar: AppBar(
//         backgroundColor: const Color(0xfff1f2f4),
//         toolbarHeight: 80.h,
//         centerTitle: true,
//         title: Subhead(
//           text: "Update Project Form",
//           color: Colors.black,
//           weight: FontWeight.w500,
//         ),
//       ),
//       body: SizedBox(
//         width: width.w,
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               SizedBox(height: 10.h),
//               _buildTextField(
//                 controller: Nameoftheworkr,
//                 hintText: "   Name of the work",
//                 icon: Icons.drive_file_rename_outline,
//
//               ),
//               SizedBox(height: 30.h),
//               _buildDropdownField(
//                 apiUrl: "$apiUrl/Work%20Type",
//                 hintText: "   Work Type",
//                 selectedValue: selectedWorkType,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedWorkType = value;
//                     print(selectedWorkType);
//                   });
//
//                 }, hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
//                 onAddNewRoute: () {
//                   Get.toNamed('/worktype'); // Use GetX to navigate to the "Add Work Type" page
//                 },
//               ),
//               SizedBox(height: 30.h),
//               _buildDropdownField(
//                 apiUrl: "$apiUrl/Scheme",
//                 hintText: "   Scheme Name",
//
//                 selectedValue: selectedSchema,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedSchema = value;
//                     print(selectedSchema);
//                   });
//                 },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
//                 onAddNewRoute: () {
//                   Get.toNamed('/scheme'); // Use GetX to navigate to the "Add Work Type" page
//                 },
//               ),
//               SizedBox(height: 30.h),
//               _buildDropdownField(
//                 apiUrl: "$apiUrl/Scheme Group",
//                 hintText: "   Scheme Group",
//                 selectedValue: selectedSchemaGroupName,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedSchemaGroupName = value;
//                     print(selectedSchemaGroupName);
//                   });
//                 },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
//                 onAddNewRoute: () {
//                   Get.toNamed('/schemegroup'); // Use GetX to navigate to the "Add Work Type" page
//                 },
//               ),
//               SizedBox(height: 30.h),
//               _buildDropdownField(
//                 apiUrl: "$apiUrl/Work Group",
//                 hintText: "   Work Group",
//                 selectedValue: selectedWorkGroupName,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedWorkGroupName = value;
//                     print(selectedWorkGroupName);
//                   });
//                 },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
//                 onAddNewRoute: () {
//                   Get.toNamed('/workgroup'); // Use GetX to navigate to the "Add Work Type" page
//                 },
//               ),
//               SizedBox(height: 30.h),
//               _buildDropdownField(
//                 apiUrl: "$apiUrl/Agency",
//                 hintText: "   Agency Name",
//                 selectedValue: selectedAgencyName,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedAgencyName = value;
//                     print(selectedAgencyName);
//                   });
//                 },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
//                 onAddNewRoute: () {
//                   Get.toNamed('/agency'); // Use GetX to navigate to the "Add Work Type" page
//                 },
//               ),
//               SizedBox(height: 30.h),
//               _buildTextField(
//                 hintText: "   Financial year",
//                 icon: Icons.date_range,
//                 controller: Financial,
//                 isDateField: true,
//               ),
//               SizedBox(height: 30.h),
//               _buildDropdownField(
//                 apiUrl: "$apiUrl/District",
//                 hintText: "   District",
//                 selectedValue: selectedDistrictName,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedDistrictName = value;
//                     print(selectedDistrictName);
//                   });
//                 },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
//                 onAddNewRoute: () {
//                   Get.toNamed('/district'); // Use GetX to navigate to the "Add Work Type" page
//                 },
//               ),
//               SizedBox(height: 30.h),
//               _buildDropdownField(
//                 apiUrl: "$apiUrl/Block",
//                 hintText: "   Block",
//                 selectedValue: selectedBlockName,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedBlockName = value;
//                     print(selectedBlockName);
//                   });
//                 },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
//                 onAddNewRoute: () {
//                   Get.toNamed('/block'); // Use GetX to navigate to the "Add Work Type" page
//                 },
//               ),
//               SizedBox(height: 30.h),
//               _buildDropdownField(
//                 apiUrl: "$apiUrl/Village",
//                 hintText: "   Village",
//                 selectedValue: selectedVillageName,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedVillageName = value;
//                     print(selectedVillageName);
//                   });
//                 },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
//                 onAddNewRoute: () {
//                   Get.toNamed('/village'); // Use GetX to navigate to the "Add Work Type" page
//                 },
//               ),
//               SizedBox(height: 30.h),
//               _buildDropdownField(
//                 apiUrl: "$apiUrl/Construction Status",
//                 hintText: "   Status",
//                 selectedValue: selectedStatus,
//                 onChanged: (value) {
//                   setState(() {
//                     selectedStatus = value;
//                     print(selectedStatus);
//                   });
//                 },hintStyle: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
//                 onAddNewRoute: () {
//                   Get.toNamed('/status'); // Use GetX to navigate to the "Add Work Type" page
//                 },
//               ),
//               SizedBox(height: 30.h),
//               _buildTextField(
//                 controller: initalamount,
//                 hintText: "   Initial Amount",
//                 icon: Icons.monetization_on,
//               ),
//               SizedBox(height: 30.h),
//               _buildTextField(
//                 hintText: "   Last Visited Date",
//                 icon: Icons.date_range,
//                 controller: _lastVisitedDateController,
//                 isDateField: true,
//               ),
//               SizedBox(height: 30.h),
//               _buildTextField(
//                 hintText: "   As Date",
//                 icon: Icons.date_range,
//                 controller: _asDateController,
//                 isDateField: true,
//               ),
//               SizedBox(height: 30.h),
//               _buildTextField(
//                 hintText: "   Ts Date",
//                 icon: Icons.date_range,
//                 controller: _vsDateController,
//                 isDateField: true,
//               ),
//               SizedBox(height: 10.h),
//               // Button for generating and previewing PDF
//               GestureDetector(
//                 onTap: () async {
//                   if (Nameoftheworkr.text.isEmpty) {
//                     // Show error if the mandatory field is empty
//                     Get.snackbar(
//                       "Validation Error",
//                       "Name of Work is required.",
//                       colorText: Colors.white,
//                       backgroundColor: Colors.red,
//                       snackPosition: SnackPosition.BOTTOM,
//                     );
//                     return;
//                   }
//
//                   final pdfFile = await generateProfessionalPdf(); // Generate the PDF
//
//                   // Navigate to a new page to show the PDF preview and confirmation
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => PdfPreviewScreen(
//                         pdfFile: pdfFile,
//                         projectName: Nameoftheworkr.text,  // Pass the project name
//                         onConfirm: () {
//                           MobileDocument(context); // Post the form on confirmation
//                           Navigator.pop(context); // Close the PDF preview screen
//                         },
//                       ),
//                     ),
//                   ).then((projectName) {
//                     // Handle the returned project name if needed (for example, update the dashboard)
//                     if (projectName != null) {
//                       // Optionally, you can update the dashboard or perform other actions here
//                       Navigator.of(context).pop(projectName); // Return project name to the dashboard
//                     }
//                   });
//                 },
//                 child: Buttons(
//                   height: height / 20.h,
//                   width: width / 2.5.w,
//                   radius: BorderRadius.circular(10.r),
//                   color: Colors.blue,
//                   text: "Submit",
//                 ),
//               ),
//
//               SizedBox(height: 20.h),
//
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Form Validation Function
//   bool validateMandatoryFields() {
//     if (Nameoftheworkr.text.isEmpty) return false;
//     return true;
//
//   }
//
//
//   /// Dropdown field //
//   Widget _buildDropdownField({
//     required String apiUrl,
//     required String hintText,
//     required TextStyle hintStyle,
//     required String? selectedValue,
//     required Function(String?) onChanged,
//     required Function onAddNewRoute, // Pass the onAddNewRoute callback
//   }) {
//     return DropdownField(
//       apiUrl: apiUrl,
//       hintText: hintText,
//       hintStyle: hintStyle,
//       onChanged: onChanged,
//       selectedValue: selectedValue,
//       onAddNewRoute: onAddNewRoute, // Pass it to DropdownField
//     );
//   }
//
//
//
//   // Updated _buildTextField method
//   Widget _buildTextField({
//     required String hintText,
//     required IconData icon,
//     TextEditingController? controller,
//     bool isDateField = false, // Boolean flag to identify date fields
//   }) {
//     return Container(
//       height: height / 15.2.h,
//       width: width / 1.09.w,
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(6.r),
//         border: Border.all(
//           color: Colors.grey.shade500,
//         ),
//       ),
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
//         child: TextFormField(
//           controller: controller,
//           style: GoogleFonts.dmSans(
//             textStyle: TextStyle(
//               fontSize: 15.sp,
//               fontWeight: FontWeight.w500,
//               color: Colors.black,
//             ),
//           ),
//           decoration: InputDecoration(
//             contentPadding: EdgeInsets.only(left: 20.0),
//             prefixIconConstraints: BoxConstraints(
//                 minWidth: 24,minHeight: 24
//             ),
//             prefixIcon: Icon(icon, size: 16), // Icon size adjusted to 16
//             hintText: hintText,
//             hintStyle: GoogleFonts.sora(
//               fontSize: 14.sp,
//               fontWeight: FontWeight.w500,
//               color: Colors.black,
//             ),
//             border: InputBorder.none,
//           ),
//           onTap: isDateField
//               ? () async {
//             DateTime? pickedDate = await showDatePicker(
//               context: context,
//               initialDate: DateTime.now(),
//               firstDate: DateTime(2000),
//               lastDate: DateTime(2100),
//             );
//             if (pickedDate != null) {
//               controller?.text = DateFormat('yyyy-MM-dd').format(pickedDate);
//             }
//           }
//               : null,
//         ),
//       ),
//     );
//   }
// }
class UpdateProjectForm extends StatefulWidget {
  const UpdateProjectForm({super.key, required this.projectName});
  final String projectName;

  @override
  State<UpdateProjectForm> createState() => _UpdateProjectFormState();
}

class _UpdateProjectFormState extends State<UpdateProjectForm> {
  late double height;
  late double width;
  bool isLoading = true;
  Map<String, dynamic> projectDetails = {};
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

  @override
  void initState() {
    super.initState();
    _fetchProjectData();
  }

  // Fetch project details from the API
  Future<void> _fetchProjectData() async {
    try {
      final projectData = await fetchProjectDetails(widget.projectName);
      setState(() {
        projectDetails = projectData;
        Nameoftheworkr.text = projectData['name'] ?? '';
        selectedWorkType = projectData['work_type'] ?? '';
        selectedSchema = projectData['scheme_name'] ?? '';
        selectedSchemaGroupName = projectData['scheme_group'] ?? '';
        selectedWorkGroupName = projectData['work_group'] ?? '';
        Financial.text = projectData['financial_year'] ?? '';
        selectedAgencyName = projectData['agency_name'] ?? '';
        selectedBlockName = projectData['block'] ?? '';
        selectedVillageName = projectData['village'] ?? '';
        selectedDistrictName = projectData['district'] ?? '';
        selectedStatus = projectData['current_stage'] ?? '';
        initalamount.text = projectData['initial_amount'] ?? '';
        _lastVisitedDateController.text = projectData['last_visited_date'] ?? '';
        _asDateController.text = projectData['as_date'] ?? '';
        _vsDateController.text = projectData['vs_date'] ?? '';
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching project details')));
    }
  }

  // Function to call API to fetch the project details
  Future<Map<String, dynamic>> fetchProjectDetails(String projectName) async {
    try {
      final encodedProjectName = Uri.encodeComponent(projectName);
      final response = await http.get(
        Uri.parse('https://vetri.regenterp.com/api/resource/Project%20Form/$encodedProjectName'), // Make sure your API URL is correctly configured
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}', // Use correct API key
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load project details');
      }
    } catch (e) {
      throw Exception('Error fetching project details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Project Form"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: Nameoftheworkr,
                decoration: InputDecoration(labelText: 'Name of the Work'),
              ),
              DropdownButtonFormField<String>(
                value: selectedWorkType,
                items: ['WorkType1', 'WorkType2'] // Replace with actual options
                    .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e),
                ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedWorkType = newValue;
                  });
                },
                decoration: InputDecoration(labelText: 'Work Type'),
              ),
              TextFormField(
                controller: Financial,
                decoration: InputDecoration(labelText: 'Financial Year'),
              ),
              DropdownButtonFormField<String>(
                value: selectedSchema,
                items: ['Schema1', 'Schema2'] // Replace with actual options
                    .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e),
                ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedSchema = newValue;
                  });
                },
                decoration: InputDecoration(labelText: 'Scheme Name'),
              ),
              DropdownButtonFormField<String>(
                value: selectedSchemaGroupName,
                items: ['Group1', 'Group2'] // Replace with actual options
                    .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e),
                ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedSchemaGroupName = newValue;
                  });
                },
                decoration: InputDecoration(labelText: 'Scheme Group'),
              ),
              // Add other form fields here in a similar way
              TextFormField(
                controller: initalamount,
                decoration: InputDecoration(labelText: 'Initial Amount'),
              ),
              TextFormField(
                controller: _lastVisitedDateController,
                decoration: InputDecoration(labelText: 'Last Visited Date'),
              ),
              TextFormField(
                controller: _asDateController,
                decoration: InputDecoration(labelText: 'As Date'),
              ),
              TextFormField(
                controller: _vsDateController,
                decoration: InputDecoration(labelText: 'VS Date'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Save logic goes here
                },
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
