import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../universal_key_api/api_url.dart';
import '../../widgets/buttons.dart';
import '../../widgets/subhead.dart';
import '../../widgets/text.dart';
import '../tabs_pages.dart';
import 'materials_add.dart';

class UsedScreen extends StatefulWidget {
  final Map<String, dynamic>? material; // Add this parameter
  late  String projectName;
  late String work; //

   UsedScreen({
    super.key,
    this.material, // Make it optional in case you navigate directly to this screen
    required this.projectName,
    required this.work,
  });

  @override
  State<UsedScreen> createState() => _UsedScreenState();
}

class _UsedScreenState extends State<UsedScreen> {
  late double height;
  late double width;
  DateTime selectedDate = DateTime.now();
  late TextEditingController materialController;
  late TextEditingController quantityController;
  Map<String, dynamic>? selectedMaterial;

  @override
  void initState() {
    super.initState();
    print("Project Name in Used: ${widget.projectName}"); // Debugging
    print("Project work  in Purchased: ${widget.work}"); // Debugging
    materialController = TextEditingController(
        text: widget.material?['material_name'] ?? ''
    );
    quantityController = TextEditingController();
  }

  @override
  void dispose() {
    materialController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Add this method to handle material selection
  void _selectMaterial() async {
    final result = await Get.to(() => MaterialsAdd(routeType: 'used', projectName: widget.projectName, work: widget.work,));
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        selectedMaterial = result;
        materialController.text = result['material_name'] ?? '';
      });
    }
  }
           /// Post method for material Used //
  Future<void> MobileDocument(BuildContext context) async {
    // Store project name in local storage for persistence
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastProjectName', widget.projectName);

    HttpClient client = HttpClient();
    client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    // Check if project name is available
    if (widget.projectName.isEmpty) {
      final lastProjectName = prefs.getString('lastProjectName');
      if (lastProjectName == null) {
        Get.snackbar(
          "Error",
          "Project name is missing",
          colorText: Colors.white,
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      // Restore project name from storage
      setState(() {
        widget.projectName = lastProjectName;
      });
    }

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    try {
      // Validate required fields before making the request
      if (materialController.text.isEmpty || quantityController.text.isEmpty) {
        throw Exception('Please fill in all required fields');
      }

      final data = {
        'doctype': 'Material Used',
        'material': materialController.text,
        'quantity': quantityController.text,
        'project_form': widget.projectName,
        'name': '',
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
      };

      print('Sending material used request for project: ${widget.projectName}');
      print('Request payload: $data');

      final url = '$apiUrl/Material Used';
      final body = jsonEncode(data);

      final response = await ioClient.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Store successful material usage data locally
        final usageBox = await Hive.openBox('usedMaterialData');
        await usageBox.add({
          'material': materialController.text,
          'quantity': quantityController.text,
          'date': DateFormat('yyyy-MM-dd').format(selectedDate),
          'project_name': widget.projectName,
        });

        Get.snackbar(
          "Success",
          "Material Usage Posted Successfully",
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Navigate with preserved project name
        Get.off(
              () => TabsPages(
            projectName: widget.projectName,
            initialTabIndex: 3, work: widget.work,
          ),
          arguments: {
            'used': {
              'material': materialController.text,
              'quantity': quantityController.text,
              'date': DateFormat('yyyy-MM-dd').format(selectedDate),
              'project_name': widget.projectName,
            },
          },
        );
      } else {
        String errorMessage = 'Request failed with status: ${response.statusCode}';
        if (response.statusCode == 417) {
          final serverMessages = json.decode(response.body)['_server_messages'];
          errorMessage = serverMessages ?? errorMessage;
        }
        _showErrorDialog(context, errorMessage);
      }
    } catch (e) {
      print('Error in material usage: $e');
      _showErrorDialog(context, 'An error occurred: $e');
    } finally {
      ioClient.close();
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Error'),
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
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;

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
      backgroundColor: const Color(0xfff1f2f4),
      appBar: AppBar(
        backgroundColor: const Color(0xfff1f2f4),
        toolbarHeight: 80.h,
        centerTitle: true,
        title: Subhead(
          text: "Material Used",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
              onTap: () => _selectDate(context),
              child: MyText(
                text: DateFormat('dd-MM-yyyy').format(selectedDate),
                color: Colors.black,
                weight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SizedBox(
        width: width.w,
        child: Column(
          children: [
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: _selectMaterial,  // Use the new method here
              child: AbsorbPointer(  // This prevents the TextFormField from receiving taps
                child: _buildTextField("Material", materialController, TextInputType.text),
              ),
            ),
            SizedBox(height: 20.h,),
            _buildTextField("Quantity", quantityController, TextInputType.number),
            SizedBox(height: 20.h,),
            // GestureDetector(
            //   onTap: _selectMaterial,  // Use the same method for consistency
            //   child: Align(
            //     alignment: Alignment.centerRight,
            //     child: Padding(
            //       padding: const EdgeInsets.only(right: 15.0),
            //       child: MyText(
            //           text: selectedMaterial == null ? "+ Add Material" : "Change Material",
            //           color: Colors.blue,
            //           weight: FontWeight.w500),
            //     ),
            //   ),
            // ),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: (){
                MobileDocument(context);
                // Handle save logic here
                if (materialController.text.isNotEmpty && quantityController.text.isNotEmpty) {
                  // TODO: Implement your save logic
                  print('Material: ${materialController.text}');
                  print('Quantity: ${quantityController.text}');
                  print('Date: ${DateFormat('dd-MM-yyyy').format(selectedDate)}');
                }
              },
              child: Buttons(
                height: height / 20.h,
                width: width / 2.5.w,
                radius: BorderRadius.circular(10.r),
                color: Colors.blue,
                text: "Save",
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTextField(String label , TextEditingController controller, TextInputType type){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.0.w),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.dmSans(
            textStyle: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          suffixIcon: label == "Material" ? const Icon(Icons.arrow_drop_down_sharp, color: Colors.black) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Colors.grey),

          ),
        ),
      ),
    );
  }
}