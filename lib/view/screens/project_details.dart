import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:vetri_hollowblock/view/screens/employee.dart';
import 'package:vetri_hollowblock/view/screens/file_upload.dart';
import 'package:vetri_hollowblock/view/screens/todo.dart';

import '../widgets/subhead.dart';
import '../widgets/text.dart';
import 'material.dart';

class ProjectDetails extends StatefulWidget {
  const ProjectDetails({super.key});

  @override
  State<ProjectDetails> createState() => _ProjectDetailsState();
}

class _ProjectDetailsState extends State<ProjectDetails> {
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
          return Text("Please make sure your device is in portrait view");
        }
      },
    );
  }


  Widget _smallBuildLayout(){
    return Scaffold(
      backgroundColor: const Color(0xfff1f2f4),
      appBar: AppBar(
        backgroundColor: const Color(0xfff1f2f4),
        toolbarHeight: 80.h,
        centerTitle: true,
        title: Subhead(
          text: "Project Details",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
      ),
      body: SizedBox(
        width: width.w,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 30.h,),
              GestureDetector(
                onTap: (){
                  Get.to(FileUpload());
                },
                child: Container(
                  height: height/10.h,
                  width: width/1.2.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Center(child: MyText(text: "File Upload", color: Colors.black, weight: FontWeight.w500)),
                ),
              ),
              SizedBox(height: 10.h,),
              GestureDetector(
                onTap: (){
                  Get.to(Employee());
                },
                child: Container(
                  height: height/10.h,
                  width: width/1.2.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Center(child: MyText(text: "Employee", color: Colors.black, weight: FontWeight.w500)),
                ),
              ),
              SizedBox(height: 10.h,),
              GestureDetector(
                onTap: (){
                  Get.to(MaterialScreen());
                },
                child: Container(
                  height: height/10.h,
                  width: width/1.2.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Center(child: MyText(text: "Material", color: Colors.black, weight: FontWeight.w500)),
                ),
              ),
              SizedBox(height: 10.h,),
              GestureDetector(
                onTap: (){
                  Get.to(Todo());
                },
                child: Container(
                  height: height/10.h,
                  width: width/1.2.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                  child: Center(child: MyText(text: "To Do", color: Colors.black, weight: FontWeight.w500)),
                ),
              )
              
              
            ],
          ),

        ),
      ),
    );
  }
}
