import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vetri_hollowblock/view/screens/masters_all/update_employee.dart';
import 'package:vetri_hollowblock/view/screens/masters_all/update_material.dart';
import 'package:vetri_hollowblock/view/screens/masters_all/update_party.dart';
import 'package:vetri_hollowblock/view/widgets/buttons.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';
import '../../widgets/subhead.dart';

class MasterAll extends StatefulWidget {
  const MasterAll({super.key});

  @override
  State<MasterAll> createState() => _MasterAllState();
}

class _MasterAllState extends State<MasterAll> {
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
          return const Center(
              child: Text("Please make sure your device is in portrait view"));
        }
      },
    );
  }

  Widget _smallBuildLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 80.h,
        centerTitle: true,
        elevation: 2, // Adds a subtle shadow
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Subhead(
          text: "   Update Masters",
          color: Colors.black,
          weight: FontWeight.w600,
        ),
      ),
      body: SizedBox(
        width: width.w,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h,),
              _buildButton("Employee Update", Icons.person, () {
                Get.to(() => const UpdateEmployee(), transition: Transition.fade);
              }),
              SizedBox(height: 20.h),
              _buildButton("Material Library Update", Icons.inventory, () {
                Get.to(() => const UpdateMaterial(), transition: Transition.fade);

              }),
              SizedBox(height: 20.h),
              _buildButton("Party Update", Icons.groups, () {
                Get.to(() => const UpdateParty(), transition: Transition.fade);
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Custom Button Widget for Reusability
  Widget _buildButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width * 0.8, // Responsive width
        height: height * 0.12, // Adjusted height
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 3),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26.sp),
            SizedBox(width: 12.w),
            MyText(text: text, color: Colors.white, weight: FontWeight.w500)
          ],
        ),
      ),
    );
  }
}
