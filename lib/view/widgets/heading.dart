import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class Heading extends StatefulWidget {
  const Heading({super.key, required this.text, required this.color, required this.weight});
  final String text;
  final Color color;
  final FontWeight weight;

  @override
  State<Heading> createState() => _HeadingState();
}

class _HeadingState extends State<Heading> {
  @override
  Widget build(BuildContext context) {
    return Text(widget.text,style: GoogleFonts.outfit(textStyle: TextStyle(fontSize: 23.sp,fontWeight: widget.weight,color: widget.color)),);
  }
}
