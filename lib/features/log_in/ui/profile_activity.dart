import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/BaseActivity.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonPopUp.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../../../Common/ContainerDecoration.dart';
import '../../../Common/ModernDesignSystem.dart';
import '../../../Models/image_module_data.dart';
import '../../dashboard_module/ui/dashboard_activity.dart';
import '../data_manager/LoginDataManager.dart';
import '../model/user_detail_model_bean.dart';
import 'modern_login_activity.dart';

class ProfileActivity extends StatefulWidget {
  const ProfileActivity({super.key});

  @override
  State<ProfileActivity> createState() => _ProfileActivityState();
}

class _ProfileActivityState extends State<ProfileActivity> {
  var firstNameController = TextEditingController();
  var lastNameController = TextEditingController();
  var emailController = TextEditingController();
  var profileController = TextEditingController();
  var locationController = TextEditingController();
  List<File> selectedFiles = [];
  String imageURl = "";
  String profileurl = "";
  double currentLat = 0.0;
  double currentLng = 0.0;

  ApiFuntions apiFuntions = ApiFuntions();
  LoginDataManager? loginDataManager;
  late SharedPreferences? sharedPreferences;

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
    getUser(context);
  }

  getUser(BuildContext context) async {
    var response = await loginDataManager!.getUserDetails(context);
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
      setState(() {
        firstNameController.text = data.data!.firstName ?? "";
        lastNameController.text = data.data!.lastName ?? "";
        emailController.text = data.data!.email ?? "";
        profileurl = data.data!.image ?? "";
        
        // Load location from user data or SharedPreferences
        if (data.data!.location?.name != null && (data.data!.location!.name?.isNotEmpty ?? false)) {
          locationController.text = data.data!.location!.name ?? "";
          currentLat = data.data!.location!.coordinates?.lat?.toDouble() ?? 0.0;
          currentLng = data.data!.location!.coordinates?.long?.toDouble() ?? 0.0;
        } else {
          // Load from SharedPreferences (captured on login)
          locationController.text = sharedPreferences!.getString(Constant.location) ?? "";
          currentLat = double.tryParse(sharedPreferences!.getString(Constant.lat) ?? "0.0") ?? 0.0;
          currentLng = double.tryParse(sharedPreferences!.getString(Constant.long) ?? "0.0") ?? 0.0;
        }
      });

      print("Profile image url  $profileurl");

      //CommonWidget.navigateToScreen(context, OTPScreenActivity());
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  postUserDetails(BuildContext context) async {
    // Get location from controller or use current location
    String locationName = locationController.text.isNotEmpty 
        ? locationController.text 
        : sharedPreferences!.getString(Constant.location) ?? "";
    double lat = currentLat != 0.0 ? currentLat : (double.tryParse(sharedPreferences!.getString(Constant.lat) ?? "0.0") ?? 0.0);
    double lng = currentLng != 0.0 ? currentLng : (double.tryParse(sharedPreferences!.getString(Constant.long) ?? "0.0") ?? 0.0);
    
    var response = await loginDataManager!.postUserDetails(
        firstNameController.text,
        lastNameController.text,
        emailController.text,
        imageURl,
        sharedPreferences!.getString(Constant.id) ?? "",
        context,
        locationName: locationName.isNotEmpty ? locationName : null,
        lat: lat != 0.0 ? lat : null,
        lng: lng != 0.0 ? lng : null);
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
      
      // Update location in SharedPreferences if location was updated
      if (locationName.isNotEmpty) {
        sharedPreferences!.setString(Constant.location, locationName);
        sharedPreferences!.setString(Constant.lat, lat.toString());
        sharedPreferences!.setString(Constant.long, lng.toString());
      }
      
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      //CommonWidget.navigateToKillAllScreen(context, DashboardActivity());
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          CommonWidget.safePop(context);
          CommonWidget.errorShowSnackBarFor(
              context, 'Location services are disabled. Please enable them.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            CommonWidget.safePop(context);
            CommonWidget.errorShowSnackBarFor(
                context, 'Location permissions are denied');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          CommonWidget.safePop(context);
          CommonWidget.errorShowSnackBarFor(
              context, 'Location permissions are permanently denied');
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        currentLat = position.latitude;
        currentLng = position.longitude;
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      
      String address = placemarks[0].locality ?? 
                      placemarks[0].subAdministrativeArea ?? 
                      placemarks[0].administrativeArea ?? 
                      "Current Location";
      
      if (mounted) {
        setState(() {
          locationController.text = address;
        });
      }
      
      sharedPreferences!.setString(Constant.location, address);
      sharedPreferences!.setString(Constant.lat, position.latitude.toString());
      sharedPreferences!.setString(Constant.long, position.longitude.toString());

      if (context.mounted) {
        CommonWidget.safePop(context);
        CommonWidget.successShowSnackBarFor(
            context, 'Location updated successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        CommonWidget.errorShowSnackBarFor(
            context, 'Error getting location: ${e.toString()}');
      }
    }
  }

  postImage(BuildContext context) async {
    List<File> image = [selectedFiles[0]];
    var response = await loginDataManager!.postImage(image, context);
    var data = ImageModuleData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      imageURl = data.data?.url ?? "";
      //CommonWidget.successShowSnackBarFor(context, data.message??"");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header with gradient
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorClass.base_color,
                    ColorClass.base_color.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(ModernDesignSystem.radiusXL),
                  bottomRight: Radius.circular(ModernDesignSystem.radiusXL),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative elements
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // Back button and logout button
                  Padding(
                    padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => CommonWidget.safePop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            padding: const EdgeInsets.all(ModernDesignSystem.spacingS),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () {
                            CommonPopUp.showalertDialog(
                              context,
                              "",
                              "Are you sure - You want to logout?",
                              "No",
                              "Yes",
                              "info",
                              () => CommonWidget.safePop(context),
                              () async {
                                CommonWidget.safePop(context);
                                sharedPreferences!.clear();
                                CommonWidget.navigateToKillAllScreen(
                                    context, const ModernLoginActivity(isSignUp: false));
                              },
                              190,
                              positivetitlecolorButton: ColorClass.red,
                              navtextColorButton: ColorClass.green,
                              isboldtitle: false,
                            );
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            padding: const EdgeInsets.all(ModernDesignSystem.spacingS),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Main Content Card
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -40),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: ModernDesignSystem.spacingL),
                  decoration: ModernDesignSystem.modernCard(
                    borderRadius: ModernDesignSystem.radiusXL,
                    shadows: ModernDesignSystem.shadowLarge,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(ModernDesignSystem.spacingXL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          "Profile Details",
                          style: ModernDesignSystem.heading2(
                            color: ColorClass.base_color,
                          ),
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingXL),
                        
                        // Profile Picture
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ColorClass.base_color.withOpacity(0.2),
                                    width: 4,
                                  ),
                                  boxShadow: ModernDesignSystem.getColoredShadow(
                                    ColorClass.base_color,
                                    opacity: 0.2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: profileurl != "" && selectedFiles.isEmpty
                                      ? Image.network(
                                          profileurl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.asset(
                                              CommonWidget.getImagePath("chat_profile.png"),
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        )
                                      : selectedFiles.isNotEmpty
                                          ? CommonWidget.determineImageAsset(
                                              selectedFiles[0].path ?? "")
                                          : Image.asset(
                                              CommonWidget.getImagePath("chat_profile.png"),
                                              fit: BoxFit.cover,
                                            ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () async {
                                    var data = await BaseActivity.pickmedia(false);
                                    if (data != null) {
                                      if (mounted) {
                                        setState(() {
                                          selectedFiles.clear();
                                          selectedFiles.addAll(data);
                                        });
                                      }
                                      postImage(context);
                                    }
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: ColorClass.base_color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: ModernDesignSystem.shadowMedium,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingXL),
                        
                        // Input Fields
                        _buildModernTextField(
                          "First Name",
                          firstNameController,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingM),
                        _buildModernTextField(
                          "Last Name",
                          lastNameController,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingM),
                        _buildModernTextField(
                          "Email Address",
                          emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingM),
                        
                        // Location Field with button
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernTextField(
                                "Location",
                                locationController,
                                icon: Icons.location_on_outlined,
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: ModernDesignSystem.spacingM),
                            Container(
                              decoration: BoxDecoration(
                                color: ColorClass.base_color,
                                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                                boxShadow: ModernDesignSystem.getColoredShadow(
                                  ColorClass.base_color,
                                  opacity: 0.3,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.my_location, color: Colors.white),
                                onPressed: _getCurrentLocation,
                                tooltip: "Get Current Location",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingXL),
                        
                        // Save Button
                        ElevatedButton(
                          onPressed: () {
                            if (BaseActivity.checkEmptyField(
                                editingController: firstNameController,
                                message: "Please Enter First Name.",
                                context: context)) {
                              return;
                            } else if (BaseActivity.checkEmptyField(
                                editingController: lastNameController,
                                message: "Please Enter Last Name.",
                                context: context)) {
                              return;
                            } else if (BaseActivity.checkEmptyField(
                                editingController: emailController,
                                message: "Please Enter Email Address.",
                                context: context)) {
                              return;
                            } else if (imageURl == "" && selectedFiles.isEmpty && profileurl == "") {
                              CommonWidget.successShowSnackBarFor(
                                  context, "Please Select Profile Image");
                              return;
                            } else {
                              postUserDetails(context);
                            }
                          },
                          style: ModernDesignSystem.modernButtonStyle(
                            backgroundColor: ColorClass.base_color,
                            borderRadius: ModernDesignSystem.radiusM,
                            padding: const EdgeInsets.symmetric(vertical: ModernDesignSystem.spacingL),
                          ),
                          child: Text(
                            "Save",
                            style: ModernDesignSystem.bodyLarge(
                              color: Colors.white,
                            ).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingL),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField(
    String hint,
    TextEditingController controller, {
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Container(
      decoration: ModernDesignSystem.modernCard(
        color: Colors.grey[50],
        borderRadius: ModernDesignSystem.radiusM,
        shadows: ModernDesignSystem.shadowSmall,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        style: ModernDesignSystem.bodyMedium(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: ModernDesignSystem.bodyMedium(
            color: Colors.grey[500],
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: ColorClass.base_color,
                  size: 22,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
            borderSide: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
            borderSide: BorderSide(
              color: ColorClass.base_color,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ModernDesignSystem.spacingL,
            vertical: ModernDesignSystem.spacingL,
          ),
        ),
      ),
    );
  }
}
