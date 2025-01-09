import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/io_client.dart';
import 'package:vetri_hollowblock/view/screens/materials/received_screen/received_screen.dart';
import 'package:vetri_hollowblock/view/universal_key_api/api_url.dart';
import 'package:http/http.dart'as http;
import '../../../widgets/buttons.dart';
import '../../../widgets/subhead.dart';
import '../../../widgets/text.dart';

class CreateParty extends StatefulWidget {
  const CreateParty({super.key});

  @override
  State<CreateParty> createState() => _CreatePartyState();
}

class _CreatePartyState extends State<CreateParty> {
  late double height;
  late double width;

  // Variables to hold GST data
  String? gstNo;
  String? legalBusinessName;
  String? stateOfSupply;
  String? billingAddress;
  List<String> partyTypes = []; // List to store fetched party types
  String? selectedPartyType; // Selected party type
  bool isLoading = false;
  // To track whether GST details are saved
  bool isGstAdded = false;
      /// TextEdititng Controller ///
  final TextEditingController partyname = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController partyid = TextEditingController();
  final TextEditingController gstNoController = TextEditingController();
  final TextEditingController legalNameController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController billingController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController partyWillPayController = TextEditingController();
  TextEditingController partyWillReceiveController = TextEditingController();

       /// Get Api's for Party Type //
  /// Get API for Party Types
  Future<void> fetchPartyType() async {
    final String url = "$apiUrl/Party%20Type?limit_page_length=50000";
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
        print(response.body);
        setState(() {
          partyTypes = List<String>.from(data['data'].map((party) => party['name']));
        });
      } else {
        print("Failed to fetch party types. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching party types: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

         /// Post method for Party ///
  Future<void> MobileDocument(BuildContext context) async {
    HttpClient client = HttpClient();
    client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    final data = {
      'doctype': 'Party',
      'party_name': partyname.text,
      'phone_no': phone.text,
      'party_type': selectedPartyType,
      'party_id': partyid.text,
      'gst_no': gstNoController.text,
      'legal_business_name': legalNameController.text,
      'state_of_suppy': stateController.text,
      'billing_address': billingController.text,
      'party_will_pay': partyWillPayController.text,
      'party_will_receive': partyWillReceiveController.text,


    };

    final url = '$apiUrl/Party'; // Replace with your actual API URL
    final body = jsonEncode(data);
    print(data);

    try {
      // Use Uri.parse() to convert the string URL into a Uri object
      final response = await ioClient.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        Get.snackbar(
          "Party Created",
          " and Posted Successfully",
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.to(ReceivedScreen(material: {},));
      }
      else {
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
    // TODO: implement initState
    super.initState();
    fetchPartyType();
  }

  @override
  Widget build(BuildContext context) {
       /// Define Sizes ///
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
          text: "Create New Party",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
      ),
      body: SizedBox(
        width: width.w,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20.h),
              _buildTextField("Party Name",partyname),
              SizedBox(height: 30.h),
              _buildTextField("Phone Number",phone),
              SizedBox(height: 30.h),
              _buildDropdownField("Party Type"),
              SizedBox(height: 30.h),
              _buildTextField("Party Id",partyid),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () {
                  _showGstBottomSheet(context);
                },
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: MyText(
                      text: " + Add GST",
                      color: Colors.blue,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              if (isGstAdded) ...[
                ListTile(
                  title: Text("GST No: $gstNo"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Legal Name: $legalBusinessName"),
                      Text("State: $stateOfSupply"),
                      Text("Billing Address: $billingAddress"),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
              ],
              GestureDetector(
                onTap: () {
                  _showOpeningBalanceBottomSheet(context);
                },
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: MyText(
                      text: "Opening Balance",
                      color: Colors.blue,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: GestureDetector(
                  onTap: (){
                    MobileDocument(context);
                  },
                  child: Buttons(
                    height: height / 20.h,
                    width: width / 2.5.w,
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.0.w),
      child: TextFormField(
        controller: controller,
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
     /// Show dropdown for Party Type //
  /// Dropdown Widget for Party Type
  Widget _buildDropdownField(String label) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.0.w),
      child: isLoading
          ? CircularProgressIndicator() // Show loading indicator while fetching
          : DropdownButtonFormField<String>(
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
              items: partyTypes
                  .map((partyType) => DropdownMenuItem<String>(
                        value: partyType,
                        child: Text(partyType),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedPartyType = value; // Update the selected value
                });
              },
              value: selectedPartyType,
              hint: Text("Select Party Type"),
            ),
    );
  }

  void _showGstBottomSheet(BuildContext context) {


    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "GST Details",
                style: GoogleFonts.dmSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),
              _buildBottomSheetTextField("GST No", gstNoController),
              SizedBox(height: 20.h),
              _buildBottomSheetTextField("Legal Business Name", legalNameController),
              SizedBox(height: 20.h),
              _buildBottomSheetTextField("State of Supply", stateController),
              SizedBox(height: 20.h),
              _buildBottomSheetTextField("Billing Address", billingController),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: GestureDetector(
                  onTap: (){
                    setState(() {
                      gstNo = gstNoController.text;
                      legalBusinessName = legalNameController.text;
                      stateOfSupply = stateController.text;
                      billingAddress = billingController.text;
                      isGstAdded = true;
                    });
                    Navigator.pop(context);
                  },
                  child: Buttons(
                    height: height / 20.h,
                    width: width / 2.5.w,
                    radius: BorderRadius.circular(10.r),
                    color: Colors.blue,
                    text: "Save",
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }


  Widget _buildBottomSheetTextField(
      String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
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
    );
  }

  void _showOpeningBalanceBottomSheet(BuildContext context) {
    String? selectedOption; // To track selected radio button

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter modalSetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Opening Balance",
                    style: GoogleFonts.dmSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: MyText(
                            text: "Party Will Pay",
                            color: Colors.black,
                            weight: FontWeight.w500,
                          ),
                          value: "Party Will Pay",
                          groupValue: selectedOption,
                          onChanged: (value) {
                            modalSetState(() {
                              selectedOption = value;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: MyText(
                            text: "Party Will Receive",
                            color: Colors.black,
                            weight: FontWeight.w500,
                          ),
                          value: "Party Will Receive",
                          groupValue: selectedOption,
                          onChanged: (value) {
                            modalSetState(() {
                              selectedOption = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  if (selectedOption == "Party Will Pay")
                    TextFormField(
                      controller: partyWillPayController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Amount for Party Will Pay",
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
                  if (selectedOption == "Party Will Receive")
                    TextFormField(
                      controller: partyWillReceiveController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Amount for Party Will Receive",
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
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        if (selectedOption == "Party Will Pay" &&
                            partyWillPayController.text.isNotEmpty) {
                          // Save logic for "Party Will Pay"
                          print("Party Will Pay Amount: ${partyWillPayController.text}");
                          Navigator.pop(context); // Close the bottom sheet
                        } else if (selectedOption == "Party Will Receive" &&
                            partyWillReceiveController.text.isNotEmpty) {
                          // Save logic for "Party Will Receive"
                          print("Party Will Receive Amount: ${partyWillReceiveController.text}");
                          Navigator.pop(context); // Close the bottom sheet
                        } else {
                          // Show error if fields are not filled
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Please fill all fields"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Buttons(
                        height: 50.h,
                        width: 150.w,
                        radius: BorderRadius.circular(10.r),
                        color: Colors.blue,
                        text: "Save",
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

}
