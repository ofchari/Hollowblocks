import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class DropdownField extends StatefulWidget {
  final String apiUrl;
  final String hintText;
  final TextStyle hintStyle;
  final Function(String?) onChanged;
  final String? selectedValue;
  final IconData? prefixIcon;
  final bool isEnabled;
  final Function onAddNewRoute; // Add new callback for route handling

  const DropdownField({
    super.key,
    required this.apiUrl,
    required this.hintText,
    required this.onChanged,
    this.selectedValue,
    required this.hintStyle,
    this.prefixIcon,
    this.isEnabled = true,
    required this.onAddNewRoute, // Initialize the callback
  });

  @override
  _DropdownFieldState createState() => _DropdownFieldState();
}

class _DropdownFieldState extends State<DropdownField> {
  late double height;
  late double width;
  List<String> options = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(widget.apiUrl),
        headers: {
          'Authorization': 'token f1178cbff3f9a07:f1d2a24b5a005b7',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          options = List<String>.from(data['data'].map((item) => item['name'].toString()));
          isLoading = false;
        });
      } else {
        print("Failed to fetch data for ${widget.hintText}: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data for ${widget.hintText}: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    height = size.height.h;
    width = size.width.w;

    return Container(
      height: height / 15.2.h,
      width: width / 1.09.w,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.grey.shade500),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : Row(
        children: [
          if (widget.prefixIcon != null)
            Icon(
              widget.prefixIcon,
              color: Colors.grey.shade600,
            ),
          SizedBox(width: 10.w),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: widget.selectedValue,
              items: [
                ...options.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: GoogleFonts.dmSans(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                DropdownMenuItem(
                  value: "add_new", // Special value to trigger Add New route
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Colors.blue),
                      SizedBox(width: 10.w),
                      Text(
                        "Add New",
                        style: TextStyle(fontSize: 15.sp, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == "add_new") {
                  widget.onAddNewRoute(); // Call the route callback
                } else {
                  widget.onChanged(value); // Call the original onChanged
                }
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: widget.hintStyle,
              ),
              style: widget.hintStyle,
              icon: SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

