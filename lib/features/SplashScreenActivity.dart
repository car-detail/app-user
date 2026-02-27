import 'dart:async';


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/CommonWidget.dart';
import '../Common/Constant.dart';
import 'dashboard_module/ui/dashboard_activity.dart';

import 'log_in/data_manager/LoginDataManager.dart';
import 'log_in/ui/new_login_activity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
    
    // Initialize Firebase Messaging and get token
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      // Request permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      print('User granted permission: ${settings.authorizationStatus}');

      // Get Token
      String? token = await messaging.getToken();
      print("FCM Token: $token");
      
      if (token != null) {
        sharedPreferences!.setString(Constant.fbtoken, token);
      }
      
      // Listen to token refresh
      messaging.onTokenRefresh.listen((fcmToken) {
        sharedPreferences!.setString(Constant.fbtoken, fcmToken);
      }).onError((err) {
        print("Error getting token refresh");
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          // You can show a custom snackbar or local notification here if needed
          if (context.mounted) {
            CommonWidget.successShowSnackBarFor(context, "${message.notification?.title}: ${message.notification?.body}");
          }
        }
      });
      
    } catch (e) {
      print("Error in Firebase Messaging init: $e");
    }

    final userIdValue = sharedPreferences!.getString(Constant.id) ?? "";
    
    setState(() {
      userid = userIdValue;
    });
    
    // Check if user is logged in - navigate immediately if yes
    if (userIdValue.isNotEmpty) {
      // Sync FCM token with backend in background
      try {
        final loginDataManager = LoginDataManager(sharedPreferences!);
        await loginDataManager.syncFcmToken(context);
      } catch (e) {
        print("Error syncing FCM token: $e");
      }

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
                        builder: (BuildContext context) => NewLoginActivity(),
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
