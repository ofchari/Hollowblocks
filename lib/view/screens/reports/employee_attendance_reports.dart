import 'package:flutter/material.dart';

class EmployeeAttendanceReports extends StatefulWidget {
  const EmployeeAttendanceReports({super.key});

  @override
  State<EmployeeAttendanceReports> createState() => _EmployeeAttendanceReportsState();
}

class _EmployeeAttendanceReportsState extends State<EmployeeAttendanceReports> {
  late double height;
  late double width;
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
          return const Text("Please make sure your device is in portrait view");
        }
      },
    );
  }
  Widget _smallBuildLayout(){
    return Scaffold(

    );
  }
}
