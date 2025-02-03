import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/io_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vetri_hollowblock/view/widgets/buttons.dart';
import 'package:vetri_hollowblock/view/widgets/subhead.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';

// Define your Hive model and adapter
@HiveType(typeId: 1)
class FileData extends HiveObject {
  @HiveField(0)
  String fileName;

  @HiveField(1)
  String filePath;

  @HiveField(2)
  String folder;

  @HiveField(3)
  String projectName;

  @HiveField(4)
  DateTime uploadDate;

  FileData({
    required this.fileName,
    required this.filePath,
    required this.folder,
    required this.projectName,
    required this.uploadDate,
  });
}

// Manually implemented adapter for FileData.
class FileDataAdapter extends TypeAdapter<FileData> {
  @override
  final int typeId = 1;

  @override
  FileData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FileData(
      fileName: fields[0] as String,
      filePath: fields[1] as String,
      folder: fields[2] as String,
      projectName: fields[3] as String,
      uploadDate: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FileData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.fileName)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.folder)
      ..writeByte(3)
      ..write(obj.projectName)
      ..writeByte(4)
      ..write(obj.uploadDate);
  }
}

class FileUpload extends StatefulWidget {
  const FileUpload({super.key, required this.projectName});
  final String projectName;

  @override
  State<FileUpload> createState() => _FileUploadState();
}

class _FileUploadState extends State<FileUpload> {
  late double height;
  late double width;

  // Updated to store FileData objects instead of Strings
  Map<String, List<FileData>> folderFiles = {
    'Common': [],
    'As Copy': [],
    'Tender Notice': [],
    'Deposite Challan': [],
    'Work Order': [],
    'Cr Copy': [],
    'Processing': [],
  };

  bool isUploading = false;
  final ImagePicker _picker = ImagePicker();
  late Box<FileData> fileBox;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    await Hive.initFlutter();

    // Register the FileData adapter if not registered
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FileDataAdapter());
    }

    // Open the box with the correct type
    fileBox = await Hive.openBox<FileData>('filesBox');

    // Load existing files
    _loadExistingFiles();
  }

  void _loadExistingFiles() {
    // Clear existing data
    folderFiles.forEach((key, value) => value.clear());

    // Load files from Hive
    for (var fileData in fileBox.values) {
      if (fileData.projectName == widget.projectName) {
        setState(() {
          folderFiles[fileData.folder]?.add(fileData);
        });
      }
    }
  }

  Future<void> _saveFileData(FileData fileData) async {
    // Generate a unique key for the file
    String key =
        '${widget.projectName}_${fileData.folder}_${fileData.fileName}_${DateTime.now().millisecondsSinceEpoch}';
    await fileBox.put(key, fileData);
  }

  Future<void> _deleteFile(String folder, int index) async {
    FileData fileData = folderFiles[folder]![index];

    // Find and delete the file from Hive
    var key = fileBox.keys.firstWhere(
          (k) => fileBox.get(k)?.filePath == fileData.filePath,
      orElse: () => null,
    );

    if (key != null) {
      await fileBox.delete(key);
    }

    // Delete the actual file
    try {
      File file = File(fileData.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting file: $e');
    }

    setState(() {
      folderFiles[folder]!.removeAt(index);
    });
  }

  Future<void> _uploadAndSave(String filePath, String folder) async {
    setState(() {
      isUploading = true;
    });

    try {
      final response =
      await uploadFileToManager(File(filePath), path.basename(filePath));
      if (response != null) {
        // Create FileData object
        FileData fileData = FileData(
          fileName: path.basename(filePath),
          filePath: filePath,
          folder: folder,
          projectName: widget.projectName,
          uploadDate: DateTime.now(),
        );

        // Save to Hive
        await _saveFileData(fileData);

        setState(() {
          folderFiles[folder]!.add(fileData);
        });
      }
    } catch (e) {
      print("Error during upload: $e");
      Get.snackbar(
        "Error",
        "Failed to save file: $e",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Widget _buildFileListTile(FileData fileData, String folder, int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: _getFileIcon(fileData.fileName),
        title: Text(fileData.fileName),
        subtitle: Text('Uploaded: ${_formatDate(fileData.uploadDate)}'),
        onTap: () => _openFile(fileData.filePath),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteFile(folder, index),
        ),
      ),
    );
  }

  void _showBottomSheet(String folder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                folder,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () => _pickFiles(folder),
                child: Text("Attach Documents / Images"),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: folderFiles[folder]!.isEmpty
                    ? Center(child: Text("No files in $folder"))
                    : ListView.builder(
                  itemCount: folderFiles[folder]!.length,
                  itemBuilder: (context, index) {
                    return _buildFileListTile(
                      folderFiles[folder]![index],
                      folder,
                      index,
                    );
                  },
                ),
              ),
              if (isUploading) CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
  }

  Widget _getFileIcon(String fileName) {
    String extension = fileName.split('.').last.toLowerCase();
    IconData iconData;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        iconData = Icons.image;
        break;
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        break;
      case 'xls':
      case 'xlsx':
        iconData = Icons.table_chart;
        break;
      default:
        iconData = Icons.insert_drive_file;
    }

    return Icon(iconData);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _pickFiles(String folder) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'txt',
        'jpg',
        'jpeg',
        'png'
      ],
    );

    if (result != null) {
      for (String? filePath in result.paths) {
        if (filePath != null) {
          await _uploadAndSave(filePath, folder);
        }
      }
    }
  }

  Future<Map<String, dynamic>?> uploadFileToManager(
      File file, String fileName) async {
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
        final responseBody =
        json.decode(await response.stream.bytesToString());
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
    // Obtain screen dimensions for responsive layout.
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Text
              const Subhead(
                text: "Attach Documents & Files 📂",
                color: Colors.black87,
                weight: FontWeight.w600,
                // Optionally, adjust font size if needed:
                // fontSize: 20.sp,
              ),
              SizedBox(height: 15.h),

              // Common Document Attachment Button
              GestureDetector(
                onTap: () => _showBottomSheet("Common"),
                child: Buttons(
                  height: screenSize.height / 15,
                  width: screenSize.width,
                  radius: BorderRadius.circular(8.r),
                  color: Colors.brown.shade400,
                  text: "Attach Common Document",
                  // Optionally, add text style customization here:
                  // textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(height: 30.h),

              // Folder-specific Buttons
              _buildFolderButtons(screenSize),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a Wrap of folder-specific buttons, excluding the 'Common' folder.
  Widget _buildFolderButtons(Size screenSize) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16.w,
      runSpacing: 16.h,
      children: folderFiles.entries
      // Exclude 'Common' folder since it's handled above.
          .where((entry) => entry.key != "Common")
          .map((entry) {
        final Color buttonColor = _getButtonColor(entry.key);
        return GestureDetector(
          onTap: () => _showBottomSheet(entry.key),
          child: Buttons(
            height: screenSize.height / 15,
            width: screenSize.width / 2.5,
            radius: BorderRadius.circular(8.r),
            color: buttonColor,
            text: entry.key,
            // Optionally, add custom text styling:
            // textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
    );
  }

  /// Returns a professional color based on the folder name.
  Color _getButtonColor(String folderName) {
    switch (folderName) {
      case 'As Copy':
        return Colors.blueGrey.shade400;
      case 'Tender Notice':
        return Colors.teal.shade400;
      case 'Deposite Challan':
        return Colors.deepOrange.shade300;
      case 'Work Order':
        return Colors.red.shade400;
      case 'Cr Copy':
        return Colors.grey.shade600;
      case 'Processing':
        return Colors.indigo.shade400;
      default:
        return Colors.blueGrey.shade400;
    }
  }


}
