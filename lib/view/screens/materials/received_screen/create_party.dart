import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/buttons.dart';
import '../../../widgets/subhead.dart';
import '../../../widgets/text.dart';

class CreateParty extends StatefulWidget {
  const CreateParty({super.key});

  @override
  State<CreateParty> createState() => _CreatePartyState();
}

class _CreatePartyState extends State<CreateParty> {
  late double height;
  late double width;
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
          text: "Create New Party",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
      ),
      body: SizedBox(
        width: width.w,
        child: Column(
          children: [
            SizedBox(height: 20.h,),
            _buildTextField("Party Name"),
            SizedBox(height: 30.h,),
            _buildTextField("Phone Number"),
            SizedBox(height: 30.h,),
            _buildTextField("Party Type"),
            SizedBox(height: 30.h,),
            _buildTextField("Party Id"),
            SizedBox(height: 20.h,),
            GestureDetector(
                onTap: (){
                  // Get.to(MaterialsAdd());
                },
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: MyText(text: " + Add GST", color: Colors.blue, weight: FontWeight.w500),
                    ))),
            SizedBox(height: 10.h,),
            GestureDetector(
                onTap: (){
                  // Get.to(MaterialsAdd());
                },
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: MyText(text: " Opening Balance", color: Colors.blue, weight: FontWeight.w500),
                    ))),
            Spacer(),
            Padding(
              padding:  EdgeInsets.only(bottom: 8.0),
              child: Buttons(
                height: height / 20.h,
                width: width / 2.5.w,
                radius: BorderRadius.circular(10.r),
                color: Colors.blue,
                text: "Save",
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTextField( String label){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.0.w),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.dmSans(
            textStyle: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
