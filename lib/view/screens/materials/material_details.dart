import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vetri_hollowblock/view/screens/materials/purchased_screen/purchased_screen.dart';
import 'package:vetri_hollowblock/view/screens/materials/received_screen/received_screen.dart';
import 'package:vetri_hollowblock/view/screens/materials/used_screen.dart';
import 'package:vetri_hollowblock/view/universal_key_api/api_url.dart';
import '../../widgets/text.dart';
import 'package:http/http.dart'as http;

class MaterialScreen extends StatefulWidget {
  const MaterialScreen({super.key,required this.projectName,required this.work});
  final String projectName;
  final String work;

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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    print("Project Name in MaterialScreen: ${widget.projectName}"); // Debugging
    _initializeHive();
    fetchAllData();

  }

  Map<String, double> calculateInventory() {
    final Map<String, double> inventory = {};

    // Add received materials to inventory
    for (var data in receivedMaterialData) {
      final material = data['material_name'];
      final quantity = double.tryParse(data['quantity']?.toString() ?? '0') ?? 0.0;
      if (material != null) {
        inventory[material] = (inventory[material] ?? 0.0) + quantity;
      }
    }

    // Subtract used materials from inventory
    for (var data in usedMaterialData) {
      final material = data['material'];
      final quantity = double.tryParse(data['quantity']?.toString() ?? '0') ?? 0.0;
      if (material != null) {
        inventory[material] = (inventory[material] ?? 0.0) - quantity;
      }
    }

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

  Future<void> fetchAllData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([
        fetchPurchasedData(),
        fetchUsedData(),
        fetchReceivedData(),
      ]);
    } catch (e) {
      print('Error fetching data: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch data. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    setState(() => isLoading = false);
  }
                 /// Purchase Api's method ///
  Future<void> fetchPurchasedData() async {
    try {
      final headers = {
        'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
        'Content-Type': 'application/json',
      };

      // Properly encode the project name for URL
      final encodedProjectName = Uri.encodeComponent(widget.projectName);
      final url = 'https://vetri.regenterp.com/api/method/regent.sales.client.get_mobile_material_purchased?name=$encodedProjectName';

      print('Fetching purchased data from: $url'); // Debug log

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Purchased Response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          purchasedMaterialData = List<Map<String, dynamic>>.from(data['message'] ?? []);
        });
      } else {
        print('Purchased Error Status: ${response.statusCode}'); // Debug log
        throw Exception('Failed to load purchased data');
      }
    } catch (e) {
      print('Error fetching purchased data: $e'); // Debug log
      rethrow;
    }
  }

  Future<void> fetchUsedData() async {
    try {
      final headers = {
        'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
        'Content-Type': 'application/json',
      };

      final encodedProjectName = Uri.encodeComponent(widget.projectName);
      final url = 'https://vetri.regenterp.com/api/method/regent.sales.client.get_mobile_material_used?name=$encodedProjectName';

      print('Fetching used data from: $url'); // Debug log

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Used Response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          usedMaterialData = List<Map<String, dynamic>>.from(data['message'] ?? []);
        });
      } else {
        print('Used Error Status: ${response.statusCode}'); // Debug log
        throw Exception('Failed to load used data');
      }
    } catch (e) {
      print('Error fetching used data: $e'); // Debug log
      rethrow;
    }
  }

  Future<void> fetchReceivedData() async {
    try {
      final headers = {
        'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
        'Content-Type': 'application/json',
      };

      final encodedProjectName = Uri.encodeComponent(widget.projectName);
      final url = 'https://vetri.regenterp.com/api/method/regent.sales.client.get_mobile_material_received?name=$encodedProjectName';

      print('Fetching received data from: $url'); // Debug log

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('Received Response: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          receivedMaterialData = List<Map<String, dynamic>>.from(data['message'] ?? []);
        });
      } else {
        print('Received Error Status: ${response.statusCode}'); // Debug log
        throw Exception('Failed to load received data');
      }
    } catch (e) {
      print('Error fetching received data: $e'); // Debug log
      rethrow;
    }
  }
               /// Update API methods ///
  // First, add these new API methods for updating materials
  Future<void> updatePurchasedMaterial(Map<String, dynamic> data) async {
    try {
      final headers = {
        'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
        'Content-Type': 'application/json',
      };

      final url = '$apiUrl/Material Purchase/${data['name']}';

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          "material": data['material'],
          "quantity": data['quantity'],
          "party_name": data['party_name'],
          "date": data['date'],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        Get.snackbar(
            'Success',
            'Material purchase updated successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM
        );
        await fetchPurchasedData(); // Refresh data
      } else {
        throw Exception('Failed to update purchased material');
      }
    } catch (e) {
      print('Error updating purchased material: $e');
      Get.snackbar(
        'Error',
        'Failed to update material purchase',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
              /// Update Used Material ///
  Future<void> updateUsedMaterial(Map<String, dynamic> data) async {
    try {
      final headers = {
        'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
        'Content-Type': 'application/json',
      };

      final url = '$apiUrl/Material Used/${data['name']}';

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          "material": data['material'],
          "quantity": data['quantity'],
          "date": data['date'],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        Get.snackbar(
            'Success',
            'Material usage updated successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM
        );
        await fetchUsedData(); // Refresh data
      } else {
        throw Exception('Failed to update used material');
      }
    } catch (e) {
      print('Error updating used material: $e');
      Get.snackbar(
        'Error',
        'Failed to update material usage',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
                 /// Updae Received material //
  Future<void> updateReceivedMaterial(Map<String, dynamic> data) async {
    try {
      final headers = {
        'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
        'Content-Type': 'application/json',
      };

      final url = '$apiUrl/Material Received/${data['name']}';

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          "material_name": data['material_name'],
          "quantity": data['quantity'],
          "party_name": data['party_name'],
          "date": data['date'],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        Get.snackbar(
            'Success',
            'Material receipt updated successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM
        );
        await fetchReceivedData(); // Refresh data
      } else {
        throw Exception('Failed to update received material');
      }
    } catch (e) {
      print('Error updating received material: $e');
      Get.snackbar(
        'Error',
        'Failed to update material receipt',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

                  // Delete API methods for Purchased ,Receieved & Used //
  Future<void> deletePurchasedMaterial(String name) async {
    try {
      final headers = {
        'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
        'Content-Type': 'application/json',
      };

      final url = '$apiUrl/Material Purchase/$name';

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        // Remove from local data
        setState(() {
          purchasedMaterialData.removeWhere((item) => item['name'] == name);
        });
        Get.snackbar(
          'Success',
          'Material purchase deleted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM
        );
        await fetchPurchasedData(); // Refresh data
      } else {
        throw Exception('Failed to delete purchased material');
      }
    } catch (e) {
      print('Error deleting purchased material: $e');
      Get.snackbar(
        'Error',
        'Failed to delete material purchase',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteUsedMaterial(String name) async {
    try {
      final headers = {
        'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
        'Content-Type': 'application/json',
      };

      final url = '$apiUrl/Material Used/$name';

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        setState(() {
          usedMaterialData.removeWhere((item) => item['name'] == name);
        });
        Get.snackbar(
          'Success',
          'Material usage record deleted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM
        );
        await fetchUsedData(); // Refresh data
      } else {
        throw Exception('Failed to delete used material');
      }
    } catch (e) {
      print('Error deleting used material: $e');
      Get.snackbar(
        'Error',
        'Failed to delete material usage record',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteReceivedMaterial(String name) async {
    try {
      final headers = {
        'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
        'Content-Type': 'application/json',
      };

      final url = 'https://vetri.regenterp.com/api/resource/Material Received/$name';

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        setState(() {
          receivedMaterialData.removeWhere((item) => item['name'] == name);
        });
        Get.snackbar(
          'Success',
          'Material receipt deleted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM
        );
        await fetchReceivedData(); // Refresh data
      } else {
        throw Exception('Failed to delete received material');
      }
    } catch (e) {
      print('Error deleting received material: $e');
      Get.snackbar(
        'Error',
        'Failed to delete material receipt',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
      backgroundColor: Colors.white,
      body: SizedBox(
        height: height/1.h,
        width: width.w,
        child: Column(
          children: [
            SizedBox(height: 20.h),
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
            if (_selectedIndex == 0) SizedBox(
              height: height/1.7.h,
              width: width/1.w,
                child: _buildInventoryDataContainer()),
            if (_selectedIndex == 1 && purchaseBox.isNotEmpty)
              SizedBox(
                height: height/1.7.h,
                width: width/1.w,
                  child: _buildPurchaseDataContainer()),
            if (_selectedIndex == 2 && usedBox.isNotEmpty)
              SizedBox(
                height: height/1.7.h,
                width: width/1.w,
                  child: _buildUsedDataContainer()),
            if (_selectedIndex == 3 && receivedBox.isNotEmpty)
              SizedBox(
                height: height/1.7.h,
                width: width/1.w,
                  child: _buildReceivedDataContainer()),
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
        width: width / 4.3.w,
        decoration: BoxDecoration(
          color: _selectedIndex == index ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: _selectedIndex == index ? Colors.green : Colors.grey,
          ),
        ),
        child: Center(
          child: Text(text,style: GoogleFonts.figtree(textStyle: TextStyle(fontSize: 13.sp,fontWeight: FontWeight.w700,color: _selectedIndex == index ? Colors.white : Colors.black)
          // MyText(
          //   text: text,
          //   color: _selectedIndex == index ? Colors.white : Colors.black,
          //   weight: FontWeight.w500,
          // ),
        ),
      ),
    )
      )
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

    return Expanded(
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
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (receivedMaterialData.isEmpty) {
      return Center(
        child: Text("No Received Materials",
          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
        ),
      );
    }

    return Expanded(
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
                      MyText(text: "Stock Details", color: Colors.grey, weight: FontWeight.w500),
                      // IconButton(
                      //   icon: Icon(Icons.edit, color: Colors.blue),
                      //   onPressed: () async {
                      //     final result = await Get.to(() => ReceivedScreen(
                      //       material: data,
                      //       projectName: widget.projectName,
                      //       work: widget.work,
                      //       // isEditing: true,
                      //     ));
                      //     if (result != null) {
                      //       await updateReceivedMaterial(result);
                      //     }
                      //   },
                      // ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.grey),
                          onPressed: () {
                            Get.defaultDialog(
                              title: 'Confirm Deletion',
                              titleStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              middleText: 'Are you sure you want to delete this material receipt?',
                              middleTextStyle: TextStyle(fontSize: 16),
                              barrierDismissible: false,
                              radius: 8,
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    Get.back(); // Close the dialog
                                    if (data['name'] != null) {
                                      await deleteReceivedMaterial(data['name'].toString());
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  ),
                                  child: Text('Delete', style: TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                              ],
                            );
                          },

                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  _buildDetailsRow("Material", data['material_name']?.toString()),
                  _buildDetailsRow("Quantity", data['quantity']?.toString()),
                  _buildDetailsRow("Party Name", data['party_name']?.toString()),
                  _buildDetailsRow("Date", data['date']?.toString()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsedDataContainer() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (usedMaterialData.isEmpty) {
      return Center(
        child: Text("No Used Materials",
          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
        ),
      );
    }

    final inventory = calculateInventory();

    return Expanded(
      child: ListView.builder(
        itemCount: usedMaterialData.length,
        itemBuilder: (context, index) {
          final data = usedMaterialData[index];
          final material = data['material'];
          final usedQuantity = double.tryParse(data['quantity']?.toString() ?? '0') ?? 0.0;
          final inventoryQuantity = inventory[material] ?? 0.0;
          final balanceStock = inventoryQuantity;

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
                      // IconButton(
                      //   icon: Icon(Icons.edit, color: Colors.blue),
                      //   onPressed: () async {
                      //     final result = await Get.to(() => UsedScreen(
                      //       material: data,
                      //       projectName: widget.projectName,
                      //       work: widget.work,
                      //       // isEditing: true,
                      //     ));
                      //     if (result != null) {
                      //       await updateUsedMaterial(result);
                      //     }
                      //   },
                      // ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.grey),
                          onPressed: () {
                            Get.defaultDialog(
                              title: 'Confirm Deletion',
                              titleStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              middleText: 'Are you sure you want to delete this material receipt?',
                              middleTextStyle: TextStyle(fontSize: 16),
                              barrierDismissible: false,
                              radius: 8,
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    Get.back(); // Close the dialog
                                    if (data['name'] != null) {
                                      await deleteUsedMaterial(data['name'].toString());
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  ),
                                  child: Text('Delete', style: TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                              ],
                            );
                          },
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  _buildDetailsRow("Material", material?.toString()),
                  _buildDetailsRow("Quantity", usedQuantity.toStringAsFixed(2)),
                  _buildDetailsRow("Balance Stock", balanceStock.toStringAsFixed(2)),
                  _buildDetailsRow("Date", data['date']?.toString()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPurchaseDataContainer() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (purchasedMaterialData.isEmpty) {
      return Center(
        child: Text("No Purchased Materials",
          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: purchasedMaterialData.length,
        itemBuilder: (context, index) {
          final data = purchasedMaterialData[index];
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
                      // IconButton(
                      //   icon: Icon(Icons.edit, color: Colors.blue),
                      //   onPressed: () async {
                      //     final result = await Get.to(() => PurchasedScreen(
                      //       material: data,
                      //       projectName: widget.projectName,
                      //       work: widget.work,
                      //       // isEditing: true,
                      //     ));
                      //     if (result != null) {
                      //       await updatePurchasedMaterial(result);
                      //     }
                      //   },
                      // ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.grey),
                        onPressed: () {
                          Get.defaultDialog(
                            title: 'Confirm Deletion',
                            titleStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            middleText: 'Are you sure you want to delete this material receipt?',
                            middleTextStyle: TextStyle(fontSize: 16),
                            barrierDismissible: false,
                            radius: 8,
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Get.back(); // Close the dialog
                                  if (data['name'] != null) {
                                    await deletePurchasedMaterial(data['name'].toString());
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                ),
                                child: Text('Delete', style: TextStyle(color: Colors.white, fontSize: 16)),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  _buildDetailsRow("Material", data['material']?.toString()),
                  _buildDetailsRow("Quantity", data['quantity']?.toString()),
                  _buildDetailsRow("Party Name", data['party_name']?.toString()),
                  _buildDetailsRow("Date", data['date']?.toString()),
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
              final result = await Get.to(() => PurchasedScreen(material: {}, projectName: widget.projectName, work: widget.work,));
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
              final result = await Get.to(() => UsedScreen(projectName: widget.projectName, work: widget.work,));
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
                final result = await Get.to(() => PurchasedScreen(material: {}, projectName: widget.projectName, work: widget.work,));
                if (result != null) {
                  _addPurchasedData(result);
                }
              }),
              SizedBox(height: 12.h),
              _buildBottomSheetButton(context, "Stock", Colors.blue, () async {
                final result = await Get.to(() => ReceivedScreen(material: {}, projectName: widget.projectName, work: widget.work,));
                if (result != null) {
                  _addReceivedData(result);
                }
              }),
              SizedBox(height: 12.h),
              _buildBottomSheetButton(context, "Used", Colors.green, () async {
                final result = await Get.to(() => UsedScreen(projectName: widget.projectName, work: widget.work,));
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
      width: width / 3.4.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
          color: color),
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

