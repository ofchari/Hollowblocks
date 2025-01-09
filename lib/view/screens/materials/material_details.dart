import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetri_hollowblock/view/screens/materials/purchased_screen.dart';
import 'package:vetri_hollowblock/view/screens/materials/received_screen/received_screen.dart';
import 'package:vetri_hollowblock/view/screens/materials/used_screen.dart';

import '../../widgets/subhead.dart';
import '../../widgets/text.dart';

class MaterialScreen extends StatefulWidget {
  const MaterialScreen({super.key});



  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  late double height;
  late double width;

  int _selectedIndex = -1; // Track the selected container index (-1 means none)
  Map<String, dynamic>? receivedMaterialData; // To store received material data
  Map<String, dynamic>? usedMaterialData; // To store received material data


  @override
  void initState() {
    super.initState();
    // _loadStoredData();
    // Check if arguments are passed and assign them correctly
    if (Get.arguments != null) {
      final args = Get.arguments as Map<String, dynamic>;
      if (args.containsKey('used')) {
        usedMaterialData = args['used'];
        _selectedIndex = 2; // Automatically select "Used" tab
        // _saveData('usedMaterialData', usedMaterialData!);
      } else if (args.containsKey('received')) {
        receivedMaterialData = args['received'];
        _selectedIndex = 1; // Automatically select "Received" tab
        // _saveData('receivedMaterialData', receivedMaterialData!);
      }
    }
  }

  // Future<void> _saveData(String key, Map<String, dynamic> data) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString(key, jsonEncode(data));
  // }

  // Future<void> _loadStoredData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     receivedMaterialData = prefs.getString('receivedMaterialData') != null
  //         ? jsonDecode(prefs.getString('receivedMaterialData')!)
  //         : null;
  //     usedMaterialData = prefs.getString('usedMaterialData') != null
  //         ? jsonDecode(prefs.getString('usedMaterialData')!)
  //         : null;
  //   });
  // }

  //
  // Future<void> _deleteData(String key) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove(key);
  //   setState(() {
  //     if (key == 'receivedMaterialData') receivedMaterialData = null;
  //     if (key == 'usedMaterialData') usedMaterialData = null;
  //   });
  // }


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
      backgroundColor: const Color(0xfff1f2f4),
      appBar: AppBar(
        backgroundColor: const Color(0xfff1f2f4),
        toolbarHeight: 80.h,
        centerTitle: true,
        title: Subhead(
          text: "Material",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
      ),
      body: Column(
        children: [
          // Horizontal menu
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildContainer(0, "Inventory"),
                  SizedBox(width: 5.w),
                  _buildContainer(1, "Received"),
                  SizedBox(width: 5.w),
                  _buildContainer(2, "Used"),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          // Display received data if selected
          if (_selectedIndex == 1 && receivedMaterialData != null)
            _buildReceivedDataContainer(),
          if (_selectedIndex == 2 && usedMaterialData != null)
            _buildUsedDataContainer(),
          const Spacer(),
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildContainer(int index, String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          // Toggle between selected and unselected states
          _selectedIndex = _selectedIndex == index ? -1 : index;
        });
      },
      child: Container(
        height: height / 17.h,
        width: width / 3.5.w,
        decoration: BoxDecoration(
          color: _selectedIndex == index ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: _selectedIndex == index ? Colors.green : Colors.grey,
          ),
        ),
        child: Center(
          child: MyText(
            text: text,
            color: _selectedIndex == index ? Colors.white : Colors.black,
            weight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedDataContainer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText(text: "Received Details", color: Colors.grey, weight: FontWeight.w500),
                // IconButton(
                //   icon: Icon(Icons.delete, color: Colors.red),
                //   onPressed: () => _deleteData('receivedMaterialData'),
                // ),
              ],
            ),
            Divider(color: Colors.grey.shade300, thickness: 1),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Material:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5.sp,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  receivedMaterialData!['material_name'] ?? "",
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quantity:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5.sp,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  receivedMaterialData!['quantity']?.toString() ?? "",
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Party:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5.sp,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  receivedMaterialData!['party_name'] ?? "",
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Date:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5.sp,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  receivedMaterialData!['date'] ?? "",
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsedDataContainer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyText(text: "Material Used Details", color: Colors.grey, weight: FontWeight.w500),
                // IconButton(
                //   icon: Icon(Icons.delete, color: Colors.red),
                //   onPressed: () => _deleteData('usedMaterialData'),
                // ),
              ],
            ),
            Divider(color: Colors.grey.shade300, thickness: 1),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Material:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5.sp,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  usedMaterialData?['material']?.toString() ?? "",
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Quantity:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5.sp,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  usedMaterialData?['quantity']?.toString() ?? "",
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Date:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5.sp,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  usedMaterialData?['date']?.toString() ?? "",
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBottomActionBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.to(ReceivedScreen(material: {})),
            child: _buildActionButton("Received", Colors.deepPurple.shade500),
          ),

          GestureDetector(
            onTap: () => _showMaterialBottomSheet(context),
            child: Container(
              height: height / 13.h,
              width: width / 3.w,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
          GestureDetector(
            onTap: () => Get.to(UsedScreen()),
            child: _buildActionButton("Used", Colors.brown),
          ),

        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color) {
    return Container(
      height: height / 17.h,
      width: width / 3.5.w,
      decoration: BoxDecoration(color: color),
      child: Center(
        child: MyText(
          text: text,
          color: Colors.white,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}

void _showMaterialBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    backgroundColor: Colors.white,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.all(16.0.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: MyText(
                text: "Material",
                color: Colors.black,
                weight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            // _buildBottomSheetButton(context, "Inventory", Colors.brown, () {
            //   Get.to(InventoryScreen());
            // }),
            SizedBox(height: 12.h),
            _buildBottomSheetButton(context, "Received", Colors.blue, () {
              Get.to(ReceivedScreen(material: {}));
            }),
            SizedBox(height: 12.h),
            _buildBottomSheetButton(context, "Used", Colors.green, () {
              Get.to(UsedScreen());
            }),
          ],
        ),
      );
    },
  );
}

Widget _buildBottomSheetButton(
    BuildContext context, String text, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: () {
      Navigator.pop(context); // Close the BottomSheet
      onTap();
    },
    child: Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: MyText(
          text: text,
          color: Colors.white,
          weight: FontWeight.w500,
        ),
      ),
    ),
  );
}
