import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/io_client.dart';
import 'package:vetri_hollowblock/view/screens/materials/purchased_screen/purchased_screen.dart';
import 'package:vetri_hollowblock/view/screens/materials/received_screen/received_screen.dart';
import 'package:vetri_hollowblock/view/screens/materials/used_screen.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';
import 'package:http/http.dart' as http;
import '../../universal_key_api/api_url.dart';
import '../../widgets/subhead.dart';

class MaterialsAdd extends StatefulWidget {
  const MaterialsAdd({super.key, required this.routeType,required this.projectName, required this.work});
  final String routeType;
  final String projectName;
  final String work;

  @override
  State<MaterialsAdd> createState() => _MaterialsAddState();
}

class _MaterialsAddState extends State<MaterialsAdd> {
  late double height;
  late double width;
  List<dynamic> materials = []; // List to hold fetched materials
  List<dynamic> filteredMaterials = []; // Li
  List<String> unitName = []; // List to hold unit names
  String? selectedUnit;
  List<String> gstPercent = []; // List to hold GST percentages
  String? selectedGst;
  bool isLoading = false;
  // Add new variables for selection
  Map<int, bool> selectedMaterials = {};
  bool selectAll = false;

  /// Textediting controllers
  final materialName = TextEditingController();
  final costCode = TextEditingController();
  final description = TextEditingController();
  final searchController = TextEditingController(); // Controller for search input

  @override
  void initState() {
    super.initState();
    fetchMaterials();
    fetchUnit();
    fetchGst();
    // Add listener for search text changes
    searchController.addListener(() {
      filterMaterials(searchController.text);
    });
  }
  /// Filter materials based on search query
  void filterMaterials(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredMaterials = materials; // Show all materials when the search is empty
      });
    } else {
      setState(() {
        filteredMaterials = materials.where((material) {
          // Check if the material name or cost code matches the search query
          return material['material_name'].toLowerCase().contains(query.toLowerCase()) ||
              material['cost_code'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
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
          filteredMaterials = materials;  // Update the filtered list immediately
        });
      } else {
        print("Failed to fetch materials. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching materials: $e");
    } finally {
      setState(() => isLoading = false);  // Ensure isLoading is set to false
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
          ? const Center(child: CircularProgressIndicator()) // Show loading initially
          : Column(
        children: [
          SizedBox(height: 10.h,),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0.w),
            child: TextFormField(
              controller: searchController,
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
          Expanded(
            child: Column(
              children: [
                // This will show the "Add Material" button if no materials are found
                if (materials.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0.w),
                    child: GestureDetector(
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
                  ),
                SizedBox(height: 20.h), // Added extra spacing for better alignment

                // Display materials when they are available
                Expanded(
                  child: filteredMaterials.isEmpty
                      ? Center(child: Text("No materials found"))
                      : ListView.builder(
                    itemCount: filteredMaterials.length,
                    itemBuilder: (context, index) {
                      final material = filteredMaterials[index];
                      return GestureDetector(
                        onTap: () {
                          if (widget.routeType == 'used') {
                            Get.off(() => UsedScreen(material: material, projectName: widget.projectName, work: widget.work,));
                          } else if (widget.routeType == 'received') {
                            Get.off(() => ReceivedScreen(material: material, projectName: widget.projectName, work: widget.work,));
                          } else if (widget.routeType == 'purchased') {
                            Get.off(() => PurchasedScreen(material: material, projectName: widget.projectName, work: widget.work,));
                          }
                        },

                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      MyText(
                                        text: material['material_name']?.trim() ?? "No Name",
                                        color: Colors.black,
                                        weight: FontWeight.bold,
                                      ),
                                      MyText(
                                        text: "Cost Code: ${material['cost_code'] ?? '--'}",
                                        color: Colors.grey.shade600,
                                        weight: FontWeight.w500,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      MyText(
                                        text: "Unit: ${material['unit'] ?? '--'}",
                                        color: Colors.grey.shade600,
                                        weight: FontWeight.w500,
                                      ),
                                      MyText(
                                        text: "GST: ${material['gst_per'] ?? '--'}%",
                                        color: Colors.blue,
                                        weight: FontWeight.w500,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
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