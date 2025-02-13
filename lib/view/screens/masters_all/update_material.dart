import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../widgets/subhead.dart';

class UpdateMaterial extends StatefulWidget {
  const UpdateMaterial({super.key});

  @override
  State<UpdateMaterial> createState() => _UpdateMaterialState();
}

class _UpdateMaterialState extends State<UpdateMaterial> {
  late double height;
  late double width;
  @override
  Widget build(BuildContext context) {
    /// Define Sizes //
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
          return const Center(child: Text("Please make sure your device is in portrait view"));
        }
      },
    );
  }
  Widget _smallBuildLayout(){
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 80.h,
        centerTitle: true,
        title: Subhead(
          text: "Material Library Update",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}
