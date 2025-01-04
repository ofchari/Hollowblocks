import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart'as http;
import 'package:http/io_client.dart';
import 'package:vetri_hollowblock/view/screens/project_form.dart';

import '../../universal_key_api/api_url.dart';
import '../../widgets/buttons.dart';
import '../../widgets/subhead.dart';

class BlockScreen extends StatefulWidget {
  const BlockScreen({super.key});

  @override
  State<BlockScreen> createState() => _BlockScreenState();
}

class _BlockScreenState extends State<BlockScreen> {
  late double height;
  late double width;
  final blockController = TextEditingController();

  /// Post method for Work Type //
  Future<void> MobileDocument(BuildContext context) async {
    HttpClient client = HttpClient();
    client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    IOClient ioClient = IOClient(client);

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode(apiKey))}',
      'Content-Type': 'application/json',
    };

    final data = {
      'doctype': 'Block',
      'block_name': blockController.text,
    };

    final url = '$apiUrl/Block'; // Replace with your actual API URL
    final body = jsonEncode(data);
    print(data);

    try {
      // Use Uri.parse() to convert the string URL into a Uri object
      final response = await ioClient.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        Get.snackbar("Block", " Document Posted Successfully",colorText: Colors.white,backgroundColor: Colors.green,snackPosition: SnackPosition.BOTTOM);
        Get.offAll(ProjectForm());
      } else {
        String message = 'Request failed with status: ${response.statusCode}';
        if (response.statusCode == 417) {
          final serverMessages = json.decode(response.body)['_server_messages'];
          message = serverMessages ?? message;
        }
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(response.statusCode == 417 ? 'Message' : 'Error'),
            content: Text(message),
            actions: [
              ElevatedButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('An error occurred: $e'),
          actions: [
            ElevatedButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }
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
          text: "Add Block",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
      ),
      body: SizedBox(
        width: width.w,
        child: Column(
          children: [
            SizedBox(height: 30.h,),
            Container(
              height: height/15.2.h,
              width: width/1.13.w,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border.all(
                      color: Colors.grey.shade500
                  ),
                  borderRadius: BorderRadius.circular(6.r)
              ),
              child: TextFormField(
                controller: blockController,
                style: GoogleFonts.dmSans(textStyle: TextStyle(fontSize: 15.sp,fontWeight: FontWeight.w500,color: Colors.black)),
                decoration: InputDecoration(
                    labelText: "Block",
                    labelStyle: GoogleFonts.sora(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    prefixIcon:  Icon(
                      Icons.block_outlined,
                      color: Colors.grey.shade700,
                      size: 17.5,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 1.h),
                    border: InputBorder.none
                ),
              ),
            ),
            SizedBox(height: 30.h,),
            GestureDetector(
                onTap: (){
                  MobileDocument(context);
                },
                child: Buttons(height: height/15.h, width: width/1.5, radius: BorderRadius.circular(10.r), color: Colors.blue, text: "Submit"))

          ],
        ),
      ),
    );
  }
}
