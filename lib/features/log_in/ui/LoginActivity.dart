import 'dart:async';
import 'dart:convert';
import 'package:car_app/features/log_in/ui/iotp_screen_activity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../../Api/ApiFuntion.dart';
import '../../../Common/BaseActivity.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../data_manager/LoginDataManager.dart';
import '../model/GenerateOTPModelBean.dart';

class LoginActivity extends StatefulWidget {
  String title;
  LoginActivity(this.title,{super.key});

  @override
  State<LoginActivity> createState() => _LoginActivityState();
}

class _LoginActivityState extends State<LoginActivity> {
  var mobileController = TextEditingController();
  String selectedCountryCode = '+1'; // Default to US

  ApiFuntions apiFuntions = ApiFuntions();
  LoginDataManager? loginDataManager;
  late SharedPreferences? sharedPreferences;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    loginDataManager = LoginDataManager(sharedPreferences!);
    try{
      var possition = await _determinePosition();
      if (!mounted) return;
      List<Placemark> placemarks = await placemarkFromCoordinates(possition.latitude, possition.longitude);
      if (!mounted) return;
      sharedPreferences!.setString(Constant.location, placemarks[0].locality??"");
      sharedPreferences!.setString(Constant.lat, possition.latitude.toString());
      sharedPreferences!.setString(Constant.long, possition.longitude.toString());
    }catch(e){
    }


  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/login_image.png'),
              fit: BoxFit.cover)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          margin: const EdgeInsets.only(top: 320),
          child: Column(
            children: [
              //Image(image: AssetImage('assets/images/login_image.png')),
              Expanded(
                  child: Container(
                margin: const EdgeInsets.only(left: 20, right: 20),
                child: SingleChildScrollView(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonWidget.getTextWidget500(widget.title,
                            color: ColorClass.base_color, size: 20),
                        // Country Code and Mobile Number Row
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: CountryCodePicker(
                                onChanged: (CountryCode countryCode) {
                                  setState(() {
                                    selectedCountryCode = countryCode.dialCode ?? '+1';
                                  });
                                },
                                initialSelection: 'US',
                                favorite: const ['+1', 'US', '+91', 'IN'],
                                showCountryOnly: false,
                                showOnlyCountryWhenClosed: false,
                                alignLeft: false,
                                padding: EdgeInsets.zero,
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                                flagWidth: 20,
                                showFlag: true,
                                showFlagDialog: true,
                                hideMainText: false,
                                hideSearch: false,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CommonWidget.getTextFieldWithgrayboderWithIcon(
                                  "Enter mobile number",
                                  "mobile_phone_rect",
                                  mobileController,
                                  keytype: TextInputType.phone),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        GestureDetector(
                            onTap: () {
                              //FocusManager.instance.primaryFocus?.unfocus();
                              if (BaseActivity.checkEmptyField(
                                  editingController: mobileController,
                                  message: "Please Enter Mobile Number",
                                  context: context)) {
                                return;
                              } else {
                                postLogin();
                              }
                            },
                            child: Container(
                              child: CommonWidget.getGradinetButton("Generate OTP",
                                  startcolor: 0xFF192028,
                                  endcolor: 0xFF192028,
                                  height: 40),
                            )),
                      ]),
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    /*if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }*/

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        permission = await Geolocator.requestPermission();
//        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  postLogin() async {
    try {
      // Validate phone number length (minimum 7 digits, maximum 15 digits)
      String phoneDigits = mobileController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      
      // Remove country code from phoneDigits if it's already included
      // Extract country code digits (e.g., "+1" -> "1", "+91" -> "91")
      String countryCodeDigits = selectedCountryCode.replaceAll(RegExp(r'[^0-9]'), '');
      if (countryCodeDigits.isNotEmpty && phoneDigits.startsWith(countryCodeDigits)) {
        phoneDigits = phoneDigits.substring(countryCodeDigits.length);
      }
      
      if (phoneDigits.length < 7 || phoneDigits.length > 15) {
        CommonWidget.errorShowSnackBarFor(
          context, 
          "Please enter a valid phone number (7-15 digits)"
        );
        return;
      }
      
      // Combine country code and mobile number
      String fullPhoneNumber = '$selectedCountryCode$phoneDigits';
      
      // Use Firebase Phone Auth
      await loginDataManager!.sendFirebaseOTP(
        fullPhoneNumber,
        (String verificationId) {
          // OTP sent successfully
          if (!mounted) return;
          // Create a mock GenerateOTPModelBean with verificationId
          var mockData = GenerateOTPModelBean(
            status: "success",
            message: "OTP sent successfully",
            data: Data(
              details: verificationId, // Store verificationId in details
            ),
          );
          
          if (context.mounted) {
            CommonWidget.navigateToScreen(
                context, OTPScreenActivity(mockData, fullPhoneNumber));
          }
        },
        (String error) {
          // Error sending OTP
          if (context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, error);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Something went wrong. Please try again.");
      }
    }
  }
}
