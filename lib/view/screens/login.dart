import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetri_hollowblock/view/screens/dashboard.dart';
import 'package:vetri_hollowblock/view/widgets/buttons.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late double height;
  late double width;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Get.off(Dashboard());
    }
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text == 'Vetri' && _passwordController.text == 'vetri123') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', _usernameController.text);

      Get.off(Dashboard());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid username or password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Define Sizes //
    var size = MediaQuery.of(context).size;
    height = size.height.h;
    width = size.width.w;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        height = constraints.maxHeight;
        width = constraints.maxWidth;

        if (width <= 1000) {
          return _smallBuildLayout();
        } else {
          return Text("Please make sure your device is in portrait view");
        }
      },
    );
  }

  Widget _smallBuildLayout() {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.grey,
      //   title: Subhead(text: "Login", color: Colors.black, weight: FontWeight.w500),
      // ),
      body: SizedBox(
        width: width.w,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 30.h,),
              Container(
                height: height/6.h,
                width: width/1.w,
                decoration: BoxDecoration(
                  image: DecorationImage(image: AssetImage("assets/KBSCo.jpg"),fit: BoxFit.fill)
                ),
                
              ),
              SizedBox(height: 30.h),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  " Welcome",
                  style: GoogleFonts.figtree(
                    textStyle: TextStyle(fontSize: 55.sp, fontWeight: FontWeight.w600, color: Colors.blue),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "  Back Here!!...",
                  style: GoogleFonts.figtree(
                    textStyle: TextStyle(fontSize: 39.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "      Please Login here to continue your access \n      and explore the features !!",
                  style: GoogleFonts.figtree(
                    textStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(height: 30.h),
              Container(
                height: height / 14.h,
                width: width / 1.09.w,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0.h),
                  child: TextFormField(
                    controller: _usernameController,
                    style: GoogleFonts.dmSans(
                      textStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.black),
                    ),
                    decoration: InputDecoration(
                      labelText: "   Username",
                      labelStyle: GoogleFonts.sora(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Colors.black,
                        size: 20,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                height: height / 14.h,
                width: width / 1.09.w,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0.h),
                  child: TextFormField(
                    obscureText: true,
                    controller: _passwordController,
                    style: GoogleFonts.dmSans(
                      textStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.black),
                    ),
                    decoration: InputDecoration(
                      labelText: "   Password",
                      labelStyle: GoogleFonts.sora(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_open,
                        color: Colors.black,
                        size: 20,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: _handleLogin,
                child: Buttons(
                  height: height / 16.h,
                  width: width / 1.3.w,
                  radius: BorderRadius.circular(10.r),
                  color: Colors.blue,
                  text: "Login",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
