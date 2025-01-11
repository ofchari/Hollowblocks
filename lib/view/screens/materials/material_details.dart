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
  List<Map<String, dynamic>> receivedMaterialData = []; // Store list of received materials
  List<Map<String, dynamic>> usedMaterialData = []; // Store list of used materials

  @override
  void initState() {
    super.initState();
    _loadStoredData();
    print("Received Data: $receivedMaterialData");
    print("Used Data: $usedMaterialData");
    if (Get.arguments != null) {
      final args = Get.arguments as Map<String, dynamic>;
      if (args.containsKey('used')) {
        setState(() {
          usedMaterialData.add(args['used']);
          _saveData('usedMaterialData', usedMaterialData);
          _selectedIndex = 2;
        });
      } else if (args.containsKey('received')) {
        setState(() {
          receivedMaterialData.add(args['received']);
          _saveData('receivedMaterialData', receivedMaterialData);
          _selectedIndex = 1;
        });
      }
    }
  }


  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    final receivedData = prefs.getString('receivedMaterialData');
    final usedData = prefs.getString('usedMaterialData');

    print("Raw Received Data from SharedPreferences: $receivedData");
    print("Raw Used Data from SharedPreferences: $usedData");

    if (receivedData != null) {
      try {
        receivedMaterialData = List<Map<String, dynamic>>.from(json.decode(receivedData));
        print("Parsed Received Data: $receivedMaterialData");
      } catch (e) {
        print("Error Parsing Received Data: $e");
      }
    }

    if (usedData != null) {
      try {
        usedMaterialData = List<Map<String, dynamic>>.from(json.decode(usedData));
        print("Parsed Used Data: $usedMaterialData");
      } catch (e) {
        print("Error Parsing Used Data: $e");
      }
    }

    setState(() {}); // Trigger UI rebuild
  }



  Future<void> _saveData(String key, List<Map<String, dynamic>> newData) async {
    final prefs = await SharedPreferences.getInstance();

    // Load the existing data
    final existingDataString = prefs.getString(key);
    List<Map<String, dynamic>> existingData = [];
    if (existingDataString != null) {
      try {
        existingData = List<Map<String, dynamic>>.from(json.decode(existingDataString));
      } catch (e) {
        print("Error decoding existing $key: $e");
      }
    }

    // Append new data
    existingData.addAll(newData);

    // Save updated data back to SharedPreferences
    await prefs.setString(key, json.encode(existingData));
    print("Saved $key to SharedPreferences: ${json.encode(existingData)}");

    // Update local state
    if (key == 'receivedMaterialData') {
      receivedMaterialData = existingData;
    } else if (key == 'usedMaterialData') {
      usedMaterialData = existingData;
    }

    setState(() {}); // Trigger UI rebuild
  }


  Future<void> _clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("All SharedPreferences Data Cleared.");
  }


  Future<void> _deleteData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    if (key == 'receivedMaterialData') {
      receivedMaterialData.clear();
    } else if (key == 'usedMaterialData') {
      usedMaterialData.clear();
    }
    setState(() {});
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
      body: SizedBox(
        width : width.w,
        child: Column(
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
            if (_selectedIndex == 1 && receivedMaterialData.isNotEmpty)
              Expanded(child: _buildReceivedDataContainer()),
            if (_selectedIndex == 2 && usedMaterialData.isNotEmpty)
              Expanded(child: _buildUsedDataContainer()),
            const Spacer(),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildContainer(int index, String text) {
    return GestureDetector(
      onTap: () {
        _selectedIndex = _selectedIndex == index ? -1 : index;
        setState(() {});
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
    if (receivedMaterialData.isEmpty) {
      return Center(
        child: Text(
          "No Received Materials",
          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        itemCount: receivedMaterialData.length,
        itemBuilder: (context, index) {
          final data = receivedMaterialData[index];
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MyText(text: "Received Details", color: Colors.grey, weight: FontWeight.w500),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            receivedMaterialData.removeAt(index);
                            _saveData('receivedMaterialData', receivedMaterialData);
                          });
                        },
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  _buildDetailsRow("Material", data['material_name']),
                  _buildDetailsRow("Quantity", data['quantity']?.toString()),
                  _buildDetailsRow("Party", data['party_name']),
                  _buildDetailsRow("Date", data['date']),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildUsedDataContainer() {
    if (usedMaterialData.isEmpty) {
      return Center(
        child: Text(
          "No Used Materials",
          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        itemCount: usedMaterialData.length,
        itemBuilder: (context, index) {
          final data = usedMaterialData[index];
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MyText(text: "Material Used Details", color: Colors.grey, weight: FontWeight.w500),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            usedMaterialData.removeAt(index);
                            _saveData('usedMaterialData', usedMaterialData);
                          });
                        },
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  _buildDetailsRow("Material", data['material']),
                  _buildDetailsRow("Quantity", data['quantity']?.toString()),
                  _buildDetailsRow("Date", data['date']),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildDetailsRow(String label, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$label:",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.5.sp,
            color: Colors.black87,
          ),
        ),
        Text(
          value ?? "",
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () async {
              final result = await Get.to(() => ReceivedScreen(material: {}));
              if (result != null && result is Map<String, dynamic>) {
                receivedMaterialData.add(result);
                _saveData('receivedMaterialData', receivedMaterialData);
              }
            },
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
            onTap: () async {
              final result = await Get.to(() => UsedScreen());
              if (result != null && result is Map<String, dynamic>) {
                usedMaterialData.add(result);
                _saveData('usedMaterialData', usedMaterialData);
              }
            },
            child: _buildActionButton("Used", Colors.brown),
          ),
        ],
      ),
    );
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
              SizedBox(height: 12.h),
              _buildBottomSheetButton(context, "Received", Colors.blue, () async {
                // Navigate to the ReceivedScreen and wait for the result
                final result = await Get.to(() => ReceivedScreen(material: {}));
                if (result != null) {
                  // Update the receivedMaterialData if new data is returned
                  setState(() {
                    receivedMaterialData = result;
                  });
                  // Save the updated data to SharedPreferences
                  await _saveData('receivedMaterialData', receivedMaterialData!);
                }
              }),
              SizedBox(height: 12.h),
              _buildBottomSheetButton(context, "Used", Colors.green, () async {
                // Navigate to the UsedScreen
                final result = await Get.to(() => UsedScreen());
                if (result != null) {
                  // Update usedMaterialData if new data is returned
                  setState(() {
                    usedMaterialData = result;
                  });
                  // Save the updated data to SharedPreferences
                  await _saveData('usedMaterialData', usedMaterialData!);
                }
              }),
            ],
          ),
        );
      },
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
Widget _buildBottomSheetButton(BuildContext context, String text, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: () {
      Navigator.pop(context); // Close the BottomSheet
      onTap(); // Perform the action
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