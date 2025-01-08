import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vetri_hollowblock/view/screens/materials/inventory_screen.dart';
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

  // Track the selected container index
  int _selectedIndex = -1;  // -1 means none selected

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
          return Text("Please make sure your device is in portrait view");
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildContainer(0, "Inventory"),
                    SizedBox(width: 5.w,),
                    _buildContainer(1, "Request"),
                    SizedBox(width: 5.w,),
                    _buildContainer(2, "Received"),
                    SizedBox(width: 5.w,),
                    _buildContainer(3, "Used"),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h,),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Padding(
                padding:  EdgeInsets.only(bottom: 8.0.h),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: (){
                        Get.to(InventoryScreen());
                      },
                      child: Container(
                        height: height / 17.h,
                        width: width / 3.5.w,
                        decoration: BoxDecoration(
                          color: Colors.brown

                        ),
                        child: Center(
                          child: MyText(
                            text: "Inventory",
                            color: Colors.white,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: (){
                        _showMaterialBottomSheet(context);
                      },
                      child: Container(
                        height: height/13.h,
                        width: width/3.w,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle
                        ),
                        child: Icon(Icons.add,color: Colors.white,),
                      ),
                    ),
                    GestureDetector(
                      onTap: (){
                        Get.to(ReceivedScreen());
                      },
                      child: Container(
                        height: height / 17.h,
                        width: width / 3.5.w,
                        decoration: BoxDecoration(
                            color: Colors.deepPurple.shade500

                        ),
                        child: Center(
                          child: MyText(
                            text: "Received",
                            color: Colors.white,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom method to build each container
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
          color: _selectedIndex == index ? Colors.blue : Colors.white, // Change color when selected
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: _selectedIndex == index ? Colors.green : Colors.grey, // Border color when selected
          ),
        ),
        child: Center(
          child: MyText(
            text: text,
            color: _selectedIndex == index ? Colors.white : Colors.black, // Text color when selected
            weight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Show bottom sheet //
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: MyText(
                text: "Material",
                color: Colors.black,
                weight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _buildBottomSheetButton(context, "Inventory", Colors.brown, () {
              Get.to(InventoryScreen());
            }),
            SizedBox(height: 12.h),
            _buildBottomSheetButton(context, "Received", Colors.blue, () {
              Get.to(ReceivedScreen());
            }),
            SizedBox(height: 12.h),
    //         _buildBottomSheetButton(context, "Purchased", Colors.green, () {
    //           Get.to(PurchasedScreen());
    //           // Add your navigation or action for Purchased
    // }),
            SizedBox(height: 12.h),
            _buildBottomSheetButton(context, "Used", Colors.green, () {
              Get.to(UsedScreen());

              // Add your navigation or action for Used
            }),
          ],
        ),
      );
    },
  );
}

Widget _buildBottomSheetButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onTap,
    ) {
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