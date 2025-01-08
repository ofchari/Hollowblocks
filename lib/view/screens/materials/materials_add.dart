import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/io_client.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';
import 'package:http/http.dart' as http;
import '../../universal_key_api/api_url.dart';
import '../../widgets/subhead.dart';

class MaterialsAdd extends StatefulWidget {
  const MaterialsAdd({super.key});

  @override
  State<MaterialsAdd> createState() => _MaterialsAddState();
}

class _MaterialsAddState extends State<MaterialsAdd> {
  late double height;
  late double width;
  List<dynamic> materials = []; // List to hold fetched materials
  List<String> unitName = []; // List to hold unit names
  String? selectedUnit;
  List<String> gstPercent = []; // List to hold GST percentages
  String? selectedGst;
  bool isLoading = false;

       /// Textediting controllers
  final materialName = TextEditingController();
  final costCode = TextEditingController();
  final description = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchMaterials();
    fetchUnit();
    fetchGst();
  }

  /// Get API for materials
  Future<void> fetchMaterials() async {
    final String url = "$apiUrl/Material?fields=[%22material_name%22,%22unit%22,%22cost_code%22,%22gst_per%22,%22description%22]&limit_page_length=50000";
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          materials = data['data'];
        });
      } else {
        print("Failed to fetch materials. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching materials: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Get API for Unit
  Future<void> fetchUnit() async {
    final String url = "$apiUrl/Material%20Units?limit_page_length=50000";
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          unitName = List<String>.from(
            data['data'].map((unit) => unit['name']),
          );
        });
      } else {
        print("Failed to fetch units. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching units: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Get API for GST
  Future<void> fetchGst() async {
    final String url = "$apiUrl/GST?limit_page_length=50000";
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          gstPercent = List<String>.from(
            data['data'].map((gst) => gst['name']),
          );
        });
      } else {
        print("Failed to fetch GST. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching GST: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Post API for material
  Future<void> addMaterial(BuildContext context) async {
    HttpClient client = HttpClient();
    client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    final data = {
      'doctype': 'Material',
      'material_name': materialName.text,
      'unit': selectedUnit,
      'cost_code': costCode.text,
      'gst_per': selectedGst,
      'description': description.text,
    };

    final url = '$apiUrl/Material';
    final body = jsonEncode(data);
    try {
      final response = await ioClient.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        Get.snackbar(
          "Material added",
          "Successfully",
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );
        Navigator.of(context).pop();
        fetchMaterials();
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
          return const Text("Please make sure your device is in portrait view");
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
          text: "Material Library",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            color: Colors.black,
            onPressed: () => _showAddMaterialBottomSheet(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : materials.isEmpty
          ? SingleChildScrollView( // Added SingleChildScrollView
        physics: BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center the column
              children: [
                SizedBox(height: 10.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0.w),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "Search Material",
                      labelStyle: GoogleFonts.dmSans(
                        textStyle: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      suffixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                SizedBox(height: 20.h), // Added extra spacing for better alignment
                GestureDetector(
                  onTap: () => _showAddMaterialBottomSheet(context),
                  child: Container(
                    height: height / 15.h,
                    width: width / 2.5.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                    child: Center(
                      child: MyText(
                        text: "Add Material",
                        color: Colors.black,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
          : ListView.builder(
        itemCount: materials.length,
        itemBuilder: (context, index) {
          final material = materials[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: height / 10.h,
              width: width / 1.1.w,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        MyText(
                          text: material['material_name'],
                          color: Colors.white,
                          weight: FontWeight.w500,
                        ),
                        MyText(
                          text: " CostCode: ${material['cost_code']}",
                          color: Colors.white,
                          weight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        MyText(
                          text: "  Unit: ${material['unit']}",
                          color: Colors.white,
                          weight: FontWeight.w500,
                        ),
                        MyText(
                          text: "  GST: ${material['gst_per']}",
                          color: Colors.white,
                          weight: FontWeight.w500,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),

    );
  }

  void _showAddMaterialBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 16.h,
            left: 16.w,
            right: 16.w,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: MyText(
                  text: "Create New Material",
                  color: Colors.black,
                  weight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              _buildTextFormField("Material Name", materialName),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedUnit,
                      hint: const Text(
                        "Select Unit",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      items: unitName
                          .map((unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedUnit = value);
                      },
                      decoration: InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedGst,
                      hint: const Text(
                        "Select GST",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      items: gstPercent
                          .map((gst) => DropdownMenuItem(
                        value: gst,
                        child: Text("$gst%"),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedGst = value);
                      },
                      decoration: InputDecoration(
                        labelText: "GST",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildTextFormField("Cost Code", costCode),
              SizedBox(height: 12.h),
              _buildTextFormField("Description", description, maxLines: 3),
              SizedBox(height: 20.h),
              Center(
                child: ElevatedButton(
                  onPressed: () => addMaterial(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: MyText(
                    text: "Save",
                    color: Colors.white,
                    weight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextFormField(
      maxLines: maxLines,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
          textStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}
