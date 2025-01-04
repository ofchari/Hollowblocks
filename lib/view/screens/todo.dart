import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';

import '../widgets/buttons.dart';
import '../widgets/subhead.dart';

class Todo extends StatefulWidget {
  const Todo({super.key});

  @override
  State<Todo> createState() => _TodoState();
}

class _TodoState extends State<Todo> {
  late double height;
  late double width;
  TextEditingController dateController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    /// Define Sizes ///
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
          text: "To Do",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
      ),
      body: SizedBox(
        width: width.w,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10.h,),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      height: height/17.h,
                      width: width/3.5.w,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10.r)
                      ),
                      child: Center(child: MyText(text: "Assignee", color: Colors.white, weight: FontWeight.w500)),
                    ),
                    GestureDetector(
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          dateController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
                        }
                      },
                      child: Container(
                        height: height / 17.h,
                        width: width / 3.5.w,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: MyText(
                            text: "Due Date",
                            color: Colors.white,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    Container(
                      height: height/17.h,
                      width: width/3.5.w,
                      decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10.r)
                      ),
                      child: Center(child: MyText(text: "Project", color: Colors.white, weight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30.h,),
              Align(
                alignment: Alignment.topLeft,
                child: Text('    Description:',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 16)),
              ),
              SizedBox(height: 10.h,),
              Container(
                height: height/7.h,
                width: width/1.13.w,
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(
                        color: Colors.grey.shade500
                    ),
                    borderRadius: BorderRadius.circular(6.r)
                ),
                child: TextFormField(
                  // controller: employeeController,
                  style: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
                  decoration: InputDecoration(
                      hintText: "     ",
                      hintStyle: GoogleFonts.sora(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      border: InputBorder.none
                  ),
                ),
              ),
              SizedBox(height: 30.h,),
              Buttons(height: height/15.h, width: width/1.5, radius: BorderRadius.circular(10.r), color: Colors.blue, text: "Save")
          
          
            ],
          ),
        ),
      ),
    );
  }
}
