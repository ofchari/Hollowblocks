import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vetri_hollowblock/view/screens/dashboard.dart';
import 'package:vetri_hollowblock/view/widgets/buttons.dart';


class SessionManager {
  static const String keyIsLoggedIn = 'isLoggedIn';
  final GetStorage storage = GetStorage();

  Future<void> logout() async {
    try {
      await storage.remove(keyIsLoggedIn); // Clear the login status
      Get.snackbar(
        'Logged Out',
        'You have been logged out successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAll(() => const Login()); // Navigate back to the Login screen
    } catch (e) {
      debugPrint('Logout failed: $e');
      Get.snackbar(
        'Error',
        'Failed to logout. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late double height;
  late double width;
  bool isLoading = false;
  final storage = GetStorage();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Constants
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String validUsername = 'Vetri';
  static const String validPassword = 'vetri123';

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void checkLoginStatus() {
    try {
      bool isLoggedIn = storage.read(keyIsLoggedIn) ?? false;
      if (isLoggedIn) {
        // Defer navigation until after the first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.off(() => const Dashboard());
        });
      }
    } catch (e) {
      debugPrint('Auto-login check failed: $e');
    }
  }


  Future<void> handleLogin() async {
    if (isLoading) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter both username and password',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (username == validUsername && password == validPassword) {
        await storage.write(keyIsLoggedIn, true);

        Get.snackbar(
          'Success',
          'Login successful!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        Get.off(() => const Dashboard());
      } else {
        Get.snackbar(
          'Error',
          'Invalid username or password',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Login failed. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint('Login error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

      /// Logout logic ///
  void logout() async {
    try {
      await storage.remove(keyIsLoggedIn); // Remove the login status
      Get.snackbar(
        'Logged Out',
        'You have been logged out successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAll(() => const Login()); // Navigate back to Login screen
    } catch (e) {
      debugPrint('Logout failed: $e');
      Get.snackbar(
        'Error',
        'Failed to logout. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          return const Center(
            child: Text("Please make sure your device is in portrait view"),
          );
        }
      },
    );
  }

  Widget _smallBuildLayout() {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: width.w,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 30.h),
                Image.asset(
                  "assets/KBSCo.jpg",
                  height: height/6.h,
                  width: width/1.w,
                  fit: BoxFit.contain,
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
                  onTap: isLoading ? null : handleLogin,
                  child: Buttons(
                    height: height / 16.h,
                    width: width / 1.3.w,
                    radius: BorderRadius.circular(10.r),
                    color: isLoading ? Colors.grey : Colors.blue,
                    text: isLoading ? "Loading..." : "Login",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}