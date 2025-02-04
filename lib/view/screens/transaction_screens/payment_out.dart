import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:vetri_hollowblock/view/screens/transaction_screens/transaction_details.dart';

import '../../universal_key_api/api_url.dart';
import '../../widgets/buttons.dart';
import '../../widgets/subhead.dart';
import '../../widgets/text.dart';
import '../tabs_pages.dart';

class PaymentOut extends StatefulWidget {
  const PaymentOut({super.key, required this.projectName,required this.work});
  final String projectName;
  final String work;

  @override
  State<PaymentOut> createState() => _PaymentOutState();
}

class _PaymentOutState extends State<PaymentOut> {
  late double height;
  late double width;

  List<String> partyName = []; // List to hold party names
  String? selectedName; // Selected party name
  bool isLoading = false;

  DateTime selectedDate = DateTime.now();
  final amountReceivedController = TextEditingController();
  final descriptionController = TextEditingController();
  final bankDetailsController = TextEditingController();
  // Removed fromPartyController because we are using a dropdown for "From Party"

  String? selectedPaymentMethod; // Initially null

  /// Formated date logic //
  String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    fetchPartyName();
  }

  /// Function to show the date picker
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

  /// Get Api for party name
  Future<void> fetchPartyName() async {
    final String url =
        "$apiUrl/Party?fields=[%22party_name%22]&limit_page_length=50000";
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $apiKey',
          'Content-Type': 'application/json',
        },
      );
      print(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          partyName = List<String>.from(
              data['data'].map((party) => party['party_name']));
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
             /// Post method for payment out //
  Future<void> MobileDocument(BuildContext context) async {
    HttpClient client = HttpClient();
    client.badCertificateCallback =
    ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    // Determine which payment method is selected:
    final int cashValue = (selectedPaymentMethod == "Cash") ? 1 : 0;
    final int bankTransferValue = (selectedPaymentMethod == "Bank Transfer") ? 1 : 0;
    final int chequeValue = (selectedPaymentMethod == "Cheque") ? 1 : 0;

    final data = {
      'doctype': 'Payment Out',
      'to_party': selectedName,
      'date': formattedDate,
      'amount_rec': amountReceivedController.text,
      'description': descriptionController.text,
      'cash': cashValue,
      'bank_transfer': bankTransferValue,
      'cheque': chequeValue,
      'bank_detail': bankDetailsController.text,
      'project_form': widget.projectName
    };

    final url = '$apiUrl/Payment Out'; // Replace with your actual API URL
    final body = jsonEncode(data);
    print(data);

    try {
      final response =
      await ioClient.post(Uri.parse(url), headers: headers, body: body);
      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        Get.snackbar(
          "Payment Out Created",
          " and Posted Successfully",
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.off(TabsPages(projectName: widget.projectName, initialTabIndex: 1, work: widget.work));
      } else {
        print('Failed: ${response.statusCode}');
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
      print('Error: $e');
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
          return Center(
            child: Text(
              "Please make sure your device is in portrait view",
              style: TextStyle(fontSize: 18.sp, color: Colors.grey),
            ),
          );
        }
      },
    );
  }

  Widget _smallBuildLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80.h,
        centerTitle: true,
        title: Subhead(
          text: "Payment Out",
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              // Replace "From Party" text field with a dropdown.
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "To Party",
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
                        ),
                        value: selectedName,
                        items: partyName.map((String party) {
                          return DropdownMenuItem<String>(
                            value: party,
                            child: Text(
                              party,
                              style: GoogleFonts.dmSans(
                                textStyle: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedName = newValue;
                          });
                        },
                        hint: const Text("Select a Party"),
                ),
              ),
              SizedBox(height: 22.h),
              _buildTextField("Amount Received", amountReceivedController,
                  TextInputType.number),
              SizedBox(height: 22.h),
              _buildTextField("Description", descriptionController,
                  TextInputType.text),
              SizedBox(height: 22.h),

              /// Payment Method Selection
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                child: Text(
                  "Payment Method",
                  style: GoogleFonts.dmSans(
                    textStyle: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  _buildRadioButton("Cash"),
                  _buildRadioButton("Bank Transfer"),
                  _buildRadioButton("Cheque"),
                ],
              ),

              /// Show Bank Details TextField if Bank Transfer or Cheque is selected
              if (selectedPaymentMethod == "Bank Transfer" ||
                  selectedPaymentMethod == "Cheque") ...[
                SizedBox(height: 10.h),
                _buildTextField("Enter Bank Details", bankDetailsController,
                    TextInputType.text),
              ],
              SizedBox(height: 20.h),
              Center(
                child: GestureDetector(
                  onTap: (){
                    MobileDocument(context);
                  },
                  child: Buttons(
                    height: height / 20,
                    width: width / 2.5,
                    radius: BorderRadius.circular(10.r),
                    color: Colors.blue,
                    text: "Save",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Common TextField Widget
  Widget _buildTextField(
      String label, TextEditingController controller, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  /// Radio Button Widget (No Default Selection)
  Widget _buildRadioButton(String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: selectedPaymentMethod, // Initially null
          onChanged: (String? newValue) {
            setState(() {
              selectedPaymentMethod = newValue;
            });
          },
          activeColor: Colors.blue,
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            textStyle: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
