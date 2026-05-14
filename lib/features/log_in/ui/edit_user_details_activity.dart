import 'dart:convert';
import 'dart:io';

import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:car_app/features/log_in/model/user_detail_model_bean.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_places_autocomplete_widgets/address_autocomplete_widgets.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/BaseActivity.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonPopUp.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Models/image_module_data.dart';
import '../data_manager/LoginDataManager.dart';

class EditUserDetailsActivity extends StatefulWidget {
  const EditUserDetailsActivity({super.key});

  @override
  State<EditUserDetailsActivity> createState() =>
      _EditUserDetailsActivityState();
}

class _EditUserDetailsActivityState extends State<EditUserDetailsActivity> {
  var firstNameController = TextEditingController();
  var lastNameController = TextEditingController();
  var emailController = TextEditingController();
  var profileController = TextEditingController();
  var locationController = TextEditingController();
  List<File> selectedFiles = [];
  String imageURl  = "";
  double currentLat = 0.0;
  double currentLng = 0.0;

  ApiFuntions apiFuntions = ApiFuntions();
  LoginDataManager? loginDataManager;
  SharedPreferences? sharedPreferences;

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
    
    // Load all user details from SharedPreferences
    setState(() {
      firstNameController.text = sharedPreferences!.getString(Constant.firstName) ?? "";
      lastNameController.text = sharedPreferences!.getString(Constant.lastName) ?? "";
      emailController.text = sharedPreferences!.getString(Constant.email) ?? "";
      imageURl = sharedPreferences!.getString(Constant.image) ?? "";
      locationController.text = sharedPreferences!.getString(Constant.location) ?? "";
      currentLat = double.tryParse(sharedPreferences!.getString(Constant.lat) ?? "0.0") ?? 0.0;
      currentLng = double.tryParse(sharedPreferences!.getString(Constant.long) ?? "0.0") ?? 0.0;
    });
  }

  postUserDetails(BuildContext context) async {
    // Get location from controller or use current location
    String locationName = locationController.text.isNotEmpty 
        ? locationController.text 
        : sharedPreferences!.getString(Constant.location) ?? "";
    double lat = currentLat != 0.0 ? currentLat : (double.tryParse(sharedPreferences!.getString(Constant.lat) ?? "0.0") ?? 0.0);
    double lng = currentLng != 0.0 ? currentLng : (double.tryParse(sharedPreferences!.getString(Constant.long) ?? "0.0") ?? 0.0);
    
    final response = await loginDataManager!.postUserDetails(
        firstNameController.text,
        lastNameController.text,
        emailController.text,
        imageURl,
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
      
      // Update location in SharedPreferences if location was updated
      if (locationName.isNotEmpty) {
        sharedPreferences!.setString(Constant.location, locationName);
        sharedPreferences!.setString(Constant.lat, lat.toString());
        sharedPreferences!.setString(Constant.long, lng.toString());
      }
      
      if (mounted) {
        CommonWidget.successShowSnackBarFor(context, data.message??"");
        CommonWidget.navigateToKillAllScreen(context, DashboardActivity());
      }
    } else {
      if (mounted) {
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      }
    }
  }

  Future<void> _handleManualLocationSave(String typedAddress) async {
    if (typedAddress.trim().isEmpty) return;
    
    try {
      List<geo.Location> locations = await geo.locationFromAddress(typedAddress);
      if (!mounted) return;
      if (locations.isNotEmpty) {
        setState(() {
          currentLat = locations[0].latitude;
          currentLng = locations[0].longitude;
          locationController.text = typedAddress;
        });
        
        // Try to get a cleaner name
        try {
          List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(currentLat, currentLng);
          if (!mounted) return;
          if (placemarks.isNotEmpty) {
            String cleanAddress = placemarks[0].locality ?? 
                                placemarks[0].subAdministrativeArea ?? 
                                typedAddress;
            setState(() {
              locationController.text = cleanAddress;
            });
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Geocoding failed for manual entry: $e');
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
        if (context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        if (context.mounted) {
          CommonWidget.errorShowSnackBarFor(
              context, 'Location services are disabled. Please enable them.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted && Navigator.canPop(context)) {
            CommonWidget.safePop(context);
          }
          if (context.mounted) {
            CommonWidget.errorShowSnackBarFor(
                context, 'Location permissions are denied');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted && Navigator.canPop(context)) {
          CommonWidget.safePop(context);
        }
        if (context.mounted) {
          CommonWidget.errorShowSnackBarFor(
              context, 'Location permissions are permanently denied');
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;

      setState(() {
        currentLat = position.latitude;
        currentLng = position.longitude;
      });

      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
          position.latitude, position.longitude);
      
      if (!mounted) return;
      String address = placemarks[0].locality ?? 
                      placemarks[0].subAdministrativeArea ?? 
                      placemarks[0].administrativeArea ?? 
                      placemarks[0].name ??
                      "Current Location";
      
      // If we have both locality and administrativeArea, format it nicely
      if (placemarks[0].locality != null && placemarks[0].administrativeArea != null) {
        address = "${placemarks[0].locality}, ${placemarks[0].administrativeArea}";
      }
      
      setState(() {
        locationController.text = address;
      });
      
      sharedPreferences!.setString(Constant.location, address);
      sharedPreferences!.setString(Constant.lat, position.latitude.toString());
      sharedPreferences!.setString(Constant.long, position.longitude.toString());

      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
      if (context.mounted) {
        CommonWidget.successShowSnackBarFor(
            context, 'Location updated successfully!');
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
      if (context.mounted) {
        CommonWidget.errorShowSnackBarFor(
            context, 'Error getting location: ${e.toString()}');
      }
    }
  }
  postImage(BuildContext context) async {
    if (selectedFiles.isNotEmpty) {
      List<File> image = [selectedFiles[0]];
      var response = await loginDataManager!.postImage(
          image,
          context);
      
      if (!mounted) return;

      var data = ImageModuleData.fromJson(jsonDecode(response.body));
      if (data.status == "success") {
        setState(() {
          imageURl = data.data?.url ?? "";
        });
        // Update SharedPreferences immediately so it reflects across the app
        sharedPreferences!.setString(Constant.image, imageURl);
      } else {
        if (mounted) {
          CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
        }
      }
    }
  }

  _validateAndSave(BuildContext context) async {
    try {
      postUserDetails(context);
    } catch (e) {
      postUserDetails(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Clean Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      CommonWidget.safePop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Profile Details",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: "Pop600",
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Profile Image Section
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
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: imageURl.isNotEmpty
                                  ? Image.network(
                                      imageURl,
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
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ColorClass.base_color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
                    
                    const SizedBox(height: 12),
                    
                    const SizedBox(height: 40),
                    
                    // Form Fields
                    _buildTextField(
                      controller: firstNameController,
                      label: "First Name",
                      hint: "Enter your first name",
                      icon: Icons.person_outline,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: lastNameController,
                      label: "Last Name",
                      hint: "Enter your last name",
                      icon: Icons.person_outline,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: emailController,
                      label: "Email Address (Optional)",
                      hint: "Enter your email",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      isOptional: true,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Location Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Location",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            fontFamily: "Pop500",
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: AddressAutocompleteTextField(
                                  controller: locationController,
                                  decoration: InputDecoration(
                                    hintText: "Search location...",
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                      fontFamily: "Pop400",
                                    ),
                                    prefixIcon: Icon(
                                      Icons.location_on_outlined,
                                      color: ColorClass.base_color,
                                      size: 22,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  mapsApiKey: 'AIzaSyBFtrosISezP-8z2NwTWKhD_5pNHoi0wRw',
                                  onSuggestionClick: (place) {
                                    final address = place.formattedAddress ?? place.name ?? '';
                                    final lat = place.lat ?? 0.0;
                                    final lng = place.lng ?? 0.0;
                                    setState(() {
                                      locationController.text = address;
                                      currentLat = lat;
                                      currentLng = lng;
                                    });
                                    if (sharedPreferences != null) {
                                      sharedPreferences!.setString(Constant.location, address);
                                      sharedPreferences!.setString(Constant.lat, lat.toString());
                                      sharedPreferences!.setString(Constant.long, lng.toString());
                                    }
                                  },
                                  types: const [
                                    AutoCompleteType.locality,
                                    AutoCompleteType.sublocality,
                                    AutoCompleteType.neighborhood,
                                    AutoCompleteType.postalCode
                                  ],
                                    onFinishedEditingWithNoSuggestion: (text) {
                                      _handleManualLocationSave(text);
                                    },
                                    language: 'en-US',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _getCurrentLocation,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: ColorClass.base_color,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ColorClass.base_color.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          if (BaseActivity.checkEmptyField(
                            editingController: firstNameController,
                            message: "Please enter first name",
                            context: context,
                          )) {
                            return;
                          } else if (BaseActivity.checkEmptyField(
                            editingController: lastNameController,
                            message: "Please enter last name",
                            context: context,
                          )) {
                            return;
                          } else {
                            // Email is optional, no validation needed
                            _validateAndSave(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorClass.base_color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Pop600",
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontFamily: "Pop500",
              ),
            ),
            if (isOptional)
              Text(
                " (Optional)",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontFamily: "PopReg",
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontFamily: "Pop400",
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontFamily: "Pop400",
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.grey[600],
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
