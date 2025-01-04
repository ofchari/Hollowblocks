import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Import the PDF view package
import 'package:vetri_hollowblock/view/widgets/subhead.dart';

class PdfPreviewScreen extends StatefulWidget {
  final File pdfFile;
  final VoidCallback onConfirm;
  final String projectName;

  const PdfPreviewScreen({
    Key? key,
    required this.pdfFile,
    required this.onConfirm,
    required this.projectName,
  }) : super(key: key);

  @override
  _PdfPreviewScreenState createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // You can perform any setup here, like checking if the PDF exists or loading
    // After setup, set isLoading to false to show the PDF
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Subhead(text: "PDF Preview", color: Colors.black, weight: FontWeight.w500),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : Column(
        children: [
          Expanded(
            child: PDFView(
              filePath: widget.pdfFile.path,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              onError: (error) {
                print('Error loading PDF: $error');
              },
              onPageError: (page, error) {
                print('Error on page $page: $error');
              },
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              widget.onConfirm();
              Navigator.of(context).pop(widget.projectName);
            },
            child: Text("Confirm and Submit"),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}


