import 'dart:io';
import 'dart:convert'; // For base64 encoding
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker package
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:vetri_hollowblock/view/screens/project_details.dart';
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
  final ImagePicker _picker = ImagePicker(); // Create an instance of ImagePicker

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

  // Method to take a picture using the camera
  Future<void> _takePicture() async {
    // Request camera permission
    PermissionStatus status = await Permission.camera.request();

    if (status.isGranted) {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera); // Open camera to take a picture

      if (image != null) {
        setState(() {
          filePaths.add(image.path); // Add the image file path to filePaths
        });
      } else {
        print("No image was selected from the camera");
      }
    } else {
      print("Camera permission denied");
      // Optionally show a dialog to ask user to grant permission
    }
  }

  // Upload files to the server
  Future<void> _uploadFiles() async {
    final String url = "https://vetri.regenterp.com/api/method/upload_file";
    const String token = "f1178cbff3f9a07:f1d2a24b5a005b7";

    setState(() {
      isUploading = true; // Show loading indicator
    });

    try {
      for (String filePath in filePaths) {
        File file = File(filePath);
        var request = http.MultipartRequest('POST', Uri.parse(url));

        String basicAuth = 'Basic ${base64Encode(utf8.encode(token))}';
        request.headers['Authorization'] = basicAuth;

        var fileName = file.uri.pathSegments.last;
        request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));

        // Add required fields
        request.fields['doctype'] = 'Documents Upload';
        request.fields['folder'] = 'Home';

        var response = await request.send();
        var responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          print("File uploaded successfully: $responseBody");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Files uploaded successfully")),
          );

          // Navigate to another screen
         Navigator.pop(context);
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
        if (width <= 1000) {
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
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt_outlined),
            onPressed: _takePicture, // Open the camera when the icon is clicked
          ),
        ],
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
                  return GestureDetector(
                    onTap: () {
                      // Show zoomable image using a dialog
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            child: PhotoView(
                              imageProvider: FileImage(File(filePaths[index])),
                              backgroundDecoration: const BoxDecoration(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5.h),
                      child: Container(
                        height: 200.h,
                        width: width * 0.8, // Perfect size adjustment
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.file(
                            File(filePaths[index]),
                            width: width * 0.8,
                            fit: BoxFit.cover,
                          ),
                        ),
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
