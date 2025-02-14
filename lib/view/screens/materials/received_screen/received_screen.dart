import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:vetri_hollowblock/view/screens/materials/materials_add.dart';
import 'package:vetri_hollowblock/view/screens/materials/received_screen/create_party.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';
import 'package:http/http.dart' as http;
import '../../../universal_key_api/api_url.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/subhead.dart';
import '../material_details.dart';

class ReceivedScreen extends StatefulWidget {
  const ReceivedScreen({super.key, required this.material});
  final Map<String, dynamic> material; // Accept material data

  @override
  State<ReceivedScreen> createState() => _ReceivedScreenState();
}

class _ReceivedScreenState extends State<ReceivedScreen> {
  late double height;
  late double width;
  DateTime selectedDate = DateTime.now(); // Store the selected date
  List<String> partyName = []; // List to hold party names
  String? selectedName; // Selected party name
  bool isLoading = false;
  final TextEditingController qtyController = TextEditingController();

  /// Date logic for calendar
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
    HttpClient client = HttpClient();
    client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    final data = {
      'doctype': 'Material Received',
      'party_name': selectedName,
      'material_name':  widget.material['material_name'] ,
      'quantity': qtyController.text,
      'date': DateFormat('yyyy-MM-dd').format(selectedDate), // Format DateTime as a string,
    };
    print(data);
    final url = '$apiUrl/Material Received';
    final body = jsonEncode(data);

    try {
      final response = await ioClient.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        Get.snackbar(
          "Material Received Posted",
          "Successfully",
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Navigate back to MaterialScreen and pass the data
        // Get.off(
        //   MaterialScreen(),
        //   arguments: {
        //     'material_name': widget.material['material_name'],
        //     'quantity': qtyController.text,
        //     'party_name': selectedName,
        //     'date': DateFormat('yyyy-MM-dd').format(selectedDate), // Format DateTime as a string,
        //   },
        // );
        Get.off(
          MaterialScreen(),
          arguments: {
            'received': {
              'material_name': widget.material['material_name'],
              'quantity': qtyController.text,
              'party_name': selectedName,
              'date': DateFormat('yyyy-MM-dd').format(selectedDate),
            },
          },
        );
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
  void initState() {
    super.initState();
    fetchPartyName(); // Fetch party names when the screen is initialized
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
          text: "Material Received",
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
                  onChanged: (value) {
                    setState(() {
                      selectedName = value;
                    });
                  },
                ),
              ),

              SizedBox(height: 10.h), // Add some space between the dropdown and the "Add Party" button

              // "Add Party" Button placed below the Dropdown
              GestureDetector(
                onTap: () {
                  Get.to(const CreateParty()); // Navigate to the screen to add a new party
                },
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: MyText(text: " + Add Party", color: Colors.blue, weight: FontWeight.w500),
                  ),
                ),
              ),

              SizedBox(height: 20.h), // Add space between "Add Party" and other components

              GestureDetector(
                onTap: () {
                  Get.to(MaterialsAdd(routeType: 'received',));
                },
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: MyText(text: " + Add Material", color: Colors.blue, weight: FontWeight.w500),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Only show the material name and quantity input if a material is selected
              if (widget.material.isNotEmpty && widget.material['material_name'] != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0.w),
                  child: Column(
                    children: [
                      // Material Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Material Name",
                            style: GoogleFonts.dmSans(fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.material['material_name'] ?? 'N/A', // Display material name
                            style: GoogleFonts.dmSans(fontSize: 14.sp, color: Colors.grey[700]),
                          ),
                        ],
                      ),

                      SizedBox(height: 10.h), // Space between material name and quantity field

                      // Quantity Input
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Enter Quantity",
                            style: GoogleFonts.dmSans(fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            width: 120.w, // Adjust width of the quantity input field
                            child: TextFormField(
                              controller: qtyController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Quantity",
                                hintText: "Qty",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

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
