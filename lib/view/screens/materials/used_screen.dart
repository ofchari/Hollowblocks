import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../universal_key_api/api_url.dart';
import '../../widgets/subhead.dart';
import '../../widgets/text.dart';
import '../tabs_pages.dart';
import 'materials_add.dart';
import 'package:http/http.dart'as http;

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
  double fetchedQty = 0.0; // Default value

  @override
  void initState() {
    super.initState();
    print("Project Name in Used: ${widget.projectName}"); // Debugging
    print("Project work  in Purchased: ${widget.work}"); // Debugging
    materialController = TextEditingController(
        text: widget.material?['material_name'] ?? ''
    );
    quantityController = TextEditingController();
    fetchMaterialStock();
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
    final result = await Get.to(() => MaterialsAdd(
      routeType: 'used',
      projectName: widget.projectName,
      work: widget.work,
    ));

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        selectedMaterial = result;
        materialController.text = result['material_name'] ?? '';
        print("Selected Material: $selectedMaterial");
      });

      print("Selected Material: $selectedMaterial");

      // Fetch stock for selected material
      fetchMaterialStock();  // Now this will only happen after selecting material
    }
  }

               /// Api's method for validation to post the data in used ///
  Future<double> fetchMaterialStock() async {
    final String materialName = selectedMaterial?['material_name'] ?? '';
    print("Fetching stock for material: $materialName");

    final String url =
        "https://vetri.regenterp.com/api/method/regent.sales.client.get_mobile_stock_material?pname=${widget.projectName}&material=${materialController.text.trim()}";

    print("API Request URL: $url");
    print("Material Name Passed: $materialName");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'token f1178cbff3f9a07:f1d2a24b5a005b7',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("API Response: ${response.body}");
        print("Response Status Code: ${response.statusCode}");

        if (data.containsKey("message") &&
            data["message"] is List &&
            data["message"].isNotEmpty) {
          final double qty = data["message"][0]["qty"]?.toDouble() ?? 0.0;
          setState(() {
            fetchedQty = qty; // Store the fetched quantity
          });
          return qty;
        }
      } else {
        print("Failed to fetch stock data. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching material stock: $e");
    }

    return 0.0; // Return 0 if data is not found or an error occurs
  }


              /// Post method for material Used ///
  Future<void> MobileDocument(BuildContext context) async {
    // Validate quantity against fetchedQty
    final enteredQuantity = double.tryParse(quantityController.text.trim()) ?? 0.0;

    if (enteredQuantity > fetchedQty) {
      Get.snackbar(
        "Error",
        "Entered quantity exceeds available stock ($fetchedQty)",
        colorText: Colors.white,
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
      return; // Stop further execution
    }

    // Proceed with the rest of the logic if validation passes
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastProjectName', widget.projectName);

    HttpClient client = HttpClient();
    client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

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
      setState(() {
        widget.projectName = lastProjectName;
      });
    }

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    try {
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

        Get.off(
              () => TabsPages(
            projectName: widget.projectName,
            initialTabIndex: 3,
            work: widget.work,
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
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: () {
                // Fetch material stock before submitting
                fetchMaterialStock().then((_) {
                  // Call MobileDocument after fetching stock
                  MobileDocument(context);
                });
              },
              child: MaterialButton(
                onPressed: () {
                  MobileDocument(context);
                },
                child: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType keyboardType) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(text: label, color: Colors.black, weight: FontWeight.w500,),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 12.sp),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
