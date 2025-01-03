import 'dart:io';
import 'dart:convert'; // For base64 encoding
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:vetri_hollowblock/view/universal_key_api/api_url.dart';
import 'package:vetri_hollowblock/view/widgets/buttons.dart';
import '../widgets/subhead.dart';

class FileUpload extends StatefulWidget {
  const FileUpload({super.key});

  @override
  State<FileUpload> createState() => _FileUploadState();
}

class _FileUploadState extends State<FileUpload> {
  late double height;
  late double width;
  List<String> filePaths = [];
  bool isUploading = false;

  // Method to pick multiple files (images)
  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        filePaths.addAll(result.paths.where((path) => path != null).cast<String>());
      });
    } else {
      print("User canceled the file picker");
    }
  }

  // Upload files to the server
  Future<void> _uploadFiles() async {
    final String url = "https://vetri.regenterp.com/api/resource/Documents%20Upload"; // Frappe API endpoint
    const String token = "f1178cbff3f9a07:f1d2a24b5a005b7"; // Your token

    setState(() {
      isUploading = true; // Show loading indicator
    });

    try {
      for (String filePath in filePaths) {
        File file = File(filePath);

        // Prepare the request for multipart/form-data
        var request = http.MultipartRequest('POST', Uri.parse(url));
        request.headers['Authorization'] = 'Bearer $token';

        // Add the file as a multipart file
        var fileName = file.uri.pathSegments.last;
        var multipartFile = await http.MultipartFile.fromPath('documents_upload', filePath, filename: fileName);
        request.files.add(multipartFile);

        // Additional fields for Frappe (customize these based on your need)
        request.fields['doctype'] = 'Documents Upload'; // Doctype you are uploading to
        // request.fields['name'] = 'DOC-2425-001'; // The name of the document (customize)
        request.fields['folder'] = 'Home'; // Folder to upload the file into (customize)

        // Send the request
        var response = await request.send();
        var responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          print("File uploaded successfully: $responseBody");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Files uploaded successfully")),
          );
        } else {
          print("Failed to upload file. Status: ${response.statusCode}, Body: $responseBody");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to upload files: $responseBody")),
          );
        }
      }
    } catch (e) {
      print("Error uploading files: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading files: $e")),
      );
    } finally {
      setState(() {
        isUploading = false; // Hide loading indicator
      });
    }
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
        if (width <= 450) {
          return _smallBuildLayout();
        } else {
          return const Text("Please make sure your device is in portrait view");
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
          text: "Files Upload",
          color: Colors.black,
          weight: FontWeight.w500,
        ),
      ),
      body: SizedBox(
        width: width.w,
        child: Column(
          children: [
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: _pickFiles,
              child: Text(
                "Attach Documents / Images",
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: filePaths.isNotEmpty
                  ? ListView.builder(
                itemCount: filePaths.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                    child: Container(
                      height: 200.h,
                      width: 200.w,
                      child: Image.file(
                        File(filePaths[index]),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              )
                  : const Center(
                child: Text("No files selected"),
              ),
            ),
            if (isUploading) const CircularProgressIndicator(), // Show loader during upload
            GestureDetector(
              onTap: () {
                filePaths.isNotEmpty && !isUploading ? _uploadFiles() : null;
              },
              child: Buttons(
                height: height / 18.h,
                width: width / 1.2.w,
                radius: BorderRadius.circular(10),
                color: Colors.blue,
                text: "Save",
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
