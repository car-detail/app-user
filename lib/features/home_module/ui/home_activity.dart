import 'dart:async';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

import 'package:car_app/Common/Color.dart';
import 'package:car_app/design_system/components/car_loader.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/Common/ModernDesignSystem.dart';
import 'package:car_app/features/categories_module/ui/categories_list_activity.dart';
import 'package:car_app/features/categories_module/ui/sevice_list_screen.dart';
import 'package:google_maps_places_autocomplete_widgets/address_autocomplete_widgets.dart';
import 'package:car_app/features/home_module/data_manager/home_data_manager.dart';
import 'package:car_app/features/home_module/model/offer_list_model.dart';
import 'package:car_app/features/specialists_module/ui/specialists_activity.dart';
import 'package:car_app/features/booking_model/ui/booking_list_activity.dart';
import 'package:car_app/features/bookmark_model/ui/bookmark_activity.dart';
import 'package:car_app/features/log_in/ui/profile_activity.dart';
import 'package:car_app/features/log_in/ui/new_login_activity.dart';
import 'package:car_app/features/notification_model/ui/notification_activity.dart';
import 'package:car_app/features/home_module/ui/search_results_screen.dart';
import 'package:car_app/features/home_module/ui/all_vendors_screen.dart';
import 'package:car_app/features/categories_module/ui/all_categories_screen.dart';
import 'package:car_app/features/home_module/ui/location_picker_screen.dart';
import 'loyalty_points_screen.dart';
import '../../../design_system/components/bouncy_tap.dart';
import '../../../design_system/components/staggered_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_places_autocomplete_widgets/widgets/address_autocomplete_textfield.dart';

import '../../../Common/CommonBean.dart';
import '../../categories_module/ui/sevice_list_screen.dart';
import '../../explore_module/ui/explore_activity.dart';
import '../../workfolio_module/ui/workfolio_activity.dart';
import '../../categories_module/data_manager/categories_list_data_manager.dart';
import '../model/category_model_data.dart';
import '../model/services_model_data.dart';
import '../model/mixed_vendor_data.dart';
import '../model/notification_data_bean.dart';
import '../data_manager/home_data_manager.dart';
import 'package:car_app/features/booking_model/model/booking_list_bean.dart' as booking_bean;

class HomeActivity extends StatefulWidget {
  final GlobalKey? locationKey;
  final GlobalKey? searchKey;
  final GlobalKey? categoriesKey;
  final GlobalKey? nearbyVendorsKey;
  
  const HomeActivity({
    super.key,
    this.locationKey,
    this.searchKey,
    this.categoriesKey,
    this.nearbyVendorsKey,
  });

  @override
  State<HomeActivity> createState() => _HomeActivityState();
}

class _HomeActivityState extends State<HomeActivity> {
  String _capitalizeWords(String text) {
    if (text.trim().isEmpty) return text;
    return text
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  List<CategoryData> categoryData = [];
  List<booking_bean.Records> recentCompletedBookings = [];
  int userLoyaltyPoints = 0;
  List<ServicesData> servicesData = [];
  List<ServicesData> filteredServicesData = [];
  List<MixedVendorData> mixedVendorsData = [];
  List<MixedVendorData> filteredMixedVendorsData = [];
  List<OfferListModelData> offerListData = [];
  List<Notifications> notificationsList = [];
  HomeDataManager? dataManager;
  CategoriesListDataManager? bookmarkDataManager;
  SharedPreferences? sharedPreferences;
  List<String> offerList = ["car_image.png", "car_image.png"];
  String _searchQuery = "";
  bool _isLoading = true;
  
  // Scroll animation variables
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  double _lastScrollOffset = 0.0;
  Timer? _scrollThrottleTimer;
  bool _headerFullyCollapsed = false; // Track if header is fully collapsed to prevent unnecessary updates
  
  // User login status
  bool _isUserLoggedIn = false;
  
  // Search functionality
  Timer? _searchTimer;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Location search
  final TextEditingController _locationController = TextEditingController();
  bool _isGettingLocation = false;
  
  // User info
  String _userFirstName = "";
  String _userLastName = "";
  
  // Offers carousel
  PageController? offerPageController;
  int _currentOfferPage = 0;
  Timer? _offerTimer;

  @override
  void initState() {
    super.initState();
    offerPageController = PageController(initialPage: 0);
    // Use post-frame callback to ensure scroll controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.addListener(_onScroll);
      }
    });
    _checkUserLoginStatus();
    _initLocationController();
    start();
  }
  
  Future<void> _initLocationController() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    final currentLocation = sharedPreferences?.getString(Constant.location) ?? "Select Location";
    final firstName = sharedPreferences?.getString(Constant.firstName) ?? "";
    final lastName = sharedPreferences?.getString(Constant.lastName) ?? "";
    if (mounted) {
      setState(() {
        _locationController.text = currentLocation;
        _userFirstName = firstName;
        _userLastName = lastName;
      });
    }
  }

  @override
  void dispose() {
    _offerTimer?.cancel();
    offerPageController?.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchTimer?.cancel();
    _scrollThrottleTimer?.cancel();
    _locationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startOfferTimer() {
    _offerTimer?.cancel();
    if (offerListData.length > 1) {
      _offerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (offerPageController != null && offerPageController!.hasClients) {
          int nextPage = _currentOfferPage + 1;
          if (nextPage >= offerListData.length) {
            nextPage = 0;
          }
          offerPageController!.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutQuart,
          );
        }
      });
    }
  }
  
  Future<void> _handleManualLocationSave(String typedAddress) async {
    if (typedAddress.trim().isEmpty) return;
    
    try {
      List<geo.Location> locations = await geo.locationFromAddress(typedAddress);
      if (!mounted) return;
      if (locations.isNotEmpty) {
        double lat = locations[0].latitude;
        double lng = locations[0].longitude;
        String address = typedAddress;

        // Try to get a cleaner name
        try {
          List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(lat, lng);
          if (placemarks.isNotEmpty) {
            address = placemarks[0].locality ?? 
                     placemarks[0].subAdministrativeArea ?? 
                     typedAddress;
          }
        } catch (_) {}

        if (mounted) {
          await _saveLocation(address, lat, lng);
        }
      }
    } catch (e) {
      debugPrint('Geocoding failed for manual entry: $e');
    }
  }

  Future<void> _saveLocation(String address, double lat, double lng) async {
    sharedPreferences ??= await SharedPreferences.getInstance();

    await sharedPreferences?.setString(Constant.location, address);
    await sharedPreferences?.setString(Constant.lat, lat.toString());
    await sharedPreferences?.setString(Constant.long, lng.toString());

    // Persist location to DB only for authenticated users
    if (dataManager != null && mounted && (sharedPreferences?.getString(Constant.id) ?? "").isNotEmpty) {
      await dataManager!.syncLocationToApi(context, address, lat, lng);
    }
    
    if (!mounted) return;
    
    if (mounted) {
      setState(() {
        _locationController.text = address;
      });
      // Refresh vendors and offers with new location
      setState(() {
        _isLoading = true;
      });
      await Future.wait([
        getMixedVendors(context),
        getOffer(context),
      ]);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isGettingLocation = false;
          });
          CommonWidget.errorShowSnackBarFor(
              context, 'Location services are disabled. Please enable them.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isGettingLocation = false;
            });
            CommonWidget.errorShowSnackBarFor(
                context, 'Location permissions are denied');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isGettingLocation = false;
          });
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

      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (!mounted) return;

      String address = placemarks[0].locality ??
          placemarks[0].subAdministrativeArea ??
          placemarks[0].administrativeArea ??
          "Current Location";

      if (mounted) {
        await _saveLocation(address, position.latitude, position.longitude);
        
        setState(() {
          _isGettingLocation = false;
        });

        CommonWidget.successShowSnackBarFor(
            context, 'Location updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
        CommonWidget.errorShowSnackBarFor(
            context, 'Error getting location: ${e.toString()}');
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !mounted) return;
    
    final currentOffset = _scrollController.offset;
    final screenHeight = MediaQuery.of(context).size.height;
    double baseHeaderHeight = screenHeight * 0.22;
    if (baseHeaderHeight < 195) baseHeaderHeight = 195;
    
    // Calculate current header height based on scroll
    final double headerHeight = (baseHeaderHeight - (currentOffset * 0.6)).clamp(0.0, baseHeaderHeight);
    final bool isCollapsing = headerHeight < 20;
    
    // Update _headerFullyCollapsed state
    if (isCollapsing != _headerFullyCollapsed) {
      if (mounted) {
        setState(() {
          _headerFullyCollapsed = isCollapsing;
          _scrollOffset = currentOffset;
        });
      }
      return;
    }
    
    // If we're at the very top, ensure offset is 0
    if (currentOffset <= 0) {
      if (_scrollOffset != 0 && mounted) {
        setState(() {
          _scrollOffset = 0;
          _headerFullyCollapsed = false;
        });
      }
      return;
    }

    // Update scroll offset for smooth header shrinking
    // Use a small threshold (3px) to prevent unnecessary rebuilds while keeping it smooth
    if ((currentOffset - _scrollOffset).abs() > 3) {
      if (mounted) {
        setState(() {
          _scrollOffset = currentOffset;
        });
      }
    }
  }

  void _checkUserLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    String? userId = sharedPreferences?.getString(Constant.id);
    setState(() {
      _isUserLoggedIn = userId != null && userId.isNotEmpty;
    });
  }

  /// Silently refreshes GPS into SharedPreferences before API calls — no UI feedback, no API re-triggers.
  Future<void> _refreshLocationSilently() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      await sharedPreferences?.setString(Constant.lat, position.latitude.toString());
      await sharedPreferences?.setString(Constant.long, position.longitude.toString());

      try {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
            position.latitude, position.longitude);
        String address = placemarks[0].locality ??
            placemarks[0].subAdministrativeArea ??
            placemarks[0].administrativeArea ??
            "Current Location";
        // Always update to current GPS address on app start
        await sharedPreferences?.setString(Constant.location, address);
        if (mounted && (sharedPreferences?.getString(Constant.id) ?? "").isNotEmpty) {
          dataManager?.syncLocationToApi(context, address, position.latitude, position.longitude);
        }
        if (mounted) {
          setState(() {
            _locationController.text = address;
          });
        }
      } catch (_) {}
    } catch (_) {
      // Silently fail — proceed with whatever is already stored
    }
  }

  start() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      dataManager = HomeDataManager(sharedPreferences!);
      bookmarkDataManager = CategoriesListDataManager(sharedPreferences!);

      setState(() {
        _isLoading = true;
      });

      // Always refresh GPS coordinates on start; _refreshLocationSilently only updates
      // the display address if the user hasn't explicitly picked a location
      await _refreshLocationSilently();
      if (!mounted) return;

      // Run all API calls in parallel with timeout
      if (mounted) {
        await Future.wait<void>([
          getCategory(context).timeout(const Duration(seconds: 10), onTimeout: () {}),
          getServices(context).timeout(const Duration(seconds: 10), onTimeout: () {}),
          getOffer(context).timeout(const Duration(seconds: 10), onTimeout: () {}),
          getMixedVendors(context).timeout(const Duration(seconds: 10), onTimeout: () {}),
          getNotifications(context),
          getRecentCompletedBookings(context).timeout(const Duration(seconds: 10), onTimeout: () {}),
          getUserDetails(context).timeout(const Duration(seconds: 10), onTimeout: () {}),
        ]);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> getRecentCompletedBookings(BuildContext context) async {
    final String userId = sharedPreferences?.getString(Constant.id) ?? "";
    if (userId.isEmpty) return;
    try {
      var response = await dataManager!.getMyBookings(context);
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] != null) {
          var recordsData = body['data']['records'] as List;
          List<booking_bean.Records> fetched = recordsData
              .map((r) => booking_bean.Records.fromJson(r))
              .toList();
          
          if (mounted) {
            setState(() {
              recentCompletedBookings = fetched
                  .where((b) => b.orderStatus == 'Completed')
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch bookings: $e");
    }
  }

  Future<void> getUserDetails(BuildContext context) async {
    final String userId = sharedPreferences?.getString(Constant.id) ?? "";
    if (userId.isEmpty) return;
    try {
      var response = await dataManager!.apiFuntions.getdatauser(context, Constant.getUserDetails);
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        if (body['status'] == 'success' && body['data'] != null) {
          if (mounted) {
            setState(() {
              userLoyaltyPoints = body['data']['loyaltyPoints'] ?? 0;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch user details: $e");
    }
  }

  getNotifications(BuildContext context) async {
    if (!mounted) return;
    // Skip notifications for guest users — requires authentication
    final String userId = sharedPreferences?.getString(Constant.id) ?? "";
    if (userId.isEmpty) return;
    try {
      var response = await dataManager!.getNotification(context);
      debugPrint('🔔 Notifications API Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        var data = NotificationDataBean.fromJson(jsonDecode(response.body));
        debugPrint('🔔 Parsed Notification Data - Status: ${data.status}');
        debugPrint('🔔 Notifications Count: ${data.data?.notifications?.length ?? 0}');
        if (data.status == "success" && data.data != null) {
          if (mounted) {
            setState(() {
              notificationsList = data.data?.notifications ?? [];
              debugPrint('🔔 Updated notificationsList in state: ${notificationsList.length} items');
            });
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error getting notifications: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  void _filterServices() {
    // Cancel previous search timer
    _searchTimer?.cancel();
    
    if (_searchQuery.isEmpty) {
      // If search is empty, show all data
      setState(() {
        filteredServicesData = List.from(servicesData);
        filteredMixedVendorsData = List.from(mixedVendorsData);
        _isSearching = false;
      });
    } else {
      // Clear previous results and show searching state
      setState(() {
        filteredMixedVendorsData = [];
        _isSearching = true;
      });
      
      // Start search timer for debounced search
      _searchTimer = Timer(const Duration(milliseconds: 500), () {
        _performSearch();
      });
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) return;

    setState(() {
      _isSearching = true;
      _isLoading = true; // Show shimmer while search is in progress
    });
    
    try {
      // 1. Search for vendors using name first
      final searchResults = await dataManager!.searchVendors(context, _searchQuery);
      if (!mounted) return;

      // Navigate to search results screen
      CommonWidget.navigateToScreen(
        context,
        SearchResultsScreen(
          searchQuery: _searchQuery,
          searchResults: searchResults,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _isLoading = false;
        });
        CommonWidget.errorShowSnackBarFor(context, "Search failed. Please try again.");
      }
    }
  }


  Future<void> _loadAllServices() async {
    try {
      // Get user location for Google Places integration
      var location = await _getUserLocationData();
      if (!mounted) return;
      if (mounted) {
        var response = await dataManager!.getAllServicesWithLocation(context, location);
        if (response != null && mounted) {
          var responseData = jsonDecode(response.body);
          if (responseData['status'] == 'success' && responseData['data'] != null) {
            setState(() {
              servicesData.clear();
              final servicesList = responseData['data'] as List;
              servicesData.addAll(servicesList.map((item) => ServicesData.fromJson(item)).toList());
            });
          }
        }
      }
    } catch (e) {
    }
  }


  List<dynamic> _extractAllServicesAndVendors() {
    List<dynamic> allItems = [];
    
    for (var vendor in servicesData) {
      
      if (vendor.sId != null && !vendor.sId!.startsWith('ChIJ')) {
        // App vendor - add the vendor itself (not individual services)
        // This way SpecialistsActivity can show all services for the vendor
        allItems.add(vendor);
      } else {
        // Google Places vendor - add the vendor itself
        allItems.add(vendor);
      }
    }
    
    return allItems;
  }

  Future<Map<String, double>?> _getUserLocationData() async {
    try {
      // Try to get location from shared preferences first
      String? latStr = sharedPreferences?.getString(Constant.lat);
      String? lngStr = sharedPreferences?.getString(Constant.long);
      
      if (latStr != null && lngStr != null && latStr != "null" && lngStr != "null") {
        return {
          'lat': double.parse(latStr),
          'lng': double.parse(lngStr),
        };
      }
      
      // No stored location available
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    // Calculate animation values based on scroll offset
    // Make header height responsive to screen size
    double baseHeaderHeight = (statusBarHeight + 180).clamp(200.0, 260.0);
    double minHeaderHeight = 0.0; // Allow complete collapse
    
    // If header is fully collapsed, use cached values to prevent unnecessary calculations
    double headerHeight;
    double welcomeOpacity;
    double welcomeScale;
    
    if (_headerFullyCollapsed) {
      // Header is fully collapsed, use fixed values to prevent rebuilds
      headerHeight = 0.0;
      welcomeOpacity = 0.0;
      welcomeScale = 0.8;
    } else {
      // Calculate header height and animations only when header is visible
      headerHeight = (baseHeaderHeight - (_scrollOffset * 0.6)).clamp(minHeaderHeight, baseHeaderHeight);
      
      welcomeOpacity = 1.0 - (_scrollOffset / 80.0).clamp(0.0, 1.0);
      welcomeScale = 1.0 - (_scrollOffset / 150.0).clamp(0.0, 0.3);
    }
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
      body: Stack(
        children: [
            // Main content - Column
          Column(
              children: [
                // Green status bar background
                // Removed manual status bar container as it's handled by parent SafeArea
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Completely remove from tree when collapsed to prevent any rebuilds
                if (!_headerFullyCollapsed && headerHeight > 20)
                IgnorePointer(
                  ignoring: headerHeight < 20, // Ignore pointer events when header is collapsed
                  child: Container(
                    height: headerHeight,
                      width: double.infinity, // Ensure full width
                    decoration: const BoxDecoration(), // Required when using clipBehavior
                    clipBehavior: Clip.hardEdge, // Clip content when height is 0
                          child: Container(
                      padding: EdgeInsets.only(
                          top: statusBarHeight + 8,
                          bottom: 12,
                        left: 20,
                        right: 20
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0D1116),
                            Color(0xFF192028),
                            Color(0xFF2A3542),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF192028).withOpacity(0.4),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      // Add margin to prevent content overlap
                      margin: const EdgeInsets.only(bottom: 0),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                              // Welcome Message
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          "Welcome back 👋",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: "Pop400",
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _userFirstName.isNotEmpty || _userLastName.isNotEmpty
                                              ? "${_userFirstName.isNotEmpty ? _userFirstName : _userLastName}${_userLastName.isNotEmpty && _userFirstName.isNotEmpty ? " $_userLastName" : ""}"
                                              : "Cahrz",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontFamily: "Pop600",
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  debugPrint('🔔 Opening notifications with ${notificationsList.length} items');
                                  CommonWidget.navigateToScreen(
                                      context, NotificationActivity(notificationsList));
                                },
                                child: Container(
                                      width: 44,
                                      height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      if (notificationsList.any((n) {
                                        String? lastReadStr = sharedPreferences?.getString(Constant.lastReadNotificationsAt);
                                        if (lastReadStr == null) return true;
                                        DateTime lastRead = DateTime.parse(lastReadStr);
                                        return n.createdAt != null && DateTime.parse(n.createdAt!).isAfter(lastRead);
                                      }))
                                        Positioned(
                                          right: -4,
                                          top: -4,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 18,
                                              minHeight: 18,
                                            ),
                                            child: Builder(
                                              builder: (context) {
                                                int unreadCount = notificationsList.where((n) {
                                                  String? lastReadStr = sharedPreferences?.getString(Constant.lastReadNotificationsAt);
                                                  if (lastReadStr == null) return true;
                                                  DateTime lastRead = DateTime.parse(lastReadStr);
                                                  return n.createdAt != null && DateTime.parse(n.createdAt!).isAfter(lastRead);
                                                }).length;
                                                return Text(
                                                  '${unreadCount > 9 ? "9+" : unreadCount}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                );
                                              }
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                              const SizedBox(height: 8),
                              // Location Field - Cleaner Design
                              Container(
                                key: widget.locationKey,
                                height: 44,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                              ),
                                child: Row(
                                children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Icon(
                                        Icons.location_on,
                                        color: ColorClass.base_color,
                                        size: 18,
                                      ),
                                    ),
                                    Expanded(
                                      child: AddressAutocompleteTextField(
                                        key: const ValueKey('home_address_autocomplete'),
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 13,
                                          fontFamily: "Pop400",
                                            ),
                                        decoration: InputDecoration(
                                          hintText: "Search location...",
                                          hintStyle: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                            fontFamily: "Pop400",
                                          ),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 10,
                                          ),
                                          isDense: true,
                                          ),
                                        mapsApiKey: 'AIzaSyBFtrosISezP-8z2NwTWKhD_5pNHoi0wRw',
                                        controller: _locationController,
                                        onSuggestionClick: (place) {
                                          final address = place.formattedAddress ?? place.name ?? '';
                                          final lat = place.lat ?? 0.0;
                                          final lng = place.lng ?? 0.0;
                                          _saveLocation(address, lat, lng);
                                        },
                                        initialValue: _locationController.text,
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
                                    IconButton(
                                      icon: _isGettingLocation
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: ColorClass.base_color),
                                            )
                                          : Icon(Icons.my_location,
                                              color: ColorClass.base_color,
                                              size: 18),
                                      onPressed: _isGettingLocation
                                          ? null
                                          : _getCurrentLocation,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: "Get current location",
                                    ),
                                    const SizedBox(width: 8),
                                      ],
                                    ),
                                ),
                              const SizedBox(height: 8),
                              // Search Field
                              Container(
                                key: widget.searchKey,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                  onSubmitted: (value) {
                                    if (value.isNotEmpty) {
                                      _performSearch();
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Search for services, vendors...",
                                    hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontFamily: "Pop400",
                                      fontSize: 14,
                                    ),
                                    prefixIcon: const Icon(Icons.search, color: Color(0xFF192028)),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_searchController.text.isNotEmpty)
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                                            onPressed: () {
                                              setState(() {
                                                _searchController.clear();
                                                _searchQuery = "";
                                                filteredMixedVendorsData = List.from(mixedVendorsData);
                                                _isSearching = false;
                                              });
                                            },
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF192028)),
                                          onPressed: () {
                                            if (_searchController.text.isNotEmpty) {
                                              _performSearch();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              ],
                            ),
                          ),
                        ), // Close SingleChildScrollView
                      ),
                    ),
              // Main Content - Expanded ensures it takes remaining space after header
          Expanded(
                child: Container(
                  // Clip to prevent content from showing under header
                  decoration: const BoxDecoration(), // Required when using clipBehavior
                  clipBehavior: Clip.hardEdge,
                child: RefreshIndicator(
                  onRefresh: () async {
                    await start();
                  },
                  child: _isLoading
                    ? const Center(child: CarLoader())
                    : SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(), // Smooth scrolling
                        padding: EdgeInsets.only(
                          left: 15,
                          right: 15,
                          top: (!_headerFullyCollapsed && headerHeight > 20)
                              ? 12
                              : (_scrollOffset > 100)
                                  ? statusBarHeight + 72  // Floating header height + spacing
                                  : 0,
                          bottom: 90, // Extra padding for bottom navigation
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            // Premium Auto-Scrolling Offers Carousel
                            _buildOfferCarouselSection(),
                            const SizedBox(height: 24),

                        // Categories Grid - 2 per row, full width (No heading)
                        Container(
                          key: widget.categoriesKey,
                          child: categoryData.isNotEmpty
                              ? GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(), // Disable grid scrolling
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.35, // Taller hero-tile layout
                            ),
                            itemCount: categoryData.length > 4 ? 4 : categoryData.length, // Show max 4 categories
                      itemBuilder: (context, index) {
                              return _buildCategoryCard(categoryData[index], index);
                            },
                                )
                              : const SizedBox.shrink(),
                                  ),
                        const SizedBox(height: 20),
                        // Quick Actions - Useful Features
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                  children: [
                            StaggeredFadeIn(
                              child: _buildCircularQuickAction(
                                "My Bookings",
                                Icons.book_online_rounded,
                                () {
                                  CommonWidget.navigateToScreen(context, const BookingListActivity());
                                },
                                const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 18),
                            StaggeredFadeIn(
                              delay: const Duration(milliseconds: 60),
                              child: _buildCircularQuickAction(
                                "Bookmarks",
                                Icons.bookmark_rounded,
                                () {
                                  CommonWidget.navigateToScreen(context, const BookmarkActivity());
                                },
                                const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 18),
                            StaggeredFadeIn(
                              delay: const Duration(milliseconds: 120),
                              child: _buildCircularQuickAction(
                                "Explore Map",
                                Icons.map_rounded,
                                () {
                                  CommonWidget.navigateToScreen(context, const ExploreActivity(startWithMap: true));
                                },
                                ColorClass.base_color,
                              ),
                            ),
                            const SizedBox(width: 18),
                            StaggeredFadeIn(
                              delay: const Duration(milliseconds: 180),
                              child: _buildCircularQuickAction(
                                "Feed",
                                Icons.photo_library_rounded,
                                () {
                                  CommonWidget.navigateToScreen(context, const WorkfolioActivity());
                                },
                                const Color(0xFFEC4899),
                              ),
                            ),
                            const SizedBox(width: 18),
                            StaggeredFadeIn(
                              delay: const Duration(milliseconds: 240),
                              child: _buildCircularQuickAction(
                                "Profile",
                                Icons.person_rounded,
                                () {
                                  CommonWidget.navigateToScreen(context, const ProfileActivity());
                                },
                                const Color(0xFFA855F7),
                              ),
                            ),
                          ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLoyaltyBanner(),
                        _buildBookAgainSection(),
                        // Outlets Section (Reference Style)
                        Container(
                          key: widget.nearbyVendorsKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                            Text(
                              _searchQuery.isNotEmpty ? "Search Results" : "Outlets near you",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: "Pop500",
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_searchQuery.isEmpty)
                              TextButton(
                                onPressed: () {
                                  CommonWidget.navigateToScreen(
                                    context,
                                    const AllVendorsScreen(),
                                  );
                                },
                                child: Text(
                                  "See All",
                                  style: TextStyle(
                                    color: ColorClass.base_color,
                                    fontFamily: "Pop500",
                                  ),
                                ),
                              ),
                          ],
                          ),
                       const SizedBox(height: 12),
                               // Show vendor cards (Vertical Layout) - Using MixedVendorsData to include Google Places vendorsde Google Places vendors
                              filteredMixedVendorsData.isEmpty
                                  ? Container(
                          height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                  child: Text(
                                          "No vendors available",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: "Pop400",
                                      color: Colors.grey[500],
                                          ),
                                    ),
                                  ),
                                )
                                  : GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.75,
                                      ),
                                      itemCount: filteredMixedVendorsData.length > 6 ? 6 : filteredMixedVendorsData.length,
                                  itemBuilder: (context, index) {
                                        return _buildVendorCard(filteredMixedVendorsData[index]);
                                  },
                                    ),
                            ],
                                ),
                        ),
                       ],
                                  ),
                                ),
                              ),
              ),
                        ),
                      ],
                ),
              ),
            ],
          ),
            // Floating minimized header - overlay on top
          if (_scrollOffset > 100)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: statusBarHeight + 64,
                padding: EdgeInsets.only(
                  top: statusBarHeight,
                  left: 20,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  gradient: ModernDesignSystem.brandGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _userFirstName.isNotEmpty || _userLastName.isNotEmpty
                            ? _capitalizeWords(
                                "${_userFirstName.isNotEmpty ? _userFirstName : _userLastName}${_userLastName.isNotEmpty && _userFirstName.isNotEmpty ? " $_userLastName" : ""}")
                            : "Cahrz",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: "Pop600",
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isUserLoggedIn)
                      GestureDetector(
                        onTap: () {
                          CommonWidget.navigateToScreen(
                              context, NotificationActivity(notificationsList));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showBecomeVendorDialog();
          },
          backgroundColor: ColorClass.base_color,
          icon: const Icon(Icons.business, color: Colors.white),
          label: const Text(
            "Become a Vendor",
            style: TextStyle(
                                                    color: Colors.white,
                              fontFamily: "Pop500",
                            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String categoryTitle) {
    // Map category titles to colorful icons
    final title = categoryTitle.toLowerCase();
    
    // Car Wash - Red car with water/foam (matching reference style)
    if (title.contains('wash')) {
      return Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Red car (front-right view)
            Positioned(
              right: 2,
              child: Container(
                width: 28,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    // Car body
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Headlights
                    Positioned(
                      left: 2,
                      top: 4,
                      child: Container(
                        width: 4,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade300,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    // Wheel
                    Positioned(
                      right: 2,
                      bottom: 1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          shape: BoxShape.circle,
                        ),
                      ),
                          ),
                        ],
                ),
              ),
            ),
            // Water spray (left side)
            Positioned(
              left: 2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.blue.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.water_drop,
                  color: Colors.blue.shade600,
                  size: 12,
                ),
              ),
            ),
            // Foam bubbles
            Positioned(
              top: 6,
              left: 8,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 6,
              child: Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                      ),
                    ),
                  ],
                ),
      );
    }
    
    // Car Detailing/Polish - Blue car with sparkles (matching reference style)
    if (title.contains('detail') || title.contains('polish')) {
      return Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Blue car (front-left view)
            Positioned(
              left: 2,
              child: Container(
                width: 28,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    // Car body
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Headlights
            Positioned(
                      right: 2,
                      top: 4,
                      child: Container(
                        width: 4,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade300,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    // Windshield
                    Positioned(
                      left: 6,
                      top: 2,
                      child: Container(
                        width: 8,
                        height: 6,
                decoration: BoxDecoration(
                          color: Colors.cyan.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Wheel
                    Positioned(
                      left: 2,
                      bottom: 1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sparkles (stars)
            Positioned(
              top: 4,
              right: 8,
              child: Icon(
                Icons.star,
                color: Colors.amber.shade600,
                size: 10,
              ),
            ),
            Positioned(
              top: 8,
              right: 4,
              child: Icon(
                Icons.star,
                color: Colors.amber.shade600,
                size: 8,
              ),
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: Icon(
                Icons.star,
                color: Colors.amber.shade600,
                size: 9,
              ),
            ),
            Positioned(
              top: 12,
              right: 10,
              child: Icon(
                Icons.star,
                color: Colors.amber.shade600,
                size: 7,
              ),
            ),
            // Cloth/sponge hand
            Positioned(
              bottom: 2,
              left: 4,
              child: Icon(
                Icons.cleaning_services,
                color: Colors.brown.shade400,
                size: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    // Default colorful icon based on category
    final colors = [
      [Colors.orange.shade50, Colors.orange.shade400, Colors.orange.shade600],
      [ColorClass.base_light_color, ColorClass.base_color, ColorClass.base_color],
      [Colors.pink.shade50, Colors.pink.shade400, Colors.pink.shade600],
      [Colors.teal.shade50, Colors.teal.shade400, Colors.teal.shade600],
      [Colors.amber.shade50, Colors.amber.shade400, Colors.amber.shade600],
      [Colors.purple.shade50, Colors.purple.shade400, Colors.purple.shade600],
      [Colors.cyan.shade50, Colors.cyan.shade400, Colors.cyan.shade600],
    ];
    final colorIndex = categoryTitle.hashCode.abs() % colors.length;
    final colorSet = colors[colorIndex];
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorSet[0], colorSet[1]],
        ),
      ),
      child: Icon(
        Icons.local_car_wash,
        color: colorSet[2],
        size: 32,
      ),
    );
  }

  String? _getServiceImage(ServicesData service) {
    // Try to get image from first service
    if (service.services.isNotEmpty && service.services.first.coverImage != null && service.services.first.coverImage!.isNotEmpty) {
      return service.services.first.coverImage;
    }
    // Fallback to vendor display picture
    return service.displayPicture;
  }

  String _getServiceRating(ServicesData service) {
    // Try to get rating from first service
    if (service.services.isNotEmpty && service.services.first.averageRating != null && service.services.first.averageRating! > 0) {
      // Rating is stored as integer (e.g., 49 for 4.9), so divide by 10
      return (service.services.first.averageRating! / 10).toStringAsFixed(1);
    }
    return "4.9"; // Default rating
  }

  String _getServiceName(ServicesData service) {
    // Try to get name from first service
    if (service.services.isNotEmpty && service.services.first.serviceTitle != null && service.services.first.serviceTitle!.isNotEmpty) {
      return service.services.first.serviceTitle!;
    }
    // Fallback to vendor display name
    return service.displayName ?? "Service";
  }

  Widget _buildServiceCard(ServicesData service) {
    return GestureDetector(
      onTap: () {
        // Navigate to vendor page - sId is the vendor ID
        String? vendorId = service.sId;
        if (vendorId == null || vendorId.isEmpty) {
          // Fallback: try to get vendorId from first service if available
          vendorId = service.services.isNotEmpty && service.services.first.vendorId != null
              ? service.services.first.vendorId
              : null;
        }
        
        // Check if this is a Google Places vendor (ID starts with "ChIJ")
        bool isGooglePlacesVendor = vendorId != null && vendorId.startsWith('ChIJ');
        bool isAppVendor = service.isAppVendor ?? true; // Default to true if not set
        
        if (vendorId != null && vendorId.isNotEmpty && vendorId.trim().isNotEmpty) {
          if (isGooglePlacesVendor || !isAppVendor) {
            // Google Places vendor - show detail page with options
            // Create a temporary MixedVendorData for the detail page
            final googleVendor = MixedVendorData(
              id: vendorId,
              name: service.displayName ?? "Vendor",
              address: service.location?.name ?? "",
              rating: 4.5,
              reviewCount: 0,
              latitude: service.location?.lat ?? 0.0,
              longitude: service.location?.lng ?? 0.0,
              imageUrl: service.displayPicture,
              phone: service.mobile,
              isOpen: service.isShopOpen ?? true,
              distance: service.distance ?? 0.0,
              isAppVendor: false,
            );
            _handleGoogleVendorTap(googleVendor);
          } else {
            // App vendor - navigate to detail page
            CommonWidget.navigateToScreen(
              context,
              SpecialistsActivity(vendorId),
            );
          }
        } else {
          CommonWidget.errorShowSnackBarFor(context, "Unable to load vendor details. Invalid vendor ID.");
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
                  children: [
              // Service Image
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[200],
                child: _getServiceImage(service) != null && _getServiceImage(service)!.isNotEmpty
                    ? Image.network(
                        _getServiceImage(service)!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        headers: const {
                          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
                            ),
                          ),
                        );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.local_car_wash,
                              size: 48,
                              color: Colors.grey[500],
                            ),
                          );
                        },
                        cacheWidth: 160,
                        cacheHeight: 200,
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.local_car_wash,
                          size: 48,
                          color: Colors.grey[500],
                        ),
                      ),
              ),
              // Rating Badge (Top Left)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                      child: Row(
                    mainAxisSize: MainAxisSize.min,
                        children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber[300],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getServiceRating(service),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: "Pop600",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bookmark Icon (Top Right)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    // Toggle bookmark
                    // TODO: Implement bookmark toggle
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                            ),
                            child: const Icon(
                      Icons.bookmark_border,
                      size: 18,
                              color: Colors.white,
                    ),
                  ),
                            ),
                          ),
              // Service Name Label (Bottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                            child: Text(
                    _getServiceName(service),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                      fontFamily: "Pop600",
                      fontWeight: FontWeight.bold,
                              ),
                    maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
      ),
    );
  }

  Widget _buildBookAgainSection() {
    if (recentCompletedBookings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Book Again?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: "Pop600",
                color: Colors.black87,
              ),
            ),
            Text(
              "Based on history",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontFamily: "Pop400",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentCompletedBookings.length > 5 ? 5 : recentCompletedBookings.length,
            itemBuilder: (context, index) {
              final booking = recentCompletedBookings[index];
              return Container(
                width: 250,
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    // Service Image/Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: ColorClass.base_light_color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: booking.serviceImage != null && booking.serviceImage!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(booking.serviceImage!, fit: BoxFit.cover),
                            )
                          : Icon(Icons.car_repair, color: ColorClass.base_color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            booking.serviceTitle ?? "Car Service",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Pop600",
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.vendorDisplayName ?? "My Vendor",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: "Pop400",
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (booking.vendorId != null) {
                                CommonWidget.navigateToScreen(
                                  context,
                                  SpecialistsActivity(booking.vendorId!),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorClass.base_color,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              minimumSize: const Size(80, 26),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Book Again",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLoyaltyBanner() {
    if (!_isUserLoggedIn) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        CommonWidget.navigateToScreen(
          context,
          LoyaltyPointsScreen(points: userLoyaltyPoints),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Cahrz Loyalty Club",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Pop600",
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "You have $userLoyaltyPoints loyalty points",
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontSize: 12,
                      fontFamily: "Pop400",
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryData category, int index) {
    final title = (category.categoryTitle ?? "").toLowerCase();
    final isWash = title.contains('wash');
    final isDetailing = title.contains('detail') || title.contains('polish');

    final List<Color> gradientColors = isWash
        ? [const Color(0xFF3B82F6), const Color(0xFF2563EB)]
        : isDetailing
            ? [const Color(0xFFA855F7), const Color(0xFF7C3AED)]
            : [Colors.grey.shade500, Colors.grey.shade700];
    final IconData categoryIcon = isWash
        ? Icons.local_car_wash_rounded
        : isDetailing
            ? Icons.auto_awesome_rounded
            : Icons.category_rounded;

    return StaggeredFadeIn(
      delay: Duration(milliseconds: 60 * index),
      child: BouncyTap(
        onTap: () {
          CommonWidget.navigateToScreen(
            context,
            CategoriesListActivity(category),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Decorative oversized watermark icon
                Positioned(
                  right: -14,
                  bottom: -14,
                  child: Icon(
                    categoryIcon,
                    size: 84,
                    color: Colors.white.withOpacity(0.14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(categoryIcon, color: Colors.white, size: 24),
                      ),
                      const Spacer(),
                      Text(
                        category.categoryTitle ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: "Pop600",
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            "Explore",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: "Pop500",
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularQuickAction(String title, IconData icon, VoidCallback onTap, Color color) {
    final hsl = HSLColor.fromColor(color);
    final Color deeper = hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor();

    return BouncyTap(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, deeper],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: "Pop500",
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, VoidCallback onTap, {Color? iconColor, Color? backgroundColor}) {
    final defaultIconColor = iconColor ?? ColorClass.base_color;
    final defaultBackgroundColor = backgroundColor ?? ColorClass.base_color.withOpacity(0.1);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ModernDesignSystem.animationFast,
        curve: ModernDesignSystem.animationCurve,
        padding: const EdgeInsets.all(ModernDesignSystem.spacingL),
        decoration: ModernDesignSystem.modernCard(
          borderRadius: ModernDesignSystem.radiusL,
          shadows: ModernDesignSystem.shadowMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: defaultBackgroundColor,
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusRound),
                boxShadow: ModernDesignSystem.getColoredShadow(defaultIconColor, opacity: 0.1),
              ),
              child: Icon(
                icon,
                color: defaultIconColor,
                size: 28,
              ),
            ),
            const SizedBox(height: ModernDesignSystem.spacingM),
            Text(
              title,
              style: ModernDesignSystem.bodyMedium(
                color: Colors.black87,
              ).copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCard(MixedVendorData vendor) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          if (vendor.isAppVendor) {
            if (vendor.id.isNotEmpty && vendor.id.trim().isNotEmpty) {
                CommonWidget.navigateToScreen(
                  context,
                  SpecialistsActivity(vendor.id),
                );
            } else {
              CommonWidget.errorShowSnackBarFor(context, "Unable to load vendor details. Invalid vendor ID.");
              }
          } else {
            // Google Places vendor - show detail page with call and navigate options
            _handleGoogleVendorTap(vendor);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Full image background
                vendor.imageUrl != null && vendor.imageUrl!.isNotEmpty
                      ? Image.network(
                          vendor.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              vendor.isAppVendor ? Icons.local_car_wash : Icons.location_on,
                              size: 64,
                              color: vendor.isAppVendor ? ColorClass.base_color : Colors.blue,
                            ),
                            );
                          },
                          headers: const {
                            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                          },
                        )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(
                          vendor.isAppVendor ? Icons.local_car_wash : Icons.location_on,
                          size: 64,
                          color: vendor.isAppVendor ? ColorClass.base_color : Colors.blue,
                        ),
                ),
                // Open/Closed Badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: vendor.isOpen ? ColorClass.base_color.withOpacity(0.9) : Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vendor.isOpen ? "OPEN" : "CLOSED",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontFamily: "Pop600",
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Gradient overlay at bottom for text readability
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.85),
                          Colors.black.withOpacity(0.95),
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vendor.name ?? "Unknown Shop",
                      style: const TextStyle(
                        fontSize: 16,
                          fontFamily: "Pop600",
                        fontWeight: FontWeight.bold,
                            color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                              size: 12,
                              color: Colors.white.withOpacity(0.9),
                        ),
                      const SizedBox(width: 4),
                        Expanded(
                        child: Text(
                            vendor.address ?? "Address not available",
                          style: TextStyle(
                                  fontSize: 12,
                              fontFamily: "Pop400",
                                  color: Colors.white.withOpacity(0.9),
                          ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                ),
                        ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (vendor.rating != null && vendor.rating! > 0) ...[
                              Icon(
                                Icons.star,
                                size: 13,
                                color: Colors.amber[300],
                              ),
                              const SizedBox(width: 3),
                Text(
                                vendor.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: "Pop500",
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Icon(
                              Icons.location_on_outlined,
                              size: 11,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "${(vendor.distance * 0.000621371).toStringAsFixed(1)} miles",
                  style: TextStyle(
                                fontSize: 11,
                    fontFamily: "Pop400",
                                color: Colors.white.withOpacity(0.9),
                  ),
                        ),
                      ],
                ),
                    const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                      children: [
                            if (vendor.isAppVendor)
                        Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                  children: [
                                    Icon(
                                Icons.local_car_wash,
                                      size: 11,
                                      color: Colors.white,
                    ),
                                    SizedBox(width: 3),
                    Text(
                                      "5 Cars",
                                      style: TextStyle(
                                        fontSize: 9,
                                  fontFamily: "Pop400",
                                        color: Colors.white,
                                ),
                              ),
                            ],
                      ),
                    ),
                        Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                  Icon(
                                Icons.eco,
                                    size: 11,
                                    color: Colors.white,
                              ),
                                  SizedBox(width: 3),
                                  Text(
                                    "Eco",
                      style: TextStyle(
                                      fontSize: 9,
                                  fontFamily: "Pop400",
                                      color: Colors.white,
                      ),
                    ),
                            ],
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
        ),
      ),
    );
  }

  Widget _buildEmptyVendorsState() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No vendors nearby",
              style: TextStyle(
                fontSize: 18,
                fontFamily: "Pop600",
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We're working on adding more vendors in your area",
              style: TextStyle(
                fontSize: 14,
                fontFamily: "Pop400",
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                if (mounted) {
                  setState(() {
                    _isLoading = true;
                  });
                  await getMixedVendors(context);
                }
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text("Refresh", style: TextStyle(fontFamily: "Pop500")),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorClass.base_color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
                                ],
                              ),
                            ),
                          );
  }

  // Build Full Width Offer Card for Carousel
  Widget _buildOfferCarouselSection() {
    if (offerListData.isEmpty) {
      return Padding(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/ChatGPT Image Aug 17, 2026, 04_13_05 AM.png',
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Hot Deals Near You",
            style: TextStyle(
              fontSize: 16,
              fontFamily: "Pop600",
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: offerPageController,
            itemCount: offerListData.length,
            onPageChanged: (index) {
              setState(() {
                _currentOfferPage = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildOfferBannerItem(offerListData[index]);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Pagination dots
        if (offerListData.length > 1)
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                offerListData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentOfferPage == index ? 18 : 6,
                  decoration: BoxDecoration(
                    color: _currentOfferPage == index 
                        ? ColorClass.base_color 
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOfferBannerItem(OfferListModelData offer) {
    // Determine the vendor ID from either the vendor field or the joined vendorData
    String? vendorId = offer.vendor;
    if ((vendorId == null || vendorId.isEmpty) && offer.vendorData != null) {
      vendorId = offer.vendorData!.id;
    }

    return GestureDetector(
      onTap: () {
        if (vendorId != null && vendorId.isNotEmpty) {
          CommonWidget.navigateToScreen(
            context, 
            SpecialistsActivity(vendorId)
          );
        } else {
          CommonWidget.errorShowSnackBarFor(context, "Vendor details not available");
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full background image
              offer.image != null && offer.image!.isNotEmpty
                  ? Image.network(
                      offer.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: ColorClass.base_color.withOpacity(0.1),
                        child: Icon(Icons.local_offer, color: ColorClass.base_color, size: 40),
                      ),
                    )
                  : Container(
                      color: ColorClass.base_color.withOpacity(0.1),
                      child: Icon(Icons.local_offer, color: ColorClass.base_color, size: 40),
                    ),
              
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.4, 0.6, 1.0],
                  ),
                ),
              ),
              
              // Offer Badge (Top Right)
              if (offer.discount != null && offer.discount! > 0)
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ColorClass.base_color, ColorClass.base_color.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "${offer.discount}% OFF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                
              // Info Overlay (Bottom)
              Positioned(
                bottom: 15,
                left: 15,
                right: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      offer.title ?? "Special Offer",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: "Pop600",
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: ColorClass.base_color, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          offer.distance != null 
                              ? "${(offer.distance! / 1609.344).toStringAsFixed(1)} miles away"
                              : "Near you",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontFamily: "Pop400",
                          ),
                        ),
                      ],
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

  Widget _buildFullWidthOfferCard(OfferListModelData offer) {
    return GestureDetector(
      onTap: () {
        if (offer.vendor != null && offer.vendor!.isNotEmpty) {
          CommonWidget.navigateToScreen(
            context,
            SpecialistsActivity(offer.vendor!),
          );
        } else {
          CommonWidget.errorShowSnackBarFor(context, "Vendor details not available for this offer.");
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build Offer Card (keeping for compatibility if needed elsewhere)
  Widget _buildOfferCard(OfferListModelData offer) {
    // Add null safety check
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          if (offer.vendor != null && offer.vendor!.isNotEmpty) {
            CommonWidget.navigateToScreen(
              context,
              SpecialistsActivity(offer.vendor!),
            );
          } else {
            CommonWidget.errorShowSnackBarFor(context, "Vendor details not available for this offer.");
          }
        },
        child: Container(
          width: 280,
          margin: const EdgeInsets.only(right: 16),
          decoration: ModernDesignSystem.modernCard(
            borderRadius: ModernDesignSystem.radiusL,
            shadows: ModernDesignSystem.shadowMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Optimize layout
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(ModernDesignSystem.radiusL),
                  topRight: Radius.circular(ModernDesignSystem.radiusL),
                ),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  color: ColorClass.base_color.withOpacity(0.1),
                  child: const Icon(
                    Icons.local_offer,
                    size: 48,
                    color: Colors.orange,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      offer.title ?? "Special Offer",
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: "Pop600",
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.description ?? "Limited time offer",
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: "Pop400",
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  void _showBecomeVendorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Become a Vendor",
            style: TextStyle(
              fontFamily: "Pop600",
              fontSize: 20,
            ),
          ),
          content: const Text(
            "Join our platform as a car service provider and start growing your business!",
            style: TextStyle(
              fontFamily: "Pop400",
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => CommonWidget.safePop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  fontFamily: "Pop500",
                  color: Colors.grey,
                ),
              ),
            ),
              ElevatedButton(
              onPressed: () async {
                CommonWidget.safePop(context);
                // Open iOS App Store link for Cahrz Vendor app
                // This will open the App Store app on iOS devices
                final Uri url = Uri.parse('https://apps.apple.com/us/app/cahrz-vendor/id6749635800');
                try {
                  if (await canLaunchUrl(url)) {
                    // Use externalApplication mode to open in App Store app on iOS
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      CommonWidget.errorShowSnackBarFor(context, "Could not open App Store");
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    CommonWidget.errorShowSnackBarFor(context, "Error opening App Store: $e");
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorClass.base_color,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "Download Vendor App",
                style: TextStyle(
                  fontFamily: "Pop500",
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        CommonWidget.successShowSnackBarFor(context, "Could not open the link");
      }
    }
  }

  Future<void> getCategory(BuildContext context) async {
    try {
    var response = await dataManager!.getcategory(context);
      if (!mounted) return;
      if (response != null && mounted) {
        var responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' && responseData['data'] != null) {
      setState(() {
        categoryData.clear();
            categoryData.addAll((responseData['data'] as List)
                .map((item) => CategoryData.fromJson(item))
                .toList());
          });
        }
      }
    } catch (e) {
    }
  }

  Future<void> getServices(BuildContext context) async {
    try {
    var response = await dataManager!.getAllServices(context);
      if (!mounted) return;
      if (response != null && mounted) {
        var responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' && responseData['data'] != null) {
      setState(() {
        servicesData.clear();
            final servicesList = responseData['data'] as List;
            servicesData.addAll(servicesList.map((item) => ServicesData.fromJson(item)).toList());
          filteredServicesData = List.from(servicesData);
        });
        }
      }
    } catch (e) {
      // Continue without services if API fails
    }
  }

  Future<void> getOffer(BuildContext context) async {
    try {
      var response = await dataManager!.getOffer(context);
      if (!mounted) return;
      if (response != null && mounted) {
        var responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          // Get user location for distance calculation
          final userLocation = _getUserLocation();
          
          // 50 miles = 80,467 meters
          const double maxDistanceMeters = 80467;
          
          setState(() {
            offerListData.clear();
            
            // Handle different data structures (Direct list or nested in 'offers' key)
            dynamic rawData = responseData['data'];
            List<dynamic> offersJson = [];
            
            if (rawData is List) {
              offersJson = rawData;
            } else if (rawData is Map && rawData['offers'] is List) {
              offersJson = rawData['offers'];
            } else if (rawData is Map && rawData['data'] is List) {
              offersJson = rawData['data'];
            }
            
            for (var offerJson in offersJson) {
              if (offerJson != null) {
                try {
                  final offer = OfferListModelData.fromJson(offerJson);
                  
                  // Calculate distance if location is available for sorting
                  if (userLocation != null && offer.location?.coordinates != null) {
                    final userLat = userLocation['lat']!;
                    final userLng = userLocation['lng']!;
                    final offerLat = offer.location!.coordinates!.lat;
                    final offerLng = offer.location!.coordinates!.long;
                    
                    if (offerLat != null && offerLng != null) {
                      offer.distance = MixedVendorData.calculateDistanceBetween(
                        userLat, userLng, offerLat, offerLng
                      );
                    }
                  }
                  
                  // Only show offers that are near the user (within 50 miles / 80467 meters)
                  if (offer.distance == null || offer.distance! <= maxDistanceMeters) {
                    offerListData.add(offer);
                  } else {
                    debugPrint("Filtered out offer '${offer.title}' because it is ${offer.distance! / 1000} km away.");
                  }
                } catch (e, st) {
                  debugPrint("Error parsing individual offer: $e\n$st");
                }
              }
            }
            
            // Sort offers by distance (closest first)
            if (offerListData.isNotEmpty) {
              offerListData.sort((a, b) => 
                (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity)
              );
              // Restart auto-scroll timer after data load
              _startOfferTimer();
            }
            debugPrint("FETCHED OFFERS: ${offerListData.length}");
          });
        }
      }
    } catch (e) {
      // Continue without offers if API fails
      debugPrint("OFFER ERROR: $e");
    }
  }

  Future<void> getMixedVendors(BuildContext context) async {
    try {
      final vendors = await dataManager!.getMixedVendors(context);
      if (!mounted) return;
      
      // Calculate distances for all vendors if location is available
      final userLocation = _getUserLocation();
      
      if (userLocation != null) {
        final userLat = userLocation['lat']!;
        final userLng = userLocation['lng']!;
        
        for (var vendor in vendors) {
          if (vendor.latitude != 0 && vendor.longitude != 0) {
            vendor.distance = MixedVendorData.calculateDistanceBetween(
              userLat, userLng, vendor.latitude, vendor.longitude
            );
          }
        }
      }
      
      if (mounted) {
        setState(() {
          mixedVendorsData.clear();
          mixedVendorsData.addAll(vendors);
          filteredMixedVendorsData = List.from(mixedVendorsData);
        });
      }
      
    } catch (e) {
      // Continue without vendors if API fails
    }
  }

  Map<String, double>? _getUserLocation() {
    try {
      final latStr = sharedPreferences?.getString(Constant.lat);
      final lngStr = sharedPreferences?.getString(Constant.long);
      
      if (latStr != null && lngStr != null && latStr != "null" && lngStr != "null") {
        return {
          'lat': double.parse(latStr),
          'lng': double.parse(lngStr),
        };
      }
      
      // No stored location available
      return null;
    } catch (e) {
      return null;
    }
  }

  void _handleGoogleVendorTap(MixedVendorData vendor) {
    // Navigate to a full-screen detail page for Google Places vendors
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _GooglePlacesDetailPage(vendor: vendor),
                ),
        );
  }

  void _showLoginRequiredDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            "Login Required",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewLoginActivity(returnToPrevious: true),
                  ),
                ).then((value) {
                  if (value == true) {
                    // Refresh state if needed
                  }
                });
              },
              child: const Text("Log In"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openInMaps(MixedVendorData vendor) async {
    final String userId = sharedPreferences?.getString(Constant.id) ?? "";
    if (userId.isEmpty) {
      _showLoginRequiredDialog(context, "Sign in to view directions.");
      return;
    }
    // Open the vendor location in Google Maps
    final lat = vendor.latitude;
    final lng = vendor.longitude;
    final name = Uri.encodeComponent(vendor.name);
    
    // Use Google Maps URL with place ID if available, otherwise use coordinates
    String url;
    if (vendor.id.startsWith('ChIJ')) {
      // Google Places ID - use place_id parameter
      url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=${vendor.id}";
    } else {
      // Use coordinates and name
      url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$name";
    }
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        CommonWidget.errorShowSnackBarFor(context, "Could not open Maps");
      }
    } catch (e) {
      CommonWidget.errorShowSnackBarFor(context, "Could not open Maps");
    }
  }

  Future<void> _toggleBookmark(MixedVendorData vendor) async {
    try {
      if (vendor.isBookmarked) {
        // Remove bookmark
        var response = await bookmarkDataManager!.removeBookmark(context, vendor.id);
        if (!mounted) return;
        var data = jsonDecode(response.body);
        if (data['status'] == "success" && mounted) {
          setState(() {
            vendor.isBookmarked = false;
          });
          CommonWidget.successShowSnackBarFor(context, "Removed from bookmarks");
        } else if (mounted) {
          CommonWidget.errorShowSnackBarFor(context, data['message'] ?? "Failed to remove bookmark");
        }
      } else {
        // Add bookmark
        var response = await bookmarkDataManager!.postBookmark(context, vendor.id);
        if (!mounted) return;
        var data = jsonDecode(response.body);
        if (data['status'] == "success" && mounted) {
          setState(() {
            vendor.isBookmarked = true;
          });
          CommonWidget.successShowSnackBarFor(context, "Added to bookmarks");
        } else if (mounted) {
          CommonWidget.errorShowSnackBarFor(context, data['message'] ?? "Failed to add bookmark");
        }
      }
    } catch (e) {
      if (mounted) CommonWidget.errorShowSnackBarFor(context, "Error updating bookmark");
    }
  }

  Widget _buildSearchingState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
            ),
            const SizedBox(height: 16),
            Text(
              "Searching...",
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Pop500",
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Finding vendors for \"$_searchQuery\"",
              style: TextStyle(
                fontSize: 14,
                fontFamily: "Pop400",
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No results found",
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Pop500",
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No vendors found for \"$_searchQuery\"\nTry a different search term",
              style: TextStyle(
                fontSize: 14,
                fontFamily: "Pop400",
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorsSection() {
    if (filteredMixedVendorsData.isEmpty) {
      return _buildEmptyVendorsState();
    }
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(), // Prevent scroll conflicts
        cacheExtent: 500, // Cache more items for smoother scrolling
        addAutomaticKeepAlives: false, // Don't keep widgets alive when off-screen
        addRepaintBoundaries: true, // Add repaint boundaries automatically
        itemCount: filteredMixedVendorsData.length,
        itemBuilder: (context, index) {
          final vendor = filteredMixedVendorsData[index];
          // Use key for better widget recycling
          return _buildVendorCard(vendor);
        },
      ),
    );
  }

}

// Google Places Detail Page Widget
class _GooglePlacesDetailPage extends StatelessWidget {
  final MixedVendorData vendor;

  const _GooglePlacesDetailPage({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: CommonWidget.buildAppBarBackButton(
            context,
            iconColor: Colors.black87,
          ),
          title: Text(
            vendor.name,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontFamily: "Pop600",
            ),
          ),
        ),
        body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            // Vendor Image
            SizedBox(
              width: double.infinity,
              height: 250,
              child: vendor.imageUrl != null && vendor.imageUrl!.isNotEmpty
                  ? Image.network(
                      vendor.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.location_on, size: 64, color: Colors.blue),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.location_on, size: 64, color: Colors.blue),
                    ),
            ),
            
            // Vendor Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vendor.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontFamily: "Pop600",
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Rating
                  if (vendor.rating != null)
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[600], size: 20),
                        const SizedBox(width: 4),
                        Text(
                          vendor.rating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: "Pop500",
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Address
                  if (vendor.address != null && vendor.address!.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            vendor.address!,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: "Pop400",
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Phone
                  if (vendor.phone != null && vendor.phone!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.phone, color: ColorClass.base_color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          vendor.phone!,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Pop400",
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _openInMapsFromDetailPage(context, vendor);
                          },
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text("Open in Maps"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorClass.base_color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                            _callVendorFromDetailPage(context, vendor);
                            },
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text("Call"),
                            style: ElevatedButton.styleFrom(
                            backgroundColor: ColorClass.base_color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // About Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "About this location",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: "Pop600",
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "This is a Google Places location. You can navigate to this location or call them directly for more information about their services.",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Pop400",
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cahrz Merchant Partnership and Onboarding Section
                  _buildCahrzPartnerCard(context),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCahrzPartnerCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1116), Color(0xFF192028)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1116).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    "Claim this Business",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Pop600",
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "PARTNER",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 9,
                    fontFamily: "Pop600",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Subtext
          Text(
            "This business is not registered on Cahrz yet. Recommend them to claim their profile to receive direct customer bookings and grow online!",
            style: TextStyle(
              fontSize: 13,
              fontFamily: "Pop400",
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Grid of benefits (glassmorphic cards)
          Row(
            children: [
              Expanded(
                child: _buildBenefitChip(Icons.percent_rounded, "0% Commission"),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBenefitChip(Icons.calendar_today_rounded, "Direct Booking"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildBenefitChip(Icons.analytics_rounded, "Live Analytics"),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBenefitChip(Icons.bolt_rounded, "Instant Payouts"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final box = context.findRenderObject() as RenderBox?;
                    final shareText = "Hey! I found your business \"${vendor.name}\" on Google Places and would love to book your car services directly on Cahrz.\n\n"
                        "Register on Cahrz Vendor to manage bookings, keep 100% of your earnings, and get direct local customers!\n\n"
                        "Download the Cahrz Vendor App:\n"
                        "iOS: https://apps.apple.com/in/app/cahrz-vendor/id6749635800\n"
                        "Android: https://play.google.com/store/apps/details?id=com.cahrz.vendor\n"
                        "Or register online: https://vendor.cahrz.com";
                    Share.share(
                      shareText,
                      subject: "Join Cahrz as a Partner Vendor!",
                      sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
                    );
                  },
                  icon: Icon(Icons.share_rounded, size: 18, color: ColorClass.base_color),
                  label: Text(
                    "Share Invite",
                    style: TextStyle(
                      fontFamily: "Pop600",
                      color: ColorClass.base_color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ColorClass.base_color,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showQrCodeDialog(context),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    "Show QR Code",
                    style: TextStyle(
                      fontFamily: "Pop600",
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: "Pop500",
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showQrCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Scan to Register",
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: "Pop600",
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // QR Code Container with nice borders and shadow
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=https%3A%2F%2Fapps.apple.com%2Fin%2Fapp%2Fcahrz-vendor%2Fid6749635800",
                        width: 180,
                        height: 180,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            width: 180,
                            height: 180,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 180,
                            height: 180,
                            color: Colors.grey[100],
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_2_rounded, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text("QR unavailable", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Onboarding Steps
                const Text(
                  "How to claim your profile:",
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: "Pop600",
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStepRow("1", "Show this QR code to the business owner/manager."),
                _buildStepRow("2", "Let them scan it with their phone camera."),
                _buildStepRow("3", "They'll land on our registration portal to claim this profile!"),
                const SizedBox(height: 24),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: "https://apps.apple.com/in/app/cahrz-vendor/id6749635800"));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Registration link copied to clipboard!"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text("Copy Link"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorClass.base_color,
                          side: BorderSide(color: ColorClass.base_color),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorClass.base_color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Done"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: ColorClass.base_color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 11,
                fontFamily: "Pop600",
                color: ColorClass.base_color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontFamily: "Pop400",
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _openInMapsFromDetailPage(BuildContext context, MixedVendorData vendor) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString(Constant.id) ?? "";
    if (userId.isEmpty) {
      _showLoginRequiredDialog(context, "Sign in to view directions.");
      return;
    }
    final lat = vendor.latitude;
    final lng = vendor.longitude;
    
    String url;
    if (vendor.id.startsWith('ChIJ')) {
      url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=${vendor.id}";
    } else {
      url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    }
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        CommonWidget.errorShowSnackBarFor(context, "Could not open Maps");
      }
    } catch (e) {
      CommonWidget.errorShowSnackBarFor(context, "Could not open Maps");
    }
  }

  static Future<void> _callVendorFromDetailPage(BuildContext context, MixedVendorData vendor) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString(Constant.id) ?? "";
    if (userId.isEmpty) {
      _showLoginRequiredDialog(context, "Sign in to call this vendor.");
      return;
    }
    if (vendor.phone != null && vendor.phone!.isNotEmpty) {
      final uri = Uri.parse('tel:${vendor.phone}');
      launchUrl(uri, mode: LaunchMode.externalApplication).catchError((e) {
        CommonWidget.errorShowSnackBarFor(context, "Could not make phone call");
        return false;
      });
    } else {
      CommonWidget.errorShowSnackBarFor(context, "Phone number not available");
    }
  }

  static void _showLoginRequiredDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            "Login Required",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewLoginActivity(returnToPrevious: true),
                  ),
                ).then((value) {
                  if (value == true) {
                    // Do nothing, state should refresh if they try the action again
                  }
                });
              },
              child: const Text("Log In"),
            ),
          ],
        );
      },
    );
  }
}