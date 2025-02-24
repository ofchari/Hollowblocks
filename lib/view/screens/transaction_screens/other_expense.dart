import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vetri_hollowblock/view/widgets/buttons.dart';
import '../../universal_key_api/api_url.dart';
import '../../widgets/subhead.dart';
import '../../widgets/text.dart';
import 'package:http/http.dart'as http;

class OtherExpense extends StatefulWidget {
  const OtherExpense({super.key});

  @override
  State<OtherExpense> createState() => _OtherExpenseState();
}

class _OtherExpenseState extends State<OtherExpense> {
  late double height;
  late double width;
  List<String> partyName = [];
  String? selectedName;
  bool isLoading = false;
  bool showGstField = false;
  bool showDiscountField = false;

  TextEditingController amountController = TextEditingController();
  TextEditingController gstController = TextEditingController();
  TextEditingController discountController = TextEditingController();

  DateTime selectedDate = DateTime.now();

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
  /// Get Api for party name ///
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

  double calculateTotal() {
    double amount = double.tryParse(amountController.text) ?? 0;
    double gst = double.tryParse(gstController.text) ?? 0;
    double discount = double.tryParse(discountController.text) ?? 0;
    return amount + gst - discount;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchPartyName();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80.h,
        centerTitle: true,
        title: Subhead(
          text: "Other Expenses",
          color: Colors.black,
          weight: FontWeight.w600,
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
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Party Dropdown
            _buildDropdown(),
            SizedBox(height: 16.h),
            // Amount Field
            _buildTextField(amountController, "Amount", TextInputType.number),
            SizedBox(height: 16.h),
            // GST Section
            _buildExpandableField(
              "Add GST",
              showGstField,
                  () => setState(() => showGstField = !showGstField),
              gstController,
              "GST Amount",
            ),
            SizedBox(height: 16.h),
            // Discount Section
            _buildExpandableField(
              "Add Discount",
              showDiscountField,
                  () => setState(() => showDiscountField = !showDiscountField),
              discountController,
              "Discount Amount",
            ),
            SizedBox(height: 20.h),
            // Total Amount
            Container(
              padding: EdgeInsets.all(12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: Colors.grey[200],
              ),
              child: Center(
                child: MyText(
                  text: "Total Amount: ₹${calculateTotal().toStringAsFixed(2)}",
                  color: Colors.black,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            // Save Button
            Center(
              child: Buttons(
                height: 50.h,
                width: width / 2,
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

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
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
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey),
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
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType keyboardType) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildExpandableField(String label, bool isExpanded, VoidCallback onTap, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: MyText(text: isExpanded ? "- $label" : "+ $label", color: Colors.blue, weight: FontWeight.w600),
        ),
        if (isExpanded) ...[
          SizedBox(height: 8.h),
          _buildTextField(controller, hint, TextInputType.number),
        ],
      ],
    );
  }
}
