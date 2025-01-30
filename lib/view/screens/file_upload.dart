import 'dart:io';
import 'dart:convert'; // For base64 encoding
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/io_client.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker package
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vetri_hollowblock/view/widgets/subhead.dart';

/// Document attach with images //
class FileUpload extends StatefulWidget {
  const FileUpload({super.key, required this.projectName});
  final String projectName;

  @override
  State<FileUpload> createState() => _FileUploadState();
}

class _FileUploadState extends State<FileUpload> {
  late double height;
  late double width;
  List<String> filePaths = [];
  bool isUploading = false;
  final ImagePicker _picker = ImagePicker();
  late Box<String> fileBox;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    await Hive.initFlutter();
    fileBox = await Hive.openBox<String>('filePathsBox');

    print("Stored Keys: ${fileBox.keys}"); // Debug print to check stored keys

    setState(() {
      filePaths = fileBox.keys
          .where((key) => key is String && key.startsWith(widget.projectName)) // Ensure key is a String
          .map((key) => fileBox.get(key)!)
          .toList();
    });
  }


  Future<void> _saveFilePath(String filePath) async {
    String uniqueKey = "${widget.projectName}_${path.basename(filePath)}";
    print("Saving: $uniqueKey -> $filePath"); // Debug print
    await fileBox.put(uniqueKey, filePath);
  }


  Future<void> _deleteFile(int index) async {
    String uniqueKey = fileBox.keys.firstWhere(
            (key) => fileBox.get(key) == filePaths[index],
        orElse: () => "");
    if (uniqueKey.isNotEmpty) {
      await fileBox.delete(uniqueKey);
    }
    setState(() {
      filePaths.removeAt(index);
    });
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );

    if (result != null) {
      for (String? filePath in result.paths) {
        if (filePath != null) {
          await _uploadAndSave(filePath);
        }
      }
    }
  }

  Future<void> _uploadAndSave(String filePath) async {
    setState(() {
      isUploading = true;
    });

    File file = File(filePath);
    String fileName = path.basename(filePath);

    try {
      final response = await uploadFileToManager(file, fileName);
      if (response != null) {
        setState(() {
          filePaths.add(filePath);
        });
        await _saveFilePath(filePath);
      } else {
        print("Upload failed for file: $fileName");
      }
    } catch (e) {
      print("Error during upload: $e");
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> uploadFileToManager(File file, String fileName) async {
    final apiUrl = 'https://vetri.regenterp.com/api/method/upload_file';

    try {
      final credentials = 'f1178cbff3f9a07:f1d2a24b5a005b7';
      final headers = {
        'Authorization': 'Basic ${base64Encode(utf8.encode(credentials))}',
      };

      final ioClient = IOClient(HttpClient()
        ..badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true));

      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers.addAll(headers);

      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();

      request.files.add(http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: fileName,
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
          "file_name": fileName,
          "is_private": 0,
          "is_home_folder": 0,
          "is_attachments_folder": 0,
          "file_size": fileLength,
          "file_url": "/files/$fileName",
          "folder": "Home",
          "is_folder": 0,
          "attached_to_doctype": "Project Form",
          "attached_to_name": widget.projectName,
          // "attached_to_field": "documents_upload",
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
          "Success",
          "File uploaded successfully",
          colorText: Colors.white,
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );
        final responseBody = json.decode(await response.stream.bytesToString());
        return responseBody;
      } else {
        Get.snackbar(
          "Error",
          "Upload failed",
          colorText: Colors.white,
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
        );
        print(response.statusCode);
        print(await response.stream.bytesToString());
        return null;
      }
    } catch (error) {
      print('File Upload Error: $error');
      Get.snackbar(
        "Error",
        "Upload failed: $error",
        colorText: Colors.white,
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  void _openFile(String filePath) {
    OpenFile.open(filePath);
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;

    return Scaffold(
      backgroundColor: const Color(0xfff1f2f4),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xfff1f2f4),
        title: Subhead(text: "File Upload", color: Colors.black, weight: FontWeight.w500),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt_outlined),
            onPressed: _pickFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 10.h,),
          ElevatedButton(
            onPressed: _pickFiles,
            child: Text("Attach Documents / Images"),
          ),
          Expanded(
            child: filePaths.isNotEmpty
                ? ListView.builder(
              itemCount: filePaths.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    leading: Icon(Icons.insert_drive_file),
                    title: Text(path.basename(filePaths[index])),
                    onTap: () {
                      _openFile(filePaths[index]);
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteFile(index);
                      },
                    ),
                  ),
                );
              },
            )
                : const Center(child: Text("No files available")),
          ),
          if (isUploading) CircularProgressIndicator(),
        ],
      ),
    );
  }
}
