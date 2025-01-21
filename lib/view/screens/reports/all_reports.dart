import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../widgets/subhead.dart';
import 'dart:math'as math;

class AllReports extends StatefulWidget {
  const AllReports({super.key});

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
            padding:  const EdgeInsets.only(left: 11.0,top: 2.0,right: 11.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: (){
                    // Get.to(const OrderForm(updatedWorkflowState: '',));
                    // Get.to();
                  },
                  child: Container(
                    height: height/7.h,
                    width: width/2.w,
                    decoration: BoxDecoration(
                        color: Colors.pink.shade100,
                        borderRadius: BorderRadius.circular(26.r)
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 10.h,),
                        // const  Icon(Icons.cut,color: Colors.red,size: 20,),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding:  EdgeInsets.only(left: 5.0),
                                child:  Subhead(text: "Employee", color: Colors.black, weight: FontWeight.w500,),
                              ),
                              Padding(
                                padding:  const EdgeInsets.only(right: 5.0),
                                child: Container(
                                    width: width/7.w,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey
                                        ),
                                        shape: BoxShape.circle
                                    ),
                                    child: Transform.rotate(
                                        angle: 60 * math.pi / 180,
                                        child: IconButton(
                                            onPressed: (){
                                              // Get.to(const OrderForm(updatedWorkflowState: '',));
                                            },
                                            icon: const Icon(Icons.arrow_upward,size: 23,))
                                    )
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

              ],
            )

            ),
      ]
    ),
    ));
  }

}
