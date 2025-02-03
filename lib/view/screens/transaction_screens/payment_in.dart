import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../widgets/buttons.dart';
import '../../widgets/subhead.dart';
import '../../widgets/text.dart';

class PaymentIn extends StatefulWidget {
  const PaymentIn({super.key});

  @override
  State<PaymentIn> createState() => _PaymentInState();
}

class _PaymentInState extends State<PaymentIn> {
  late double height;
  late double width;
  DateTime selectedDate = DateTime.now();
  final amountReceivedController = TextEditingController();
  final descriptionController = TextEditingController();
  final bankDetailsController = TextEditingController();
  final fromPartyController = TextEditingController();

  String? selectedPaymentMethod; // Initially null

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
      backgroundColor: const Color(0xfff1f2f4),
      appBar: AppBar(
        backgroundColor: const Color(0xfff1f2f4),
        toolbarHeight: 80.h,
        centerTitle: true,
        title: Subhead(
          text: "Payment In",
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
              _buildTextField("From Party", fromPartyController, TextInputType.text),
              SizedBox(height: 22.h),
              _buildTextField("Amount Received", amountReceivedController, TextInputType.number),
              SizedBox(height: 22.h),
              _buildTextField("Description", descriptionController, TextInputType.text),
              SizedBox(height: 22.h),

              /// Payment Method Selection
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h,horizontal: 8.w),
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
              if (selectedPaymentMethod == "Bank Transfer" || selectedPaymentMethod == "Cheque") ...[
                SizedBox(height: 10.h),
                _buildTextField("Enter Bank Details", bankDetailsController, TextInputType.text),
              ],
              SizedBox(height: 20.h,),
              Center(
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
      ),
    );
  }

  /// Common TextField Widget
  Widget _buildTextField(String label, TextEditingController controller, TextInputType type) {
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
