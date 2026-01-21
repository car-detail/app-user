import 'dart:async';


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/CommonWidget.dart';
import '../Common/Constant.dart';
import 'dashboard_module/ui/dashboard_activity.dart';
import 'log_in/ui/modern_login_activity.dart';

class SplashScreenActivity extends StatefulWidget {
  const SplashScreenActivity({super.key});

  @override
  State<SplashScreenActivity> createState() => _SplashScreenActivityState();
}

class _SplashScreenActivityState extends State<SplashScreenActivity>
    with SingleTickerProviderStateMixin {
  SharedPreferences? sharedPreferences;
  String? userid;

  @override
  void initState() {
    super.initState();
    start();
  }
  
  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    final userIdValue = sharedPreferences!.getString(Constant.id) ?? "";
    
    setState(() {
      userid = userIdValue;
    });
    
    // Check if user is logged in - navigate immediately if yes
    if (userIdValue.isNotEmpty) {
      // Small delay for splash screen visibility, then navigate
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => DashboardActivity(),
            ),
            (route) => false,
          );
        }
      });
      return; // Don't show login buttons if user is logged in
    }
    
    // User is not logged in - show login buttons
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/first_image.png'),
              fit: BoxFit.cover)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 30, 15, 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Only show Get Started button if user is NOT logged in
              if(userid == null || userid!.isEmpty)
              GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => const ModernLoginActivity(),
                      ),
                          (route) => false,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 30, right: 30),
                    child: CommonWidget.getGradinetButton(
                        "Get Started",
                        startcolor: 0xff006538,
                        endcolor: 0xff006538,
                        height: 50
                    ),
                  )),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
