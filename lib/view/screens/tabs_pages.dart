import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vetri_hollowblock/view/screens/dashboard.dart';
import 'package:vetri_hollowblock/view/screens/employee/employee.dart';
import 'package:vetri_hollowblock/view/screens/file_upload.dart';
import 'package:vetri_hollowblock/view/screens/materials/material_details.dart';
import 'package:vetri_hollowblock/view/screens/project_forms/update_project_form.dart';
import 'package:vetri_hollowblock/view/screens/transaction_screens/transaction_details.dart';
import 'package:vetri_hollowblock/view/widgets/text.dart';
import '../widgets/subhead.dart';
import 'reports/all_reports.dart';

class TabsPages extends StatefulWidget {
  const TabsPages({
    super.key,
    required this.projectName,
    required this.work,
    this.initialTabIndex = 0
  });

  final String projectName;
  final String work;
  final int initialTabIndex;

  @override
  State<TabsPages> createState() => _TabsPagesState();
}

class _TabsPagesState extends State<TabsPages> with TickerProviderStateMixin {
  late TabController _tabController;
  String selectedDate = "Date"; // Default text before any date is selected,
  DateTime chooseDate = DateTime.now();

  /// Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: chooseDate,
      firstDate: DateTime(2000), // Earliest selectable date
      lastDate: DateTime(2101), // Latest selectable date
    );
    if (picked != null && picked != chooseDate) {
      setState(() {
        chooseDate = picked; // Update the selected date
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  /// Handles the back button press to confirm exit
  Future<bool> _onWillPop() async {
    return await Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: const Text(
          "Are you sure you want to exit?",
          textAlign: TextAlign.center,
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          _buildDialogButton("Yes", Colors.red, () {
            Get.offAll(() => const Dashboard());
          }),
          _buildDialogButton("No", Colors.green, () {
            Navigator.pop(context);
          }),
        ],
      ),
    ) ?? false;
  }

  /// Custom button for Alert Dialog
  Widget _buildDialogButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      ),


      onPressed: onPressed,
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: TabBarView(
          controller: _tabController,
          children: [
            UpdateProjectForm(projectName: widget.projectName),
            TransactionDetails(projectName : widget.projectName, work: widget.work,),
            Employee(work: widget.work),
            MaterialScreen(projectName: widget.projectName, work: widget.work),
            FileUpload(projectName: widget.projectName),
            AllReports(projectName : widget.projectName),
          ],
        ),
      ),
    );
  }

  /// Builds the App Bar with a sleek gradient background
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      leading: GestureDetector(
        onTap: (){
          Get.back();
        },
          child: Icon(Icons.arrow_back,color: Colors.white,)),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF0059C7)], // Modern blue gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      toolbarHeight: 80.h,
      centerTitle: true,
      elevation: 4,
      shadowColor: Colors.black26,
      title: Subhead(
        text: widget.work,
        color: Colors.white,
        weight: FontWeight.w600,
      ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
              onTap: () => _selectDate(context), // Call date picker on tap
              child: Text(chooseDate != null // Check if selectedDate is null
    ? DateFormat('dd-MM-yyyy').format(chooseDate)
        : 'Select Date',style: GoogleFonts.manrope(textStyle: TextStyle(fontSize: 13.5.sp,fontWeight: FontWeight.w500,color: Colors.white)),
            ),
          ),
          ) ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(50.h),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.figtree(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          labelPadding: EdgeInsets.symmetric(horizontal: 12.w),
          tabs: [
            _buildTab("Update Project"),
            _buildTab("Transaction Details"),
            _buildTab("Employee"),
            _buildTab("Material"),
            _buildTab("Files Upload"),
            _buildTab("Reports"),
          ],
        ),
      ),
    );
  }

  /// Custom method to create a professional-looking tab
  Tab _buildTab(String title) {
    return Tab(
      child: MyText(
        text: title,
        color: Colors.white,
        weight: FontWeight.w600,
      ),
    );
  }
}
