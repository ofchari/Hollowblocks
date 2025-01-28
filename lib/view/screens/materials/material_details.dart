import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vetri_hollowblock/view/screens/materials/purchased_screen/purchased_screen.dart';
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
  late Box purchaseBox;
  List<Map<String, dynamic>> receivedMaterialData = []; // Store list of received materials
  List<Map<String, dynamic>> usedMaterialData = []; // Store list of used materials
  List<Map<String, dynamic>> purchasedMaterialData = []; // Store list of used materials

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Map<String, double> calculateInventory() {
    final Map<String, double> inventory = {};

    // Iterate over the purchased materials and add them to inventory
    for (int i = 0; i < purchaseBox.length; i++) {
      final data = Map<String, dynamic>.from(purchaseBox.getAt(i) as Map);
      final material = data['material'];
      final quantity = double.tryParse(data['quantity']?.toString() ?? '0') ?? 0.0;

      if (material != null) {
        inventory[material] = (inventory[material] ?? 0.0) + quantity;
      }
    }

    // Subtract used materials from the inventory
    for (int i = 0; i < usedBox.length; i++) {
      final data = Map<String, dynamic>.from(usedBox.getAt(i) as Map);
      final material = data['material'];
      final quantity = double.tryParse(data['quantity']?.toString() ?? '0') ?? 0.0;

      if (material != null) {
        inventory[material] = (inventory[material] ?? 0.0) - quantity;
      }
    }

    // Remove materials with zero or negative quantities
    inventory.removeWhere((key, value) => value <= 0);

    return inventory;
  }


  Future<void> _initializeHive() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    // Open the boxes asynchronously
    receivedBox = await Hive.openBox('receivedMaterialData');
    usedBox = await Hive.openBox('usedMaterialData');
    purchaseBox = await Hive.openBox('purchasedMaterialData');

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
        _selectedIndex = 3;
      } else if (args.containsKey('purchased')) {
        _addPurchasedData(args['purchased']);
        _selectedIndex = 1;
      }
    }
  }

  void _addUsedData(Map<String, dynamic> data) {
    // Check if the data already exists in the box
    final existingData = usedBox.values.where((entry) {
      return Map<String, dynamic>.from(entry)['material'] == data['material'] &&
          Map<String, dynamic>.from(entry)['date'] == data['date'];
    }).toList();

    // Add only if it doesn't exist
    if (existingData.isEmpty) {
      usedBox.add(Map<String, dynamic>.from(data));
      setState(() {});
    }
  }

  void _addReceivedData(Map<String, dynamic> data) {
    final existingData = receivedBox.values.where((entry) {
      return Map<String, dynamic>.from(entry)['material_name'] == data['material_name'] &&
          Map<String, dynamic>.from(entry)['date'] == data['date'];
    }).toList();

    if (existingData.isEmpty) {
      receivedBox.add(Map<String, dynamic>.from(data));
      setState(() {});
    }
  }

  void _addPurchasedData(Map<String, dynamic> data) {
    final existingData = purchaseBox.values.where((entry) {
      return Map<String, dynamic>.from(entry)['material'] == data['material'] &&
          Map<String, dynamic>.from(entry)['date'] == data['date'];
    }).toList();

    if (existingData.isEmpty) {
      purchaseBox.add(Map<String, dynamic>.from(data));
      setState(() {});
    }
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
        automaticallyImplyLeading: false,
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
                    _buildContainer(1, "Purchase"),
                    SizedBox(width: 5.w),
                    _buildContainer(2, "Used"),
                    SizedBox(width: 5.w),
                    _buildContainer(3, "Stock"),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            if (_selectedIndex == 0) Expanded(child: _buildInventoryDataContainer()),
            if (_selectedIndex == 1 && purchaseBox.isNotEmpty)
              Expanded(child: _buildPurchaseDataContainer()),
            if (_selectedIndex == 2 && usedBox.isNotEmpty)
              Expanded(child: _buildUsedDataContainer()),
            if (_selectedIndex == 3 && receivedBox.isNotEmpty)
              Expanded(child: _buildReceivedDataContainer()),
            SizedBox(height: 50.h,),

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

    return Container(
      height: height/1.h,
      width: width/1.w,
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
                        color: Colors.black,
                        weight: FontWeight.w600,
                      ),
                      MyText(
                        text: "In Stock",
                        color: Colors.black,
                        weight: FontWeight.w600,
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
                      MyText(text: "Stock Details", color: Colors.grey, weight: FontWeight.w500),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteData(receivedBox, index),
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  _buildDetailsRow("Material", data['material_name']),
                  _buildDetailsRow("Quantity", data['quantity']?.toString()),
                  _buildDetailsRow("Party_Name", data['party_name']),
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
    final inventory = calculateInventory(); // Fetch the inventory data

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
          // Fetch used material data
          final data = Map<String, dynamic>.from(usedBox.getAt(index) as Map);

          final material = data['material']; // Material name
          final usedQuantity = double.tryParse(data['quantity']?.toString() ?? '0') ?? 0.0; // Used quantity

          // Validate if material has been purchased
          final isPurchased = purchaseBox.values.any((entry) {
            final purchaseData = Map<String, dynamic>.from(entry as Map);
            return purchaseData['material'] == material;
          });

          if (!isPurchased) {
            // Show Snackbar for error
            Future.microtask(() {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Material '$material' is not purchased. Please purchase it before using.",
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            });

            // Skip rendering this item
            return SizedBox.shrink();
          }

          // Get inventory quantity for the material
          final inventoryQuantity = inventory[material] ?? 0.0;

          // Calculate balance stock
          final balanceStock = inventoryQuantity - usedQuantity;

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
                        text: "Material Used Details",
                        color: Colors.grey,
                        weight: FontWeight.w500,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteData(usedBox, index),
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  _buildDetailsRow("Material", material),
                  _buildDetailsRow("Quantity", usedQuantity.toStringAsFixed(2)),
                  _buildDetailsRow("Balance Stock", balanceStock.toStringAsFixed(2)), // Display calculated balance
                  _buildDetailsRow("Date", data['date']),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildPurchaseDataContainer() {
    if (purchaseBox.isEmpty) {
      return Center(
        child: Text(
          "No Purchased Materials",
          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        itemCount: purchaseBox.length,
        itemBuilder: (context, index) {
          // final data = usedBox.getAt(index) as Map<String, dynamic>;
          final data = Map<String, dynamic>.from(purchaseBox.getAt(index) as Map);
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
                      MyText(text: "Material Purchase Details", color: Colors.grey, weight: FontWeight.w500),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteData(purchaseBox, index),
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  _buildDetailsRow("Material", data['material']),
                  _buildDetailsRow("Quantity", data['quantity']?.toString()),
                  _buildDetailsRow("Party Name", data['party_name']?.toString()),
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
            fontWeight: FontWeight.w600
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
              final result = await Get.to(() => PurchasedScreen(material: {},));
              if (result != null && result is Map<String, dynamic>) {
                _addPurchasedData(result);
              }
            },
            child: _buildActionButton("Purchase", Colors.deepPurple.shade500),
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
              _buildBottomSheetButton(context, "Purchase", Colors.pink, () async {
                final result = await Get.to(() => PurchasedScreen(material: {},));
                if (result != null) {
                  _addPurchasedData(result);
                }
              }),
              SizedBox(height: 12.h),
              _buildBottomSheetButton(context, "Stock", Colors.blue, () async {
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

