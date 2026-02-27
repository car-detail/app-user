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
      value: SystemUiOverlayStyle(
        statusBarColor: ColorClass.base_color,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: CommonWidget.buildBackButton(
            context,
            backgroundColor: Colors.white.withOpacity(0.2),
            iconColor: Colors.black87,
          ),
          title: const Text(
            "Profile",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, size: 20, color: Colors.red),
              tooltip: "Logout",
              onPressed: () => _showLogoutDialog(context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadUserDetails,
                child: SingleChildScrollView(
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
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: ColorClass.base_color.withOpacity(0.1),
                              child: ClipOval(
                                child: (userDetails?.data?.image != null && 
                                        userDetails!.data!.image!.isNotEmpty)
                                    ? Image.network(
                                        userDetails!.data!.image!,
                                        height: 120,
                                        width: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.asset(
                                            CommonWidget.getImagePath("chat_profile.png"),
                                            height: 120,
                                            width: 120,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      )
                                    : Image.asset(
                                        CommonWidget.getImagePath("chat_profile.png"),
                                        height: 120,
                                        width: 120,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // User Name
                          Text(
                            _getDisplayName(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Email
                          Text(
                            _getValueOrNA(
                              userDetails?.data?.email,
                              sharedPreferences?.getString(Constant.email),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Personal Information Section
                          _buildInfoRow(
                            icon: Icons.person,
                            label: "First Name",
                            value: _getValueOrNA(
                              userDetails?.data?.firstName,
                              sharedPreferences?.getString(Constant.firstName),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.person_outline,
                            label: "Last Name",
                            value: _getValueOrNA(
                              userDetails?.data?.lastName,
                              sharedPreferences?.getString(Constant.lastName),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.email,
                            label: "Email",
                            value: _getValueOrNA(
                              userDetails?.data?.email,
                              sharedPreferences?.getString(Constant.email),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.location_on,
                            label: "Location",
                            value: _getLocation(),
                          ),
                          const SizedBox(height: 32),
                          
                          // Edit Button
                          SizedBox(
                            width: double.infinity,
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
                                backgroundColor: ColorClass.base_color,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Edit Profile",
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
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: ColorClass.base_color,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
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
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
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
