import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../data_manager/LoginDataManager.dart';
import '../model/user_detail_model_bean.dart';
import 'profile_activity.dart';
import 'new_login_activity.dart';

class ProfileViewActivity extends StatefulWidget {
  const ProfileViewActivity({super.key});

  @override
  State<ProfileViewActivity> createState() => _ProfileViewActivityState();
}

class _ProfileViewActivityState extends State<ProfileViewActivity> {
  LoginDataManager? loginDataManager;
  SharedPreferences? sharedPreferences;
  UserDetailsModelBean? userDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load from SharedPreferences first as fallback
    _loadFromSharedPreferences();
    _loadUserDetails();
  }
  
  Future<void> _loadFromSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      // Data will be loaded from SharedPreferences in the display methods
      // This just ensures sharedPreferences is initialized
    } catch (e) {
    }
  }

  Future<void> _loadUserDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      sharedPreferences = await SharedPreferences.getInstance();
      loginDataManager = LoginDataManager(sharedPreferences!);
      
      var response = await loginDataManager!.getUserDetails(context);
      
      if (!mounted) return;
      
      
      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        setState(() {
          isLoading = false;
        });
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        return;
      }
      
      if (response.statusCode == 200) {
        try {
          var jsonData = jsonDecode(response.body);
          var data = UserDetailsModelBean.fromJson(jsonData);
          
          
          if (data.status == "success" && data.data != null) {
            setState(() {
              userDetails = data;
              isLoading = false;
            });
          } else {
            // If API fails, keep SharedPreferences data visible
            setState(() {
              isLoading = false;
            });
            if (mounted && context.mounted) {
              CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to load user details. Showing cached data.");
            }
          }
        } catch (jsonError) {
          setState(() {
            isLoading = false;
          });
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, "Error parsing user details: $jsonError");
          }
        }
      } else {
        setState(() {
          isLoading = false;
        });
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Failed to load user details (Status: ${response.statusCode})");
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error loading user details: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Modern soft background
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadUserDetails,
                child: Stack(
                  children: [
                    // Gradient Header Background
                    Container(
                      height: 240,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF166534),
                            Color(0xFF1CB273),
                            Color(0xFF00E676),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                    ),
                    
                    // Main Content
                    SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          // Custom App Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CommonWidget.buildGreenHeaderBackButton(context),
                                const Text(
                                  "Profile",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontFamily: "Pop600",
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                                    onPressed: () => _showLogoutDialog(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Profile Card & Content
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.topCenter,
                                children: [
                                  // Card Background
                                  Container(
                                    margin: const EdgeInsets.only(top: 60),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 24,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.fromLTRB(24, 76, 24, 30),
                                    child: Column(
                                      children: [
                                        // User Name
                                        Text(
                                          _getDisplayName(),
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontFamily: "Pop700",
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        
                                        // Email
                                        Text(
                                          _getValueOrNA(
                                            userDetails?.data?.email,
                                            sharedPreferences?.getString(Constant.email),
                                          ),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: "Pop400",
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        
                                        // Personal Information Section
                                        _buildModernInfoRow(
                                          icon: Icons.phone_android_rounded,
                                          label: "Phone Number",
                                          value: _getValueOrNA(
                                            userDetails?.data?.mobile,
                                            sharedPreferences?.getString(Constant.mobile),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 12),
                                          child: Divider(color: Color(0xFFF1F5F9), height: 1),
                                        ),
                                        _buildModernInfoRow(
                                          icon: Icons.location_on_rounded,
                                          label: "Location",
                                          value: _getLocation(),
                                        ),
                                        const SizedBox(height: 32),
                                        
                                        // Edit Button
                                        Container(
                                          width: double.infinity,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF1CB273), Color(0xFF00E676)],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF1CB273).withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const ProfileActivity(),
                                                ),
                                              ).then((_) {
                                                // Refresh user details after editing
                                                _loadUserDetails();
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: const Text(
                                              "Edit Profile",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontFamily: "Pop600",
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Overlapping Profile Picture
                                  Positioned(
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 56,
                                        backgroundColor: const Color(0xFFF1F5F9),
                                        child: ClipOval(
                                          child: _getUserImageUrl().isNotEmpty
                                              ? Image.network(
                                                  _getUserImageUrl(),
                                                  width: 112,
                                                  height: 112,
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
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildModernInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: ColorClass.base_color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: "Pop400",
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: "Pop500",
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDisplayName() {
    String firstName = userDetails?.data?.firstName ?? sharedPreferences?.getString(Constant.firstName) ?? "";
    String lastName = userDetails?.data?.lastName ?? sharedPreferences?.getString(Constant.lastName) ?? "";
    String fullName = "$firstName $lastName".trim();
    return fullName.isEmpty ? "User" : fullName;
  }

  String _getLocation() {
    // Try from API data first
    if (userDetails?.data?.location?.name != null && 
        userDetails!.data!.location!.name!.isNotEmpty) {
      return userDetails!.data!.location!.name!;
    }
    // Fallback to SharedPreferences
    String location = sharedPreferences?.getString(Constant.location) ?? "";
    return location.isEmpty ? "N/A" : location;
  }

  String _getUserImageUrl() {
    if (userDetails?.data?.image != null && userDetails!.data!.image!.isNotEmpty) {
      return userDetails!.data!.image!;
    }
    return sharedPreferences?.getString(Constant.image) ?? "";
  }

  String _getValueOrNA(String? apiValue, String? sharedPrefValue) {
    if (apiValue != null && apiValue.isNotEmpty) {
      return apiValue;
    }
    if (sharedPrefValue != null && sharedPrefValue.isNotEmpty) {
      return sharedPrefValue;
    }
    return "N/A";
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
                sharedPreferences?.clear();
                CommonWidget.navigateToKillAllScreen(
                    context, const NewLoginActivity());
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }
}
