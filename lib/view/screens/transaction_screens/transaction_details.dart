import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../universal_key_api/api_url.dart';
import 'payment_in.dart';  // Assuming you have these screens defined elsewhere
import 'payment_out.dart';

class TransactionDetails extends StatefulWidget {
  const TransactionDetails({super.key, required this.projectName,required this.work});
  final String projectName;
  final String work;

  @override
  State<TransactionDetails> createState() => _TransactionDetailsState();
}

class _TransactionDetailsState extends State<TransactionDetails> {
  late double height;
  List<dynamic> paymentInList = [];
  List<dynamic> paymentOutList = [];

  late double width;

  // Totals and balance
  double totalIn = 0.0;
  double totalOut = 0.0;
  double balance = 0.0;
  bool isDataLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPaymentData();
  }

  /// Fetch Payment In and Payment Out data and calculate totals and balance.
  Future<void> fetchPaymentData() async {
    setState(() {
      isDataLoading = true;
    });

    final String paymentInUrl =
        "https://vetri.regenterp.com/api/method/regent.sales.client.get_mobile_payment_in?name=${widget.projectName}";
    final String paymentOutUrl =
        "https://vetri.regenterp.com/api/method/regent.sales.client.get_mobile_payment_out?name=${widget.projectName}";

    try {
      final inResponse = await http.get(
        Uri.parse(paymentInUrl),
        headers: {
          "Authorization": "token $apiKey",
          "Content-Type": "application/json",
        },
      );

      final outResponse = await http.get(
        Uri.parse(paymentOutUrl),
        headers: {
          "Authorization": "token $apiKey",
          "Content-Type": "application/json",
        },
      );

      print("Payment In Response: ${inResponse.body}");
      print("Payment Out Response: ${outResponse.body}");

      if (inResponse.statusCode == 200 && outResponse.statusCode == 200) {
        final inData = json.decode(inResponse.body);
        final outData = json.decode(outResponse.body);

        // ✅ Fix: Access 'message' instead of 'data'
        List<dynamic> inList = (inData['message'] ?? []) as List<dynamic>;
        List<dynamic> outList = (outData['message'] ?? []) as List<dynamic>;

        double sumIn = 0.0;
        for (var item in inList) {
          double amount = double.tryParse(item['amount_rec'].toString()) ?? 0;
          sumIn += amount;
        }

        double sumOut = 0.0;
        for (var item in outList) {
          double amount = double.tryParse(item['amount_rec'].toString()) ?? 0;
          sumOut += amount;
        }

        setState(() {
          totalIn = sumIn;
          totalOut = sumOut;
          balance = totalIn - totalOut;
          paymentInList = inList;  // ✅ Store Payment In Data
          paymentOutList = outList; // ✅ Store Payment Out Data
        });


        print("Total In: $totalIn");
        print("Total Out: $totalOut");
        print("Balance: $balance");
      } else {
        print("Failed to fetch payment data. Status codes: ${inResponse.statusCode}, ${outResponse.statusCode}");
      }
    } catch (e) {
      print("Error fetching payment data: $e");
    } finally {
      setState(() {
        isDataLoading = false;
      });
    }
  }
              /// Delete method Api //
  Future<void> _deleteTransaction(String transactionId, bool isPaymentIn) async {
    final String type = isPaymentIn ? "Payment%20In" : "Payment%20Out"; // Encode space properly
    final String deleteUrl = "https://vetri.regenterp.com/api/resource/$type/$transactionId";
    print("Api "+deleteUrl);

    try {
      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: {
          "Authorization": "token $apiKey",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 202) {
        print("Transaction deleted successfully");
        // Show success message using GetX Snackbar
        Get.snackbar(
          "Success",
          "Transaction deleted successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
        setState(() {
          if (isPaymentIn) {
            paymentInList.removeWhere((item) => item['name'] == transactionId);
          } else {
            paymentOutList.removeWhere((item) => item['name'] == transactionId);
          }
        });
      } else {
        print("Failed to delete transaction: ${response.body}");
      }
      print(response.statusCode);
    } catch (e) {
      print("Error deleting transaction: $e");
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
      // Display the summary card at the top of the body.
      body: Column(
        children: [
          isDataLoading
              ? Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _buildSummaryCard(),
          Expanded(
            child: _buildTransactionDetails(),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _bottomButton("Payment In", Colors.green, PaymentIn(projectName : widget.projectName, work: widget.work,)),
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
            _bottomButton("Payment Out", Colors.red, PaymentOut(projectName : widget.projectName, work: widget.work,)),
          ],
        ),
      ),
    );
  }

              /// Builds the summary card showing Balance, Total In, and Total Out ///.

  Widget _buildSummaryCard() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          /// Balance Column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Balance",
                style: GoogleFonts.dmSans(
                  textStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "${balance >= 0 ? '+' : '-'} ${balance.abs().toStringAsFixed(2)}",
                style: GoogleFonts.outfit(
                  textStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),

          /// Total In Column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Total In",
                style: GoogleFonts.dmSans(
                  textStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                totalIn.toStringAsFixed(2),
                style: GoogleFonts.outfit(
                  textStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),

          /// Total Out Column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Total Out",
                style: GoogleFonts.dmSans(
                  textStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                totalOut.toStringAsFixed(2),
                style: GoogleFonts.outfit(
                  textStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (paymentInList.isNotEmpty) _transactionSection("Payment In", paymentInList, true),
            if (paymentOutList.isNotEmpty) _transactionSection("Payment Out", paymentOutList, false),
          ],
        ),
      ),
    );
  }

  Widget _transactionSection(String title, List<dynamic> transactions, bool isPaymentIn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Text(
            title,
            style: GoogleFonts.dmSans(
              textStyle: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            var transaction = transactions[index];
            return _buildTransactionCard(transaction, isPaymentIn);
          },
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, bool isPaymentIn) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _transactionDetailRow(
            title: isPaymentIn ? "From" : "To",
            value: transaction[isPaymentIn ? 'from_party' : 'to_party'] ?? "-",
            icon: Icons.person,
          ),
          SizedBox(height: 6.h),
          _transactionDetailRow(
            title: "Amount",
            value: "₹${transaction['amount_rec'].toStringAsFixed(2)}",
            icon: Icons.currency_rupee,
            valueColor: isPaymentIn ? Colors.green : Colors.red,
          ),
          SizedBox(height: 6.h),
          _transactionDetailRow(
            title: "Date",
            value: transaction['date'] ?? "-",
            icon: Icons.calendar_today,
          ),
          if (transaction['description'] != null && transaction['description'].toString().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: _transactionDetailRow(
                title: "Description",
                value: transaction['description'],
                icon: Icons.description,
                isMultiline: true,
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                print("Delete button clicked for: ${transaction['name']}");

                // if (transaction['name'] == null) {
                //   print("Transaction data: $transaction");  // Print full transaction
                //   print("Transaction ID is null! Check your data.");
                // } else {
                //   String apiUrl = "https://vetri.regenterp.com/api/resource/"
                //       "${isPaymentIn ? "Payment%20In" : "Payment%20Out"}/${transaction['name']}";
                //   print("API URL: $apiUrl");

                  _deleteTransaction(transaction['name'], isPaymentIn);
                // }
              },


            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionDetailRow({
    required String title,
    required String value,
    required IconData icon,
    Color valueColor = Colors.black87,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18.sp, color: Colors.grey),
        SizedBox(width: 8.w),
        Text(
          "$title:",
          style: GoogleFonts.dmSans(
            textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black),
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.dmSans(
              textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: valueColor),
            ),
            maxLines: isMultiline ? null : 1,
            overflow: isMultiline ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }



  Widget _bottomButton(String text, Color color, Widget destinationScreen) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      ),
      onPressed: () {
        Get.to(destinationScreen);
      },
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ),
    );
  }

  Widget _sectionHeading(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          textStyle: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.black),
        ),
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
            child: Container(
              decoration: BoxDecoration(
                gradient: getGradient(button["text"]),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                onPressed: () {
                  print("Selected: ${button["text"]}");
                  // Navigation Based on Button Text
                  switch (button["text"]) {
                    case "Payment Out":
                      Get.to(() => PaymentOut(projectName: widget.projectName, work: widget.work,));
                      break;
                    case "Payment In":
                      Get.to(() => PaymentIn(projectName: widget.projectName, work: widget.work,));
                      break;
                    case "Material Purchase":
                    // Replace with the correct screen
                      Get.to(() => Container());
                      break;
                    case "Other Expense":
                    // Replace with the correct screen
                      Get.to(() => Container());
                      break;
                    default:
                      print("No route defined");
                  }
                },
                child: Text(
                  button["text"],
                  style: GoogleFonts.dmSans(
                    textStyle: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Helper function to get gradient based on button type.
  LinearGradient getGradient(String buttonText) {
    switch (buttonText) {
      case "Payment Out":
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade300,
            Colors.red.shade500,
          ],
        );
      case "Payment In":
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
        );
      case "Material Purchase":
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purpleAccent.shade200,
            Colors.purpleAccent.shade400,
          ],
        );
      case "Other Expense":
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade200,
            Colors.purple.shade400,
          ],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade400,
            Colors.grey.shade600,
          ],
        );
    }
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
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeading("Payment"),
                _buildButtonRow([
                  {"text": "Payment Out"},
                  {"text": "Payment In"}
                ]),
                SizedBox(height: 12.h),
                _sectionHeading("Expenses"),
                _buildButtonRow([
                  {"text": "Material Purchase"},
                  {"text": "Other Expense"}
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}
