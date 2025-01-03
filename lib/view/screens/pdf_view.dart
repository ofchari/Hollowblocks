import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:vetri_hollowblock/view/widgets/subhead.dart';

class PdfPreviewScreen extends StatelessWidget {
  final File pdfFile;

  const PdfPreviewScreen({Key? key, required this.pdfFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Subhead(text: "PDF Preview", color: Colors.black, weight: FontWeight.w500),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            OpenFilex.open(pdfFile.path);
          },
          child: Text("Open PDF"),
        ),
      ),
    );
  }
}
