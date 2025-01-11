import 'dart:io';
import 'dart:convert'; // For base64 encoding
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/io_client.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker package
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
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

  @override
  void initState() {
    super.initState();
    _loadFilePaths(); // Load file paths on initialization
  }

  // Load file paths from SharedPreferences
  Future<void> _loadFilePaths() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      filePaths = prefs.getStringList('filePaths') ?? [];
    });
  }

  // Save file paths to SharedPreferences
  Future<void> _saveFilePaths() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('filePaths', filePaths);
  }

  // Method to pick multiple files (images)
  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        filePaths.addAll(result.paths.where((path) => path != null).cast<String>());
        _saveFilePaths(); // Save updated file paths
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
          _saveFilePaths(); // Save updated file paths
        });
      } else {
        print("No image was selected from the camera");
      }
    } else {
      print("Camera permission denied");
    }
  }

  // Method to upload image to file manager
  Future<Map<String, dynamic>?> uploadImageToFileManager(
      File imageFile,
      String fileName,
      ) async {
    final apiUrl = 'https://btex.regenterp.com/api/method/upload_file';

    try {
      final credentials = '3eb2e0bbf9f6d44:e972ba4bf4c48f9';
      final headers = {
        'Authorization': 'Basic ${base64Encode(utf8.encode(credentials))}',
      };

      final ioClient = IOClient(HttpClient()
        ..badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true));

      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers.addAll(headers);

      final imageStream = http.ByteStream(imageFile.openRead());
      final imageLength = await imageFile.length();

      request.files.add(http.MultipartFile(
        'file',
        imageStream,
        imageLength,
        filename: '$fileName.png',
      ));

      final messageData = {
        "message": {
          "name": fileName,
          "owner": "Administrator",
          "creation": DateTime.now().toIso8601String(),
          "modified": DateTime.now().toIso8601String(),
          "modified_by": "Administrator",
          "docstatus": 0,
          "idx": 0,
          "file_name": '$fileName.png',
          "is_private": 0,
          "is_home_folder": 0,
          "is_attachments_folder": 0,
          "file_size": imageLength,
          "file_url": "/files/$fileName.png",
          "folder": "Home",
          "is_folder": 0,
          "content_hash": "",
          "uploaded_to_dropbox": 0,
          "uploaded_to_google_drive": 0,
          "doctype": "File"
        }
      };

      request.fields['data'] = json.encode(messageData);

      final response = await ioClient.send(request);

      if (response.statusCode == 200) {
        Get.snackbar(
          "Image",
          " Document Posted Successfully",
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );
        final responseBody = json.decode(await response.stream.bytesToString());
        return responseBody;
      } else {
        print(response.statusCode);
        print(await response.stream.bytesToString());
        return null;
      }
    } catch (error) {
      print('Image Upload Error: $error');
      return null;
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
            onPressed: _takePicture,
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
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
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
                            child: Container(
                              height: 200.h,
                              width: width * 0.8,
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
                        ),
                        SizedBox(width: 10.w),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 24.sp,
                          ),
                          onPressed: () {
                            setState(() {
                              filePaths.removeAt(index);
                              _saveFilePaths(); // Save updated file paths
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              )
                  : const Center(
                child: Text("No files selected"),
              ),
            ),
            if (isUploading) const CircularProgressIndicator(),
            GestureDetector(
              onTap: () async {
                if (filePaths.isNotEmpty && !isUploading) {
                  setState(() {
                    isUploading = true;
                  });

                  try {
                    for (String filePath in filePaths) {
                      File imageFile = File(filePath);
                      String fileName = imageFile.uri.pathSegments.last.split('.').first;

                      final response = await uploadImageToFileManager(imageFile, fileName);
                      if (response != null) {
                        print("Upload successful for file: $fileName");
                      } else {
                        print("Upload failed for file: $fileName");
                      }
                    }
                  } catch (e) {
                    print("Error during upload: $e");
                  } finally {
                    setState(() {
                      isUploading = false;
                    });
                  }
                }
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
