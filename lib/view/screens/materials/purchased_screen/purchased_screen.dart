import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetri_hollowblock/view/screens/materials/materials_add.dart';
import 'package:vetri_hollowblock/view/screens/materials/received_screen/create_party.dart';
import 'package:vetri_hollowblock/view/screens/tabs_pages.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';
import 'package:http/http.dart' as http;

import '../../../universal_key_api/api_url.dart';
import '../../../widgets/subhead.dart';


class PurchasedScreen extends StatefulWidget {
   PurchasedScreen({super.key, required this.material,required this.projectName,required this.work});
    late  String projectName;
   late String work; //
  final Map<String, dynamic> material; // Accept material data

  @override
  State<PurchasedScreen> createState() => _PurchasedScreenState();
}

class _PurchasedScreenState extends State<PurchasedScreen> {
  late double height;
  late double width;
  DateTime selectedDate = DateTime.now(); // Store the selected date
  List<String> partyName = []; // List to hold party names
  String? selectedName; // Selected party name
  bool isLoading = false;
  final TextEditingController qtyController = TextEditingController();

  double baseAmount = 0.0; // User-provided base amount
  double additionalCharges = 0.0; // Additional charges
  double discount = 0.0; // Discount percentage
  double totalAmount = 0.0; // Total amount after calculations

  bool showBaseAmountField = true; // Always show the base amount field
  bool showAdditionalChargesField = false; // Toggle for additional charges field
  bool showDiscountField = false; // Toggle for discount field
  bool showNotesField = false; // Toggle for notes field
  bool showReferenceField = false; // Toggle for reference number field

  final TextEditingController baseAmountController = TextEditingController();
  final TextEditingController additionalChargesController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();


  // Method to calculate the total amount dynamically
  void _updateTotalAmount() {
    setState(() {
      double amountWithCharges = baseAmount + additionalCharges;
      double discountAmount = amountWithCharges * (discount / 100);
      totalAmount = (amountWithCharges - discountAmount).clamp(0, double.infinity);
    });
  }

               /// Add Material Whole Container logic //
  final TextEditingController unitRateController = TextEditingController();
  String? selectedGST = "18.0%"; // Default GST value
  double total = 0.0;
  double gstAmount = 0.0;
  double subTotal = 0.0;

  final List<String> gstValues = [
    "0.0%",
    "5.0%",
    "12.0%",
    "18.0%",
    "28.0%",
    "0.1%",
    "0.25%",
    "1.5%",
    "3.0%",
    "6.0%",
    "7.5%",
    "14.0%",
  ]; // Dropdown GST options

  // Method to calculate the total and GST
  void _calculateTotal() {
    setState(() {
      // Parse quantity and unit rate
      double quantity = double.tryParse(qtyController.text) ?? 0.0;
      double unitRate = double.tryParse(unitRateController.text) ?? 0.0;

      // Step 1: Calculate Base Total (Quantity × Unit Rate)
      total = quantity * unitRate;

      // Step 2: Calculate GST Amount (GST % of Base Total)
      double gstPercentage = double.tryParse(selectedGST?.replaceAll("%", "") ?? "0") ?? 0.0;
      gstAmount = total * (gstPercentage / 100);

      // Step 3: Add GST and Additional Charges to get Subtotal
      double amountWithCharges = total + gstAmount + additionalCharges;

      // Step 4: Subtract Discount (fixed discount amount)
      double discountAmount = discount; // Treat `discount` as a fixed amount, not a percentage

      // Step 5: Calculate Final Subtotal
      subTotal = (amountWithCharges - discountAmount).clamp(0, double.infinity);

      print("Base Total: $total");
      print("GST Amount: $gstAmount");
      print("Subtotal with Charges: $amountWithCharges");
      print("Discount Amount: $discountAmount");
      print("Final Subtotal: $subTotal");
    });
  }


              /// Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000), // Earliest selectable date
      lastDate: DateTime(2101), // Latest selectable date
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked; // Update the selected date
      });
    }
  }

          /// Get Api's for Party Name ///
  Future<void> fetchPartyName() async {
    final String url = "$apiUrl/Party?fields=[%22party_name%22]&limit_page_length=50000";
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
          partyName = List<String>.from(data['data'].map((party) => party['party_name'])); // Extract party names
        });
      } else {
        print("Failed to fetch party names. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching party names: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }
  /// Post method for Material Received //
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
      if (selectedName!.isEmpty ||
          qtyController.text.isEmpty ||
          widget.material['material_name'] == null) {
        throw Exception('Please fill in all required fields');
      }

      final data = {
        'doctype': 'Material Purchase',
        'party_name': selectedName,
        'material': widget.material['material_name'],
        'quantity': qtyController.text,
        'additional_discount': additionalChargesController.text,
        'add_discount': discountController.text,
        'add_notes': notesController.text,
        'reference_no': referenceController.text,
        'unit_rate': unitRateController.text,
        'gst': gstAmount,
        'total': total,
        'sub_total': subTotal,
        'project_form': widget.projectName,
        'name': '',
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
      };

      print('Sending purchase request for project: ${widget.projectName}');
      print('Request payload: $data');

      final url = '$apiUrl/Material Purchase';
      final body = jsonEncode(data);

      final response = await ioClient.post(
          Uri.parse(url),
          headers: headers,
          body: body
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Store successful purchase data locally
        final purchaseBox = await Hive.openBox('purchasedMaterialData');
        await purchaseBox.add({
          'material': widget.material['material_name'],
          'quantity': qtyController.text,
          'party_name': selectedName,
          'date': DateFormat('yyyy-MM-dd').format(selectedDate),
          'project_name': widget.projectName,
        });

        Get.snackbar(
          "Success",
          "Material Purchase Posted Successfully",
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
            'purchased': {
              'material': widget.material['material_name'],
              'quantity': qtyController.text,
              'party_name': selectedName,
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
      print('Error in material purchase: $e');
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

  // New method to handle initialization
  Future<void> _initializeData() async {
    await Future.wait([
      fetchPartyName(),
      loadSelectedName(),
    ]);
  }

  // Modified saveSelectedName to handle null values
  Future<void> saveSelectedName(String? name) async {
    if (name == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedName', name);
  }

  // Modified loadSelectedName to update state
  Future<void> loadSelectedName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedName = prefs.getString('selectedName');
    });
  }


  @override
  void initState() {
    super.initState();
    print("Project Name in Purchased: ${widget.projectName}"); // Debugging
    print("Project work  in Purchased: ${widget.work}"); // Debugging
    _initializeData();
  }
  @override
  void dispose() {
    additionalChargesController.dispose();
    discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Define Sizes
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
          text: "Add Material Purchase",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
              onTap: () => _selectDate(context), // Call date picker on tap
              child: MyText(
                text: DateFormat('dd-MM-yyyy').format(selectedDate), color: Colors.black, weight: FontWeight.w500, // Display current date
              ),
            ),
          ),
        ],
      ),
      body: SizedBox(
        width: width.w,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10.h),

              // Party Name Dropdown
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0.w),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Party Name",
                    labelStyle: GoogleFonts.dmSans(
                      textStyle: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    prefixIcon: const Icon(Icons.person_pin),
                  ),
                  value: selectedName,
                  items: partyName.map((party) {
                    return DropdownMenuItem<String>(
                      value: party,
                      child: Text(
                        party,
                        style: GoogleFonts.dmSans(fontSize: 15.sp),
                      ),
                    );
                  }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedName = value;
                      });
                      saveSelectedName(value); // Save whenever selection changes
                    }
                ),
              ),

              SizedBox(height: 10.h), // Add some space between the dropdown and the "Add Party" button

              // "Add Party" Button placed below the Dropdown
              GestureDetector(
                onTap: () {
                  Get.to(() => CreateParty(sourceScreen: 'PurchasedScreen'));
                },
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: MyText(text: " + Add Party", color: Colors.blue, weight: FontWeight.w500),
                  ),
                ),
              ),

              SizedBox(height: 15.h), // Add space between "Add Party" and other components

              GestureDetector(
                onTap: () {
                  Get.to(MaterialsAdd(routeType: 'purchased', projectName: widget.projectName, work : widget.work));
                },
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: MyText(text: " + Add Material", color: Colors.blue, weight: FontWeight.w500),
                  ),
                ),
              ),
              // Only show the material name and quantity input if a material is selected
              if (widget.material.isNotEmpty && widget.material['material_name'] != null)
                Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12.0),
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cancel Button (Top Right)
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: Icon(Icons.cancel, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                widget.material.clear(); // Clear the selected material
                              });
                            },
                          ),
                        ),

                        // Material Name and GST Dropdown
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column: Material Name and GST
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.material['material_name'] ?? 'N/A',
                                    style: GoogleFonts.dmSans(fontSize: 16.sp, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "GST: ",
                                        style: GoogleFonts.dmSans(fontSize: 14.sp, fontWeight: FontWeight.w500),
                                      ),
                                      DropdownButton<String>(
                                        value: selectedGST,
                                        items: gstValues.map((value) {
                                          return DropdownMenuItem(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedGST = value;
                                            _calculateTotal();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Right Column: Quantity and Unit Rate
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Quantity Input
                                  SizedBox(
                                    width: 150.w,
                                    child: TextFormField(
                                      controller: qtyController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: "Quantity",
                                        hintText: "Qty",
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      onChanged: (value) {
                                        _calculateTotal();
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 10.h),

                                  // Unit Rate Input
                                  SizedBox(
                                    width: 150.w,
                                    child: TextFormField(
                                      controller: unitRateController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: "Unit Rate",
                                        hintText: "Rate",
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      onChanged: (value) {
                                        _calculateTotal();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16.h),

                        // Total Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total:",
                              style: GoogleFonts.dmSans(fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Icon(Icons.currency_rupee, size: 16.sp),
                                Text(
                                  total.toStringAsFixed(2),
                                  style: GoogleFonts.dmSans(fontSize: 16.sp, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Sub Total (Incl. GST):",
                              style: GoogleFonts.dmSans(fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Icon(Icons.currency_rupee, size: 16.sp),
                                Text(
                                  subTotal.toStringAsFixed(2),
                                  style: GoogleFonts.dmSans(fontSize: 16.sp, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ),
              SizedBox(height: 15.h,),
              GestureDetector(
                onTap: () {
                  setState(() {
                    showAdditionalChargesField = !showAdditionalChargesField;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                      child: MyText(text: " + Additional Charges", color: Colors.blue, weight: FontWeight.w500)),
                ),
              ),
// Additional Charges Field
              if (showAdditionalChargesField)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: SizedBox(
                    width: 240, // Increased width for a more spacious input
                    height: 48, // Adjusted height for a modern feel
                    child: Padding(
                      padding:  EdgeInsets.only(left: 100.0.w),
                      child: TextFormField(
                        controller: additionalChargesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Additional Charges",
                          labelStyle: GoogleFonts.outfit(
                            textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0), // Rounded corners
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Colors.blue, width: 1.5), // Elevated border on focus
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1), // Subtle border
                          ),
                          filled: true,
                          fillColor: Colors.grey[100], // Light background
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Adjusted padding
                        ),
                        style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.black87),
                        onChanged: (value) {
                          setState(() {
                            additionalCharges = double.tryParse(value) ?? 0.0;
                            _calculateTotal();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 15.h,),
              // Add Discount Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    showDiscountField = !showDiscountField;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: MyText(text: " + Add Discount", color: Colors.blue, weight: FontWeight.w500)),
                ),
              ),
// Discount Field
              if (showDiscountField)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: SizedBox(
                    width: 240, // Increased width for a balanced input
                    height: 48, // Adjusted height for uniformity
                    child: Padding(
                      padding:  EdgeInsets.only(left: 100.0.w),
                      child: TextFormField(
                        controller: discountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Discount Amount",
                          labelStyle: GoogleFonts.outfit(
                            textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Colors.blue, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.black87),
                        onChanged: (value) {
                          setState(() {
                            discount = double.tryParse(value) ?? 0.0;
                            _calculateTotal();
                          });
                        },
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 20.0),
              SizedBox(height: 10.h,),
              GestureDetector(
                onTap: () {
                  setState(() {
                    showNotesField = !showNotesField;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                      child: MyText(text: " + Add Notes", color: Colors.blue, weight: FontWeight.w500)),
                ),
              ),
              if (showNotesField)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: TextFormField(
                    controller: notesController,
                    maxLines: 3, // Multi-line notes
                    decoration: InputDecoration(
                      labelText: "Notes",
                      labelStyle: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 16.sp,fontWeight: FontWeight.w500,color: Colors.grey)),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              SizedBox(height: 10.h,),
              GestureDetector(
                onTap: () {
                  setState(() {
                    showReferenceField = !showReferenceField;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                      child: MyText(text: " + Reference No", color: Colors.blue, weight: FontWeight.w500)),
                ),
              ),
              if (showReferenceField)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: SizedBox(
                    width: 200.w, // Compact width
                    height: 50.h, // Compact height
                    child: TextFormField(
                      controller: referenceController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: "Reference No",
                        labelStyle: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 16.sp,fontWeight: FontWeight.w500,color: Colors.grey)),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 16.h),

              SizedBox(height: 20.h),

              // Save Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0.w),
                child: ElevatedButton(
                  onPressed: () {
                    MobileDocument(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: MyText(text: "Save", color: Colors.white, weight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
