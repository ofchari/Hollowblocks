import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
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
  late Box receivedBox;
  late Box usedBox;
  List<Map<String, dynamic>> receivedMaterialData = []; // Store list of received materials
  List<Map<String, dynamic>> usedMaterialData = []; // Store list of used materials

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Map<String, double> calculateInventory() {
    Map<String, double> inventory = {};

    // Calculate received quantities
    for (int i = 0; i < receivedBox.length; i++) {
      final data = Map<String, dynamic>.from(receivedBox.getAt(i) as Map);
      final material = data['material_name'] as String;
      final quantity = double.tryParse(data['quantity'].toString()) ?? 0.0;

      inventory[material] = (inventory[material] ?? 0) + quantity;
    }

    // Subtract used quantities
    for (int i = 0; i < usedBox.length; i++) {
      final data = Map<String, dynamic>.from(usedBox.getAt(i) as Map);
      final material = data['material'] as String;
      final quantity = double.tryParse(data['quantity'].toString()) ?? 0.0;

      inventory[material] = (inventory[material] ?? 0) - quantity;
    }

    // Remove materials with zero or negative inventory
    inventory.removeWhere((key, value) => value <= 0);

    return inventory;
  }





  Future<void> _initializeHive() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    // Open the boxes asynchronously
    receivedBox = await Hive.openBox('receivedMaterialData');
    usedBox = await Hive.openBox('usedMaterialData');

    // After initialization, rebuild the UI if necessary
    setState(() {});

    // Now, it's safe to access receivedBox and usedBox
    if (Get.arguments != null) {
      final args = Get.arguments as Map<String, dynamic>;
      if (args.containsKey('used')) {
        _addUsedData(args['used']);
        _selectedIndex = 2;
      } else if (args.containsKey('received')) {
        _addReceivedData(args['received']);
        _selectedIndex = 1;
      }
    }
  }

  void _addReceivedData(Map<String, dynamic> data) {
    receivedBox.add(Map<String, dynamic>.from(data)); // Explicit conversion
    setState(() {});
  }

  void _addUsedData(Map<String, dynamic> data) {
    usedBox.add(Map<String, dynamic>.from(data)); // Explicit conversion
    setState(() {});
  }


  Future<void> _clearAllData() async {
    await receivedBox.clear();
    await usedBox.clear();
    setState(() {});
  }

  Future<void> _deleteData(Box box, int index) async {
    await box.deleteAt(index);
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
        width: width.w,
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
            if (_selectedIndex == 0) Expanded(child: _buildInventoryDataContainer()),
            if (_selectedIndex == 1 && receivedBox.isNotEmpty)
              Expanded(child: _buildReceivedDataContainer()),
            if (_selectedIndex == 2 && usedBox.isNotEmpty)
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

  Widget _buildInventoryDataContainer() {
    final inventory = calculateInventory();

    if (inventory.isEmpty) {
      return Center(
        child: Text(
          "No Inventory Data",
          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        itemCount: inventory.length,
        itemBuilder: (context, index) {
          final material = inventory.keys.elementAt(index);
          final quantity = inventory[material];

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
                      MyText(
                        text: "Material: $material",
                        color: Colors.grey,
                        weight: FontWeight.w500,
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  _buildDetailsRow("Quantity", quantity?.toStringAsFixed(2)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildReceivedDataContainer() {
    if (receivedBox.isEmpty) {
      return Center(
        child: Text(
          "No Received Materials",
          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        itemCount: receivedBox.length,
        itemBuilder: (context, index) {
          final data = Map<String, dynamic>.from(receivedBox.getAt(index) as Map);
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
                        onPressed: () => _deleteData(receivedBox, index),
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
    if (usedBox.isEmpty) {
      return Center(
        child: Text(
          "No Used Materials",
          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        itemCount: usedBox.length,
        itemBuilder: (context, index) {
          // final data = usedBox.getAt(index) as Map<String, dynamic>;
          final data = Map<String, dynamic>.from(usedBox.getAt(index) as Map);
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
                        onPressed: () => _deleteData(usedBox, index),
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
                _addReceivedData(result);
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
                _addUsedData(result);
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
                final result = await Get.to(() => ReceivedScreen(material: {}));
                if (result != null) {
                  _addReceivedData(result);
                }
              }),
              SizedBox(height: 12.h),
              _buildBottomSheetButton(context, "Used", Colors.green, () async {
                final result = await Get.to(() => UsedScreen());
                if (result != null) {
                  _addUsedData(result);
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

