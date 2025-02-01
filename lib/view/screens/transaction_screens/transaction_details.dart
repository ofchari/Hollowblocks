import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vetri_hollowblock/view/screens/transaction_screens/payment_in.dart';
import 'package:vetri_hollowblock/view/screens/transaction_screens/payment_out.dart';
import 'package:vetri_hollowblock/view/widgets/heading.dart';
import 'package:vetri_hollowblock/view/widgets/subhead.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';

class TransactionDetails extends StatefulWidget {
  const TransactionDetails({super.key});

  @override
  State<TransactionDetails> createState() => _TransactionDetailsState();
}

class _TransactionDetailsState extends State<TransactionDetails> {
  late double height;
  late double width;

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
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _bottomButton("Payment In", Colors.green,PaymentIn()),
            GestureDetector(
              onTap: () => _showBottomSheet(context),
              child: Container(
                height: 50.h,
                width: 45.w,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: Colors.white),
              ),
            ),
            _bottomButton("Payment Out", Colors.red , PaymentOut()),
          ],
        ),
      ),
    );
  }

  Widget _bottomButton(String text, Color color, Widget destinationScreen) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        ),
        onPressed: () {
          Get.to(destinationScreen);
        },
        child: MyText(text: text, color: Colors.white, weight: FontWeight.w500)
    );
  }

  Widget _sectionHeading(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        text,
        style: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.black)),
      ),
    );
  }

  Widget _buildButtonRow(List<Map<String, dynamic>> buttons) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: buttons.map((button) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: button["color"],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              onPressed: () {
                print("Selected: ${button["text"]}");

                // **Navigation Based on Button Text**
                switch (button["text"]) {
                  case "Payment Out":
                    Get.to(() => PaymentOut());
                    break;
                  case "Payment In":
                    Get.to(() => PaymentIn());
                    break;
                  case "Material Purchase":
                    Get.to(() =>());
                    break;
                  case "Other Expense":
                    Get.to(() => ());
                    break;
                  default:
                    print("No route defined");
                }
              },
              child: Text(
                button["text"],
                style: GoogleFonts.dmSans(textStyle:TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.white) ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeading("Payment"),
                _buildButtonRow([
                  {"text": "Payment Out", "color": Colors.red},
                  {"text": "Payment In", "color": Colors.green}
                ]),
                SizedBox(height: 12.h),
                _sectionHeading("Expenses"),
                _buildButtonRow([
                  {"text": "Material Purchase", "color": Colors.purpleAccent},
                  {"text": "Other Expense", "color": Colors.purple}
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}
