import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'new_login_activity.dart';
import '../../home_module/data_manager/home_data_manager.dart';
import '../../home_module/model/services_model_data.dart';
import '../../home_module/model/offer_list_model.dart';
import '../../specialists_module/ui/all_packages_screen.dart';
import '../../specialists_module/ui/all_offers_screen.dart';

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
  HomeDataManager? homeDataManager;
  List<OfferListModelData> offers = [];
  bool isLoadingOffers = false;
  PageController? offerPageController;
  int currentOfferPage = 0;

  @override
  void initState() {
    super.initState();
    offerPageController = PageController();
    init();
  }

  @override
  void dispose() {
    offerPageController?.dispose();
    super.dispose();
  }

  void init() async {
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    loginDataManager = LoginDataManager(sharedPreferences!);
    homeDataManager = HomeDataManager(sharedPreferences!);
    
    // Load data from SharedPreferences first as fallback
    if (mounted) {
      setState(() {
        firstNameController.text = sharedPreferences!.getString(Constant.firstName) ?? "";
        lastNameController.text = sharedPreferences!.getString(Constant.lastName) ?? "";
        emailController.text = sharedPreferences!.getString(Constant.email) ?? "";
        locationController.text = sharedPreferences!.getString(Constant.location) ?? "";
        profileurl = sharedPreferences!.getString(Constant.image) ?? "";
      });
    }
    
    getUser(context);
    getOffers(context);
  }

  getUser(BuildContext context) async {
    if (!mounted || !context.mounted) return;
    
    try {
      var response = await loginDataManager!.getUserDetails(context);
      
      if (!mounted || !context.mounted) return;
      
      
      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        return;
      }
      
      // Check response status code
      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to load user details. Please check your connection and try again.");
        }
        return;
      }
      
      try {
        var jsonData = jsonDecode(response.body);
        var data = UserDetailsModelBean.fromJson(jsonData);
        
        
        if (data.status == "success" && data.data != null) {
          sharedPreferences!
              .setString(Constant.firstName, data.data!.firstName ?? "");
          sharedPreferences!
              .setString(Constant.lastName, data.data!.lastName ?? "");
          sharedPreferences!.setString(Constant.email, data.data!.email ?? "");
          sharedPreferences!.setString(Constant.image, data.data!.image ?? "");
          sharedPreferences!.setString(Constant.isEmailVerified,
              data.data!.isEmailVerified.toString() ?? "");
          sharedPreferences!.setString(Constant.mobile, data.data!.mobile ?? "");
          sharedPreferences!
              .setString(Constant.isNewUser, data.data!.isNewUser.toString() ?? "");
          sharedPreferences!
              .setString(Constant.roleName, data.data!.roleName ?? "");
          sharedPreferences!
              .setString(Constant.id, data.data!.sId.toString() ?? "");
          sharedPreferences!
              .setString(Constant.UserID, data.data!.sId.toString() ?? "");
          
          if (mounted) {
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
          }

        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to load user details. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error parsing user details. Please try again.");
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error loading user details. Please check your connection and try again.");
      }
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
        imageURl.isNotEmpty ? imageURl : profileurl,
        sharedPreferences!.getString(Constant.id) ?? "",
        context,
        locationName: locationName.isNotEmpty ? locationName : null,
        lat: lat != 0.0 ? lat : null,
        lng: lng != 0.0 ? lng : null);
    
    if (!mounted) return;

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
      sharedPreferences!
          .setString(Constant.UserID, data.data!.sId.toString() ?? "");
      
      // Update location in SharedPreferences if location was updated
      if (locationName.isNotEmpty) {
        sharedPreferences!.setString(Constant.location, locationName);
        sharedPreferences!.setString(Constant.lat, lat.toString());
        sharedPreferences!.setString(Constant.long, lng.toString());
      }
      
      if (mounted) {
        CommonWidget.successShowSnackBarFor(context, data.message ?? "");
        // Navigate back to profile view after successful save
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } else {
      if (mounted) {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      }
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

      if (mounted) {
        setState(() {
          currentLat = position.latitude;
          currentLng = position.longitude;
        });
      }

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
    if (!mounted || !context.mounted) return;
    
    try {
      List<File> image = [selectedFiles[0]];
      var response = await loginDataManager!.postImage(image, context);
      
      if (!mounted || !context.mounted) return;
      
      // Check response status code
      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to upload image. Please try again.");
        }
        return;
      }
      
      try {
        var data = ImageModuleData.fromJson(jsonDecode(response.body));
        if (data.status == "success") {
          if (mounted) {
            setState(() {
              imageURl = data.data?.url ?? "";
            });
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to upload image. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error processing image upload. Please try again.");
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error uploading image. Please check your connection and try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
              ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
        leading: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          onPressed: () {
            try {
              if (mounted && context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else if (mounted && context.mounted) {
                // If can't pop, navigate to dashboard as fallback
                Navigator.pushReplacement(
                              context,
                  MaterialPageRoute(builder: (context) => DashboardActivity(currentIndex: 0)),
                );
              }
            } catch (e) {
              // Fallback navigation
              if (mounted && context.mounted) {
                try {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardActivity(currentIndex: 0)),
                  );
                } catch (e2) {
                }
              }
            }
          },
        ),
        actions: [
          // Small logout button in top right
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.logout, size: 20),
              color: Colors.red,
              onPressed: () {
                _showLogoutDialog(context);
              },
              tooltip: "Logout",
                    ),
                  ),
                ],
              ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
                child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
                  ),
          child: Padding(
            padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Profile Picture
                        Center(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  CommonPopUp.imagePick(context, (List<File> files) {
                                    if (files.isNotEmpty) {
                                      setState(() {
                                        selectedFiles = files;
                                      });
                                      postImage(context);
                                    }
                                  });
                                },
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: ColorClass.base_color.withOpacity(0.1),
                                  child: ClipOval(
                                    child: (imageURl.isNotEmpty || profileurl.isNotEmpty)
                                        ? Image.network(
                                            imageURl.isNotEmpty ? imageURl : profileurl,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              Icons.person,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: ColorClass.base_color,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                const SizedBox(height: 32),
                        
                // First Name Field
                _buildDetailRow("First Name", firstNameController),
                const SizedBox(height: 20),
                
                // Last Name Field
                _buildDetailRow("Last Name", lastNameController),
                const SizedBox(height: 20),
                
                // Email Field (Optional)
                _buildDetailRow("Email (Optional)", emailController, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 20),
                
                // Location Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Location",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                          children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Icon(
                              Icons.location_on,
                              color: ColorClass.base_color,
                              size: 24,
                            ),
                          ),
                            Expanded(
                            child: TextField(
                              controller: locationController,
                                readOnly: true,
                              decoration: const InputDecoration(
                                hintText: "Location",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                              ),
                            ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                            Container(
                            margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ColorClass.base_color,
                              shape: BoxShape.circle,
                              ),
                              child: IconButton(
                              icon: const Icon(
                                Icons.my_location,
                                color: Colors.white,
                                size: 20,
                              ),
                                onPressed: _getCurrentLocation,
                                tooltip: "Get Current Location",
                              ),
                            ),
                          ],
                        ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                        
                        // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                            } else {
                              postUserDetails(context);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                            backgroundColor: ColorClass.base_color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                          ),
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(
                        fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            "Logout",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to logout?",
          ),
          actions: [
            TextButton(
              onPressed: () => CommonWidget.safePop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: ColorClass.base_color,
              ),
              onPressed: () {
                CommonWidget.safePop(context);
                sharedPreferences!.clear();
                if (context.mounted) {
                  CommonWidget.navigateToKillAllScreen(
                      context, const NewLoginActivity());
                }
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
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

  // Fetch offers
  Future<void> getOffers(BuildContext context) async {
    if (homeDataManager == null) return;
    
    setState(() {
      isLoadingOffers = true;
    });
    
    try {
      var response = await homeDataManager!.getOffer(context);
      if (response != null && response.statusCode == 200 && mounted) {
        var responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          setState(() {
            offers.clear();
            List<dynamic> offersJson = responseData['data'] as List;
            for (var offerJson in offersJson) {
              if (offerJson != null) {
                offers.add(OfferListModelData.fromJson(offerJson));
              }
            }
            isLoadingOffers = false;
          });
        } else {
          setState(() {
            offers = [];
            isLoadingOffers = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            offers = [];
            isLoadingOffers = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          offers = [];
          isLoadingOffers = false;
        });
      }
    }
  }

  // Build Packages Section
  Widget _buildPackagesSection(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final safeAreaPadding = mediaQuery.padding;
    const parentMargin = ModernDesignSystem.spacingL;
    const parentPadding = ModernDesignSystem.spacingXL;
    final offset = parentMargin + parentPadding;
    
    return OverflowBox(
      maxWidth: screenWidth,
      alignment: Alignment.centerLeft,
      child: Transform.translate(
        offset: Offset(-offset, 0),
        child: SizedBox(
          width: screenWidth,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Packages",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: "Pop600",
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to home to browse vendors with packages
                      CommonWidget.navigateToKillAllScreen(context, DashboardActivity(currentIndex: 0));
                    },
                    child: Text(
                      "See All",
                      style: TextStyle(
                        color: ColorClass.base_color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.grey[400], size: 48),
                    const SizedBox(height: 8),
                    Text(
                      "Browse vendors to see packages",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Packages are available from individual vendors",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
            ),
        ),
        ),
      ),
    );
  }

  // Build Personal Details Card
  Widget _buildPersonalDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorClass.base_color.withOpacity(0.1),
                  ColorClass.base_color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  color: ColorClass.base_color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Personal Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ColorClass.base_color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Image
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: ColorClass.base_color.withOpacity(0.1),
                        child: ClipOval(
                          child: profileurl != "" && selectedFiles.isEmpty
                              ? Image.network(
                                  profileurl,
                                  height: 100,
                                  width: 100,
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
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: ColorClass.base_color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Details
                _buildDetailRow("First Name", firstNameController),
                const SizedBox(height: 12),
                _buildDetailRow("Last Name", lastNameController),
                const SizedBox(height: 12),
                _buildDetailRow("Email", emailController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build Detail Row with TextField
  Widget _buildDetailRow(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ColorClass.base_color, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Build Offers Section
  Widget _buildOffersSection(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final safeAreaPadding = mediaQuery.padding;
    const parentMargin = ModernDesignSystem.spacingL;
    const parentPadding = ModernDesignSystem.spacingXL;
    final offset = parentMargin + parentPadding;
    
    return OverflowBox(
      maxWidth: screenWidth,
      alignment: Alignment.centerLeft,
      child: Transform.translate(
        offset: Offset(-offset, 0),
        child: SizedBox(
          width: screenWidth,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Offers",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: "Pop600",
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to home where offers are shown
                    CommonWidget.navigateToKillAllScreen(context, DashboardActivity(currentIndex: 0));
                  },
                  child: Text(
                    "See All",
                    style: TextStyle(
                      color: ColorClass.base_color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoadingOffers)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (offers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.local_offer, color: Colors.grey[400], size: 48),
                    const SizedBox(height: 8),
                    Text(
                      "No offers available",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: offerPageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentOfferPage = index;
                      });
                    },
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildFullWidthOfferCard(offers[index]),
                      );
                    },
                  ),
                ),
                if (offers.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        offers.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentOfferPage == index
                                ? ColorClass.base_color
                                : Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
            ),
          ),
        ),
      ),
    );
  }

  // Build Full Width Offer Card for Carousel
  Widget _buildFullWidthOfferCard(OfferListModelData offer) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background Image or Color
            if (offer.image != null && offer.image!.isNotEmpty)
              Image.network(
                offer.image!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorClass.base_color,
                          ColorClass.base_color.withOpacity(0.7),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorClass.base_color,
                      ColorClass.base_color.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            // Content Overlay
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.orange[300],
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            offer.title ?? "Offer",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: "Pop600",
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offer.description ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (offer.discount != null && offer.discount! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${offer.discount}% OFF",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.all_inclusive,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Never expires",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (offer.isActive ?? true) ? ColorClass.base_color : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (offer.isActive ?? true) ? "Active" : "Inactive",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build Offer Card (for horizontal list - keeping for compatibility)
  Widget _buildOfferCard(OfferListModelData offer) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    offer.title ?? "Offer",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: "Pop600",
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              offer.description ?? "",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${offer.discount ?? 0}% OFF",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (offer.isActive ?? true) ? ColorClass.base_color : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (offer.isActive ?? true) ? "Active" : "Inactive",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
