import 'dart:convert';
import 'dart:io';

import 'package:car_app/Api/ApiFuntion.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constants.dart';
import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:car_app/features/log_in/model/user_detail_model_bean.dart';
import 'package:car_app/features/log_in/ui/edit_user_details_activity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Common/Color.dart';
import '../../../Common/Constant.dart';
import '../data_manager/LoginDataManager.dart';
import '../model/GenerateOTPModelBean.dart';
import '../model/VerifyOtpModelBean.dart';

class OTPScreenActivity extends StatefulWidget {
  //GenerateOTPModelBean data;
  String mobileNo;

  OTPScreenActivity(this.mobileNo, {super.key});

  @override
  State<OTPScreenActivity> createState() => _OTPScreenActivityState();
}

class _OTPScreenActivityState extends State<OTPScreenActivity> {
  final TextEditingController _fieldOne = TextEditingController();
  final TextEditingController _fieldTwo = TextEditingController();
  final TextEditingController _fieldThree = TextEditingController();
  final TextEditingController _fieldFour = TextEditingController();
  final TextEditingController _fieldFive = TextEditingController();
  final TextEditingController _fieldSix = TextEditingController();

  ApiFuntions apiFuntions = ApiFuntions();
  LoginDataManager? loginDataManager;
  late SharedPreferences? sharedPreferences;
  final bool _isPasswordVisible = false;
  int maxLength = 10;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    loginDataManager = LoginDataManager(sharedPreferences!);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        CommonWidget.safePop(context, result: true);
        return false; // Prevent the default back button action
      },
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Spacer for background illustration
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                  ),
                  
                  // Main content card - White card with rounded top corners
                  Container(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Back button (optional, can be removed if not needed)
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
                              onPressed: () => CommonWidget.safePop(context),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // SMS verification message - Split into two lines as per design
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: "SMS verification code has been sent to your\n",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              fontFamily: "Pop400",
                            ),
                            children: [
                              TextSpan(
                                text: "Register Mobile No.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: "Pop500",
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Resend OTP - Proper spacing
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Implement resend OTP
                              CommonWidget.errorShowSnackBarFor(context, "Resend OTP functionality coming soon");
                            },
                            child: RichText(
                              text: TextSpan(
                                text: "OTP not received? ",
                                style: TextStyle(
                                  fontFamily: "Pop400",
                                  color: Colors.black87,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Resend",
                                    style: TextStyle(
                                      fontFamily: "Pop600",
                                      color: ColorClass.base_color,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Enter OTP label
                        Text(
                          "Enter OTP",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            fontFamily: "Pop600",
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // OTP Input - Centered with proper spacing
                        Center(
                          child: Pinput(
                            controller: _fieldOne,
                            length: 6,
                            keyboardType: TextInputType.number,
                            defaultPinTheme: PinTheme(
                              width: 50,
                              height: 56,
                              textStyle: const TextStyle(
                                fontSize: 22,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey[300]!, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            focusedPinTheme: PinTheme(
                              width: 50,
                              height: 56,
                              textStyle: const TextStyle(
                                fontSize: 22,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: ColorClass.base_color, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            submittedPinTheme: PinTheme(
                              width: 50,
                              height: 56,
                              textStyle: const TextStyle(
                                fontSize: 22,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: ColorClass.base_color, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Verify Button - Full width green button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_fieldOne.text.toString().length == 6) {
                                postOTP(context);
                              } else {
                                CommonWidget.errorShowSnackBarFor(
                                    context, "Please Enter the valid OTP");
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorClass.base_color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              "Verify",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  postOTP(BuildContext context) async {
    var response = await loginDataManager!.postOTP(
        _fieldOne.text,
        "",
        widget.mobileNo,
        context);
    var data = VerifyOtpModelBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      //loginDataManager!.setDataInShared(data.data!);
      sharedPreferences!
          .setString(Constant.accessToken, data.data!.accessToken ?? "");
      sharedPreferences!
          .setString(Constant.refreshToken, data.data!.refreshToken ?? "");
      sharedPreferences!.setString(Constant.refreshTokenExpireTime,
          data.data!.refreshTokenExpireTime.toString() ?? "");
      //CommonWidget.successShowSnackBarFor(context, data.message.toString());
      getUser(context);
      //CommonWidget.navigateToScreen(context, OTPScreenActivity());
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  getUser(BuildContext context) async {
    var response = await loginDataManager!.getUserDetails(context);
    
    // Check if response is HTML (error page) instead of JSON
    if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
      CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
      return;
    }
    
    try {
      var data = UserDetailsModelBean.fromJson(jsonDecode(response.body));
      if (data.status == "success") {
      sharedPreferences!
          .setString(Constant.firstName, data.data!.firstName ?? "");
      sharedPreferences!
          .setString(Constant.lastName, data.data!.lastName ?? "");
      sharedPreferences!.setString(Constant.email, data.data!.email ?? "");
      sharedPreferences!.setString(Constant.isEmailVerified,
          data.data!.isEmailVerified.toString() ?? "");
      sharedPreferences!.setString(Constant.mobile, data.data!.mobile ?? "");
      sharedPreferences!
          .setString(Constant.isNewUser, data.data!.isNewUser.toString() ?? "");
      sharedPreferences!
          .setString(Constant.roleName, data.data!.roleName ?? "");
      sharedPreferences!
          .setString(Constant.id, data.data!.sId.toString() ?? "");
      if (data.data!.isNewUser == true) {
        CommonWidget.navigateToScreen(context, const EditUserDetailsActivity());
      } else {
        CommonWidget.navigateToKillAllScreen(context, DashboardActivity());
      }
      //CommonWidget.navigateToScreen(context, OTPScreenActivity());
      } else {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      }
    } catch (e) {
      print("Error parsing user details: $e");
      CommonWidget.errorShowSnackBarFor(context, "Error parsing user details. Please try again.");
    }
  }
}

class OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final bool autoFocus;
  final String type;

  const OtpInput(this.controller, this.autoFocus, this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 50,
      child: TextField(
        autofocus: autoFocus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        controller: controller,
        maxLength: 1,
        cursorColor: Colors.purple,
        decoration: InputDecoration(
            focusColor: Colors.purple,
            hintText: "*",
            hintFadeDuration: Duration.zero,
            focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                borderSide: BorderSide(
                    color: ColorClass.base_color,
                    width: 1,
                    style: BorderStyle.solid)),
            enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                borderSide: BorderSide(
                    color: Color(0xffdedede),
                    width: 1,
                    style: BorderStyle.solid)),
            counterText: '',
            hintStyle: const TextStyle(color: Colors.black, fontSize: 20.0),
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                borderSide: BorderSide(color: Color(0xffdedede)))),
        onChanged: (value) {
          if (value.length == 1 && type != "six") {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && type != "one") {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }
}
