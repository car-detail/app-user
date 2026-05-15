import 'package:car_app/features/booking_model/ui/booking_list_activity.dart';
import 'package:car_app/features/home_module/ui/home_activity.dart';
import 'package:car_app/features/log_in/ui/edit_user_details_activity.dart';
import 'package:car_app/features/log_in/ui/profile_view_activity.dart';
import 'package:car_app/features/log_in/data_manager/LoginDataManager.dart';
import 'package:car_app/features/log_in/model/user_detail_model_bean.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/ModernDesignSystem.dart';
import '../../../Common/TourGuide.dart';
import '../../explore_module/ui/explore_activity.dart';

class DashboardActivity extends StatefulWidget {
  int currentIndex;
  DashboardActivity({this.currentIndex = 0,super.key});

  @override
  State<DashboardActivity> createState() => _DashboardActivityState();
}

class _DashboardActivityState extends State<DashboardActivity> {
  int selectedpage = 0;
  bool? tourShown; // This comes from database - tour_shown field
  LoginDataManager? loginDataManager;
  final GlobalKey<ExploreActivityState> _exploreKey = GlobalKey<ExploreActivityState>();
  
  // Tour guide keys
  final GlobalKey _homeNavKey = GlobalKey();
  final GlobalKey _exploreNavKey = GlobalKey();
  final GlobalKey _bookingsNavKey = GlobalKey();
  final GlobalKey _profileNavKey = GlobalKey();
  
  // Home screen tour guide keys
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _categoriesKey = GlobalKey();
  final GlobalKey _nearbyVendorsKey = GlobalKey();
  
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectedpage = widget.currentIndex;
    _loadUserDetails();
    
    // Handle when app is opened from a terminated state via notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔔 User App opened from terminated state via notification');
        _handleNotificationClick(message);
      }
    });

    // Handle when app is in background and opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 User App opened from background via notification');
      _handleNotificationClick(message);
    });

    // Listen for foreground messages to refresh data
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 User Dashboard received foreground message: ${message.data}');
      if (message.data['type'] == 'BOOKING_CONFIRMED' || 
          message.data['type'] == 'BOOKING_CANCELLED' ||
          message.data['type'] == 'BOOKING_COMPLETED') {
        debugPrint('🔔 Booking update detected. Refreshing data...');
        if (mounted) {
          _loadUserDetails();
          if (context.mounted && message.notification != null) {
            CommonWidget.successShowSnackBarFor(context, "${message.notification?.title}: ${message.notification?.body}");
          }
        }
      }
    });
  }

  void _handleNotificationClick(RemoteMessage message) {
    debugPrint('🔔 Handling notification click: ${message.data}');
    if (message.data['type'] == 'BOOKING_CONFIRMED' || 
        message.data['type'] == 'BOOKING_CANCELLED' ||
        message.data['type'] == 'BOOKING_COMPLETED') {
      if (mounted) {
        setState(() {
          selectedpage = 2; // Navigate to Bookings tab (index 2 in user app)
        });
      }
    }
  }

  
  Future<void> _loadUserDetails() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      loginDataManager = LoginDataManager(sharedPrefs);
      final response = await loginDataManager!.getUserDetails(context);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'success' && jsonData['data'] != null) {
          final userDetails = UserDetailsModelBean.fromJson(jsonData);
          
          // Force profile completion if name is missing
          final String firstName = (userDetails.data?.firstName ?? "").trim();
          if (firstName.isEmpty || firstName.toLowerCase() == "null") {
            if (mounted) {
              CommonWidget.navigateToKillAllScreen(context, const EditUserDetailsActivity());
              return;
            }
          }

          if (mounted) {
            setState(() {
              // Ensure tour_shown defaults to false if not present
              tourShown = userDetails.data?.tour_shown ?? false;
            });
            // Show tour guide only if not shown before (based on database tour_shown flag) and only on home screen
            // Only check tour_shown from database, not session flag
            if (!(tourShown ?? false) && selectedpage == 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                // Wait longer for home screen to be fully rendered, especially after navigation
                await Future.delayed(const Duration(milliseconds: 2000));
                // Retry up to 3 times if keys are not ready
                int retryCount = 0;
                bool keysReady = false;
                while (retryCount < 3 && mounted && context.mounted && selectedpage == 0) {
                  // Check if at least the home nav key is ready (required for first step)
                  if (_homeNavKey.currentContext != null) {
                    // Check other keys but don't require all of them
                    keysReady = true;
                    break;
                  } else {
                    await Future.delayed(const Duration(milliseconds: 500));
                    retryCount++;
                  }
                }
                if (mounted && context.mounted && selectedpage == 0) {
                  if (keysReady) {
                  } else {
                  }
                  _showTourGuide();
                } else {
                }
              });
            } else {
            }
          }
        }
      }
    } catch (e) {
      // Don't show tour guide if API fails - user might have already seen it
    }
  }
  
  Future<void> _markTourAsSeen() async {
    try {
      if (loginDataManager != null) {
        final response = await loginDataManager!.markTourShown(context);
        if (response.statusCode == 200) {
          if (mounted) {
            setState(() {
              tourShown = true; // Update local state to reflect database change
            });
          }
        } else {
        }
      }
    } catch (e) {
    }
  }
  List<Widget> get _pageNo => [
    HomeActivity(
      locationKey: _locationKey,
      searchKey: _searchKey,
      categoriesKey: _categoriesKey,
      nearbyVendorsKey: _nearbyVendorsKey,
    ),
    ExploreActivity(key: _exploreKey),
    const BookingListActivity(),
    const ProfileViewActivity()
  ];

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
        extendBody: true,
        body: Stack(
          children: [
            // Green status bar background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).padding.top,
                color: const Color(0xFF166534),
              ),
            ),
            SafeArea(
        child: IndexedStack(
          index: selectedpage,
          children: _pageNo,
        ),
            ),
          ],
      ),
      bottomNavigationBar: _buildModernBottomNav(),
      ),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      margin: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom > 0 ? 8 : 12,
      ),
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              key: _homeNavKey,
              icon: Icons.home_rounded,
              label: 'Home',
              index: 0,
              isSelected: selectedpage == 0,
            ),
            _buildNavItem(
              key: _exploreNavKey,
              icon: Icons.explore_rounded,
              label: 'Explore',
              index: 1,
              isSelected: selectedpage == 1,
            ),
            _buildNavItem(
              key: _bookingsNavKey,
              icon: Icons.book_online_rounded,
              label: 'Bookings',
              index: 2,
              isSelected: selectedpage == 2,
            ),
            _buildNavItem(
              key: _profileNavKey,
              icon: Icons.person_rounded,
              label: 'Profile',
              index: 3,
              isSelected: selectedpage == 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    Key? key,
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Expanded(
      flex: isSelected ? 3 : 2,
      key: key,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (mounted) {
            setState(() => selectedpage = index);
            if (index == 1) {
              _exploreKey.currentState?.refreshIfLocationChanged();
            }
          }
        },
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
          child: isSelected
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1CB273),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              : Icon(icon, color: Colors.grey[400], size: 24),
        ),
      ),
    );
  }

  void _showTourGuide() {
    // Double check - don't show if already shown in database
    if (tourShown == true) {
      return;
    }
    
    // Ensure we have a valid context
    if (!mounted || !context.mounted) {
      return;
    }
    
    try {
      TourGuide.showTour(
        context: context,
        tourId: 'user_dashboard',
        tourShown: tourShown ?? false,
        onMarkAsSeen: _markTourAsSeen, // This will be called when tour is completed or skipped
        steps: [
        TourStep(
          targetKey: _homeNavKey,
          title: "Home Tab",
          description: "Browse services, view offers, discover vendors, and find what you need",
          icon: Icons.home_rounded,
        ),
        TourStep(
          targetKey: _locationKey,
          title: "Location",
          description: "Set your location to find nearby vendors and services. Tap to search or select a location",
          icon: Icons.location_on,
          alignment: Alignment.bottomCenter,
        ),
        TourStep(
          targetKey: _searchKey,
          title: "Search",
          description: "Search for services, vendors, or locations. Press enter or tap the search icon to find results",
          icon: Icons.search,
          alignment: Alignment.bottomCenter,
        ),
        TourStep(
          targetKey: _categoriesKey,
          title: "Categories",
          description: "Browse services by category. Tap any category to see available services",
          icon: Icons.category,
          alignment: Alignment.topCenter,
        ),
        TourStep(
          targetKey: _nearbyVendorsKey,
          title: "Outlets Near You",
          description: "Discover vendors and services near your location. Tap 'See All' to view more options",
          icon: Icons.store,
          alignment: Alignment.topCenter,
        ),
        TourStep(
          targetKey: _exploreNavKey,
          title: "Explore Tab",
          description: "Discover new services, browse categories, and explore nearby vendors on the map",
          icon: Icons.explore_rounded,
        ),
        TourStep(
          targetKey: _bookingsNavKey,
          title: "Bookings Tab",
          description: "View all your bookings, track upcoming appointments, and manage your service history",
          icon: Icons.book_online_rounded,
        ),
        TourStep(
          targetKey: _profileNavKey,
          title: "Profile Tab",
          description: "Manage your account, edit your profile, update preferences, and view your information",
          icon: Icons.person_rounded,
        ),
      ],
      );
    } catch (e) {
    }
  }
}
