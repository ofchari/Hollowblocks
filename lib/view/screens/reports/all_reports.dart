import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vetri_hollowblock/view/screens/reports/employee_attendance_reports.dart';
import 'package:vetri_hollowblock/view/screens/reports/purchased_reports.dart';
import 'package:vetri_hollowblock/view/screens/reports/received_reports.dart';
import 'package:vetri_hollowblock/view/screens/reports/used_reports.dart';
import '../../widgets/subhead.dart';
import 'dart:math'as math;

import '../../widgets/text.dart';

class AllReports extends StatefulWidget {
  const AllReports({super.key,required, required this.projectName});
  final String projectName;

  @override
  State<AllReports> createState() => _AllReportsState();
}

class _AllReportsState extends State<AllReports> {
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
          return const Text("Please make sure your device is in portrait view");
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
        automaticallyImplyLeading: false,
        title: Subhead(
          text: "All Reports",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
      ),
      body: SizedBox(
        width: width.w,
        child: Column(
          children: [
            Padding(
            padding:  const EdgeInsets.only(left: 5.0,top: 2.0,right: 5.0),
            child:
                GestureDetector(
                  onTap: (){
                    Get.to(EmployeeReport(projectName: widget.projectName,));

                  },
                  child: Container(
                    height: height/6.h,
                    width: width/1.2.w,
                    decoration: BoxDecoration(
                        color: Colors.brown.shade600,
                        borderRadius: BorderRadius.circular(16.r)
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 10.h,),
                        // const  Icon(Icons.cut,color: Colors.red,size: 20,),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding:  const EdgeInsets.only(left: 5.0),
                                child:  Text("Employee Attendance \n Reports",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 19.sp,fontWeight: FontWeight.w500,color: Colors.white)),),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 5.0),
                                child: Container(
                                  width: width / 7.w,
                                  height: width / 7.w, // Ensure the container is a circle
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade400,
                                        Colors.blue.shade700,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.5),
                                        blurRadius: 10.0,
                                        offset: Offset(2, 4), // Slight shadow for depth
                                      ),
                                    ],
                                  ),
                                  child: Transform.rotate(
                                    angle: 60 * math.pi / 180,
                                    child: IconButton(
                                      onPressed: () {
                                        Get.to(EmployeeReport(projectName: widget.projectName,));
                                      },
                                      icon: const Icon(Icons.arrow_upward, size: 23),
                                      color: Colors.white, // Icon color matches the professional theme
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 20 .h,),
                        // Display the pending count for Cutting Inward from the API
                      ],
                    ),
                  ),
                ),
      ),
            SizedBox(height: 10.h,),
            Padding(
              padding:  const EdgeInsets.only(left: 5.0,top: 2.0,right: 5.0),
              child:
              GestureDetector(
                onTap: (){
                  Get.to(MaterialReceivedReport(projectName: widget.projectName,
                    ));

                },
                child: Container(
                  height: height/6.h,
                  width: width/1.2.w,
                  decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(16.r)
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 10.h,),
                      // const  Icon(Icons.cut,color: Colors.red,size: 20,),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding:  const EdgeInsets.only(left: 5.0),
                              child:  Text("Material Received \n Reports",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 19.sp,fontWeight: FontWeight.w500,color: Colors.white)),),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 5.0),
                              child: Container(
                                width: width / 7.w,
                                height: width / 7.w, // Ensure the container is a circle
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.blue.shade700,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.5),
                                      blurRadius: 10.0,
                                      offset: Offset(2, 4), // Slight shadow for depth
                                    ),
                                  ],
                                ),
                                child: Transform.rotate(
                                  angle: 60 * math.pi / 180,
                                  child: IconButton(
                                    onPressed: () {
                                      Get.to(MaterialReceivedReport(projectName: widget.projectName,
                                         ));
                                    },
                                    icon: const Icon(Icons.arrow_upward, size: 23),
                                    color: Colors.white, // Icon color matches the professional theme
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 20 .h,),
                      // Display the pending count for Cutting Inward from the API
                    ],
                  ),
                ),
              ),
            ),
                SizedBox(height: 10.h,),
            Padding(
              padding:  const EdgeInsets.only(left: 5.0,top: 2.0,right: 5.0),
              child:
              GestureDetector(
                onTap: (){
                  Get.to(MaterialUsedReport(projectName: widget.projectName,
                      ));

                },
                child: Container(
                  height: height/6.h,
                  width: width/1.2.w,
                  decoration: BoxDecoration(
                      color: Colors.pink.shade300,
                      borderRadius: BorderRadius.circular(16.r)
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 10.h,),
                      // const  Icon(Icons.cut,color: Colors.red,size: 20,),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding:  const EdgeInsets.only(left: 5.0),
                              child:  Text("Material Used \n Reports",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 19.sp,fontWeight: FontWeight.w500,color: Colors.white)),),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 5.0),
                              child: Container(
                                width: width / 7.w,
                                height: width / 7.w, // Ensure the container is a circle
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.blue.shade700,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.5),
                                      blurRadius: 10.0,
                                      offset: Offset(2, 4), // Slight shadow for depth
                                    ),
                                  ],
                                ),
                                child: Transform.rotate(
                                  angle: 60 * math.pi / 180,
                                  child: IconButton(
                                    onPressed: () {
                                      Get.to(MaterialUsedReport(projectName: widget.projectName,
                                          ));
                                    },
                                    icon: const Icon(Icons.arrow_upward, size: 23),
                                    color: Colors.white, // Icon color matches the professional theme
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 20 .h,),
                      // Display the pending count for Cutting Inward from the API
                    ],
                  ),
                ),
              ),
            ),
                SizedBox(height: 10.h,),
            Padding(
              padding:  const EdgeInsets.only(left: 5.0,top: 2.0,right: 5.0),
              child:
              GestureDetector(
                onTap: (){
                  Get.to(MaterialPurchaseReport(
                      projectName: widget.projectName,
                  ));

                },
                child: Container(
                  height: height/6.h,
                  width: width/1.2.w,
                  decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(16.r)
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 10.h,),
                      // const  Icon(Icons.cut,color: Colors.red,size: 20,),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding:  const EdgeInsets.only(left: 5.0),
                              child:  Text("Material Purchase \n Reports",style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 19.sp,fontWeight: FontWeight.w500,color: Colors.white)),),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 5.0),
                              child: Container(
                                width: width / 7.w,
                                height: width / 7.w, // Ensure the container is a circle
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.blue.shade700,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.5),
                                      blurRadius: 10.0,
                                      offset: Offset(2, 4), // Slight shadow for depth
                                    ),
                                  ],
                                ),
                                child: Transform.rotate(
                                  angle: 60 * math.pi / 180,
                                  child: IconButton(
                                    onPressed: () {
                                      Get.to(MaterialPurchaseReport(
                                          projectName: widget.projectName, // Coming from tab page
                                      ));
                                    },
                                    icon: const Icon(Icons.arrow_upward, size: 23),
                                    color: Colors.white, // Icon color matches the professional theme
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 20 .h,),
                      // Display the pending count for Cutting Inward from the API
                    ],
                  ),
                ),
              ),
            ),
                SizedBox(width: 2.w,),
                // GestureDetector(
                //   onTap: (){
                //     // Get.to(const OrderForm(updatedWorkflowState: '',));
                //     // Get.to();
                //   },
                //   child: Container(
                //     height: height/4.h,
                //     width: width/2.w,
                //     decoration: BoxDecoration(
                //         color: Colors.pink.shade100,
                //         borderRadius: BorderRadius.circular(26.r)
                //     ),
                //     child: Column(
                //       children: [
                //         SizedBox(height: 10.h,),
                //         // const  Icon(Icons.cut,color: Colors.red,size: 20,),
                //         Padding(
                //           padding: const EdgeInsets.all(8.0),
                //           child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //             children: [
                //               const Padding(
                //                 padding:  EdgeInsets.only(left: 5.0),
                //                 child:  Subhead(text: "Employee", color: Colors.black, weight: FontWeight.w500,),
                //               ),
                //               Padding(
                //                 padding:  const EdgeInsets.only(right: 5.0),
                //                 child: Container(
                //                     width: width/7.w,
                //                     decoration: BoxDecoration(
                //                         border: Border.all(
                //                             color: Colors.grey
                //                         ),
                //                         shape: BoxShape.circle
                //                     ),
                //                     child: Transform.rotate(
                //                         angle: 60 * math.pi / 180,
                //                         child: IconButton(
                //                             onPressed: (){
                //                               // Get.to(const OrderForm(updatedWorkflowState: '',));
                //                             },
                //                             icon: const Icon(Icons.arrow_upward,size: 23,))
                //                     )
                //                 ),
                //               )
                //
                //             ],
                //           ),
                //         ),
                //         SizedBox(height: 20 .h,),
                //         // Display the pending count for Cutting Inward from the API
                //       ],
                //     ),
                //   ),
                // ),

            ]
    ),

      )
    );
  }

}
