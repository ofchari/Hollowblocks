import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/io_client.dart';
import 'package:vetri_hollowblock/view/universal_key_api/api_url.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';
import '../../widgets/subhead.dart';

class UpdateParty extends StatefulWidget {
  const UpdateParty({super.key});

  @override
  State<UpdateParty> createState() => _UpdatePartyState();
}

class _UpdatePartyState extends State<UpdateParty> {
  late double height;
  late double width;
  bool isLoading = true; // Track loading state
  List<dynamic> partys = []; // Store API data

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final partytypeController = TextEditingController();
  final partyidController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchParty(); // Fetch employees when screen loads
  }

  /// Fetch Employee Data from API
  Future<void> _fetchParty() async {
    final String url = "$apiUrl/Party?fields=[%22name%22,%22party_name%22,%22phone_no%22,%22party_type%22,%22party_id%22]";
    final String token = apiKey; // Replace with actual token

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "token $token"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          partys = data['data']; // Extract employee list
          isLoading = false;
        });
        print(response.body);
      } else {
        throw Exception("Failed to load employees");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }
  /// Post Api method for Update Employees //
  Future<void> updateMaterial(BuildContext context, String name) async {
    HttpClient client = HttpClient();
    client.badCertificateCallback =
    ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    final data = {
      'party_name': nameController.text,
      'phone_no': phoneController.text,
      'party_type': partytypeController.text,
      'party_id': partyidController.text,
    };

    final url = '$apiUrl/Party/$name';
    final body = jsonEncode(data);
    print(data);

    try {
      final response =
      await ioClient.put(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        Get.snackbar(
          "Success",
          "Party Master Updated Successfully",
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );
        _fetchParty(); // Refresh the employee list
      } else {
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
          return const Center(child: Text("Please make sure your device is in portrait view"));
        }
      },
    );
  }

  Widget _smallBuildLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 80.h,
        centerTitle: true,
        title: Subhead(
          text: "Update Party",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loader while fetching data
          : partys.isEmpty
          ? Center(child: Text("No employees found", style: TextStyle(fontSize: 18.sp)))
          : Padding(
        padding: EdgeInsets.all(10.w),
        child: ListView.builder(
          itemCount: partys.length,
          itemBuilder: (context, index) {
            final employee = partys[index];
            return _buildEmployeeCard(employee);
          },
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> employee) {
    // Pre-fill fields with selected employee data
    nameController.text = employee["party_name"];
    phoneController.text = employee["phone_no"];
    partytypeController.text = employee["party_type"];
    partyidController.text = employee["party_id"];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)), // Smooth rounded corners
          title: MyText(text: "Edit Employee", color: Colors.black54, weight: FontWeight.w500),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameController, "Name", Icons.person),
                _buildTextField(phoneController, "Phone", Icons.phone),
                _buildTextField(partytypeController, "Party Type", Icons.park_outlined),
                _buildTextField(partyidController, "Party Id", Icons.important_devices),

              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.red, fontSize: 14.sp)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_validateFields()) {
                  updateMaterial(context, employee["name"]); // Pass employee ID
                  Navigator.pop(context); // Close dialog after updating
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text("Save", style: TextStyle(fontSize: 14.sp, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Custom reusable text field with icon
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, [TextInputType keyboardType = TextInputType.text]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500)),
          prefixIcon: Icon(icon, color: Colors.purple),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.purple, width: 2),
            borderRadius: BorderRadius.circular(10.r),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 15.w),
        ),
      ),
    );
  }

  /// Validate fields before submission
  bool _validateFields() {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        partytypeController.text.isEmpty ||
        partyidController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill in all fields",
        colorText: Colors.white,
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    return true;
  }


  /// Widget to display each employee in a styled, interactive card
  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    return Card(
      elevation: 6, // Professional shadow effect
      margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r), // Softer rounded corners
      ),
      child: InkWell(
        onTap: () => _showEditDialog(employee), // Tap anywhere to edit
        borderRadius: BorderRadius.circular(15.r),
        splashColor: Colors.purple.withOpacity(0.2), // Subtle tap effect
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensures spacing
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(Icons.person, "Name", employee["party_name"], true),
                    _infoRow(Icons.location_on, "Phone", employee["phone_no"]),
                    _infoRow(Icons.location_city, "Party Type", employee["party_type"]),
                    _infoRow(Icons.phone, "Party Id", employee["party_id"]),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showEditDialog(employee),
                icon: Icon(Icons.edit, color: Colors.red, size: 23),
                tooltip: "Edit Employee",
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// Improved row widget with enhanced spacing and text alignment
  Widget _infoRow(IconData icon, String label, String value, [bool isBold = false]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: 22.sp),
          SizedBox(width: 10.w),
          MyText(text: label, color: Colors.black, weight: FontWeight.w500),
          SizedBox(width: 8.w),
          Expanded(
              child: MyText(text: value, color: Colors.black54, weight: FontWeight.w500)
          ),
        ],
      ),
    );
  }

}
