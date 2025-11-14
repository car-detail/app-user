import 'dart:async';
import 'dart:convert';

import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/ShimmerLoader.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/categories_module/ui/categories_list_activity.dart';
import 'package:car_app/features/categories_module/ui/sevice_list_screen.dart';
import 'package:car_app/features/home_module/data_manager/home_data_manager.dart';
import 'package:car_app/features/home_module/model/offer_list_model.dart';
import 'package:car_app/features/specialists_module/ui/specialists_activity.dart';
import 'package:car_app/features/booking/ui/booking_activity.dart';
import 'package:car_app/features/booking_model/ui/booking_list_activity.dart';
import 'package:car_app/features/explore_module/ui/explore_list_map_activity.dart';
import 'package:car_app/features/bookmark_model/ui/bookmark_activity.dart';
import 'package:car_app/features/log_in/ui/profile_activity.dart';
import 'package:car_app/features/notification_model/ui/notification_activity.dart';
import 'package:car_app/features/home_module/ui/search_results_screen.dart';
import 'package:car_app/features/home_module/ui/all_vendors_screen.dart';
import 'package:car_app/features/categories_module/ui/all_categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Common/CommonBean.dart';
import '../../categories_module/ui/sevice_list_screen.dart';
import '../../explore_module/ui/explore_activity.dart';
import '../../categories_module/data_manager/categories_list_data_manager.dart';
import '../model/category_model_data.dart';
import '../model/services_model_data.dart';
import '../model/mixed_vendor_data.dart';
import '../data_manager/home_data_manager.dart';

class HomeActivity extends StatefulWidget {
  const HomeActivity({super.key});

  @override
  State<HomeActivity> createState() => _HomeActivityState();
}

class _HomeActivityState extends State<HomeActivity> {
  List<CategoryData> categoryData = [];
  List<ServicesData> servicesData = [];
  List<ServicesData> filteredServicesData = [];
  List<MixedVendorData> mixedVendorsData = [];
  List<MixedVendorData> filteredMixedVendorsData = [];
  List<OfferListModelData> offerListData = [];
  HomeDataManager? dataManager;
  CategoriesListDataManager? bookmarkDataManager;
  SharedPreferences? sharedPreferences;
  List<String> offerList = ["car_image.png", "car_image.png"];
  String _searchQuery = "";
  bool _isLoading = true;
  
  // Scroll animation variables
  ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  
  // User login status
  bool _isUserLoggedIn = false;
  
  // Search functionality
  Timer? _searchTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkUserLoginStatus();
    start();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  void _checkUserLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    String? userId = sharedPreferences?.getString(Constant.id);
    setState(() {
      _isUserLoggedIn = userId != null && userId.isNotEmpty;
    });
  }

  start() async {
    try {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = HomeDataManager(sharedPreferences!);
    bookmarkDataManager = CategoriesListDataManager(sharedPreferences!);
      
      setState(() {
        _isLoading = true;
      });
      
      // Run all API calls in parallel with timeout
      await Future.wait<void>([
        getCategory(context).timeout(Duration(seconds: 10), onTimeout: () {
          print('Category API timeout');
        }),
        getServices(context).timeout(Duration(seconds: 10), onTimeout: () {
          print('Services API timeout');
        }),
        getOffer(context).timeout(Duration(seconds: 10), onTimeout: () {
          print('Offer API timeout');
        }),
        getMixedVendors(context).timeout(Duration(seconds: 10), onTimeout: () {
          print('Mixed vendors API timeout');
        }),
      ]);
    } catch (e) {
      print('Error in start method: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      _searchTimer = Timer(Duration(milliseconds: 500), () {
        _performSearch();
      });
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      // Search using backend API
      final searchResults = await dataManager!.searchVendors(context, _searchQuery);
      
      setState(() {
        _isSearching = false;
      });
      
      print('Search completed for "$_searchQuery": ${searchResults.length} results');
      
      // Navigate to search results screen
      CommonWidget.navigateToScreen(
        context,
        SearchResultsScreen(
          searchQuery: _searchQuery,
          searchResults: searchResults,
        ),
      );
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _isSearching = false;
      });
      CommonWidget.errorShowSnackBarFor(context, "Search failed. Please try again.");
    }
  }


  Future<void> _loadAllServices() async {
    try {
      print('Loading all services...');
      // Get user location for Google Places integration
      var location = await _getCurrentLocation();
      var response = await dataManager!.getAllServicesWithLocation(context, location);
      if (response != null) {
        var responseData = jsonDecode(response.body);
        print('Services API response: $responseData');
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          setState(() {
            servicesData.clear();
            final servicesList = responseData['data'] as List;
            print('Services list length: ${servicesList.length}');
            servicesData.addAll(servicesList.map((item) => ServicesData.fromJson(item)).toList());
            print('Loaded ${servicesData.length} vendors with services');
            for (var vendor in servicesData) {
              print('Vendor: ${vendor.displayName}, Services count: ${vendor.services.length}');
            }
          });
        } else {
          print('No services data found in API response');
        }
      } else {
        print('No response from services API');
      }
    } catch (e) {
      print('Error loading services: $e');
    }
  }


  List<dynamic> _extractAllServicesAndVendors() {
    List<dynamic> allItems = [];
    print('Extracting services and vendors from ${servicesData.length} vendors');
    
    for (var vendor in servicesData) {
      print('Vendor ${vendor.displayName} has ${vendor.services.length} services');
      
      if (vendor.sId != null && !vendor.sId!.startsWith('ChIJ')) {
        // App vendor - add the vendor itself (not individual services)
        // This way SpecialistsActivity can show all services for the vendor
        allItems.add(vendor);
      } else {
        // Google Places vendor - add the vendor itself
        allItems.add(vendor);
      }
    }
    
    print('Total extracted items: ${allItems.length}');
    return allItems;
  }

  Future<Map<String, double>?> _getCurrentLocation() async {
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
      
      // If no stored location, use default location (Chandigarh)
      return {
        'lat': 30.7200094,
        'lng': 76.7080831,
      };
    } catch (e) {
      print('Error getting location: $e');
      // Return default location on error
      return {
        'lat': 30.7200094,
        'lng': 76.7080831,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    // Calculate animation values based on scroll offset
    // Make header height responsive to screen size
    double baseHeaderHeight = screenHeight * 0.28; // 28% of screen height for better visibility
    double minHeaderHeight = 0.0; // Allow complete collapse
    double headerHeight = (baseHeaderHeight - (_scrollOffset * 0.6)).clamp(minHeaderHeight, baseHeaderHeight);
    
    // Ensure minimum height for very small screens
    if (screenHeight < 600) {
      baseHeaderHeight = 200.0;
      headerHeight = (baseHeaderHeight - (_scrollOffset * 0.6)).clamp(0.0, baseHeaderHeight);
    }
    
    // Debug information
    print('Screen Height: $screenHeight, Status Bar: $statusBarHeight, Header Height: $headerHeight');
    
    double welcomeOpacity = 1.0 - (_scrollOffset / 80.0).clamp(0.0, 1.0);
    double welcomeScale = 1.0 - (_scrollOffset / 150.0).clamp(0.0, 0.3);
    
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Animated Header - Only show if height > 0
              if (headerHeight > 0)
                AnimatedContainer(
                  duration: Duration(milliseconds: 100),
                  height: headerHeight,
                  child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: statusBarHeight + 10, 
                      bottom: 20, 
                      left: 20, 
                      right: 20
                    ),
                  decoration: BoxDecoration(
            color: ColorClass.base_color,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
              children: [
                Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Current Location",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontFamily: "Pop300",
                                  ),
                                ),
                                Text(
                                  sharedPreferences?.getString(Constant.location) ?? "Select Location",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: "Pop500",
                                  ),
                                ),
                              ],
                            ),
                          ),
                      GestureDetector(
                        onTap: () {
                          CommonWidget.navigateToScreen(
                              context, NotificationActivity([]));
                        },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Animated Welcome Section
                      AnimatedOpacity(
                        opacity: welcomeOpacity,
                        duration: Duration(milliseconds: 200),
                        child: Transform.scale(
                          scale: welcomeScale,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Welcome to Cahrz!",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontFamily: "Pop600",
                                            ),
                                          ),
                                          // const SizedBox(height: 4),
                                          // const Text(
                                          //   "Find the best car services near you",
                                          //   style: TextStyle(
                                          //     color: Colors.white70,
                                          //     fontSize: 12,
                                          //     fontFamily: "Pop400",
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.car_repair,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () {
                                            CommonWidget.navigateToScreen(context, const ProfileActivity());
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Search Bar
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
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
                                      hintText: "Search for services, locations...",
                                      hintStyle: TextStyle(
                                        fontFamily: "Pop400",
                                        color: Colors.grey[600],
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                  color: ColorClass.base_color,
                                      ),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  onPressed: () {
                                                    _performSearch();
                                                  },
                                                  icon: Icon(
                                                    Icons.search,
                                                    color: ColorClass.base_color,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _searchQuery = "";
                                                      filteredMixedVendorsData = List.from(mixedVendorsData);
                                                      _isSearching = false;
                                                    });
                                                  },
                                                  icon: Icon(
                                                    Icons.clear,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
                ),
              ),
              // Main Content
          Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    await getMixedVendors(context);
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  child: _isLoading 
                    ? SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Categories Shimmer
                            ShimmerLoader.buildSleekShimmer(width: 150, height: 20),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 5,
                                itemBuilder: (context, index) => Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 16),
                                  child: ShimmerLoader.buildSleekShimmer(
                                    width: 100,
                                    height: 120,
                                    borderRadius: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Quick Actions Shimmer
                            ShimmerLoader.buildSleekShimmer(width: 150, height: 20),
                            const SizedBox(height: 12),
                            ShimmerLoader.buildSleekShimmer(
                              width: double.infinity,
                              height: 100,
                              borderRadius: 12,
                            ),
                            const SizedBox(height: 24),
                            // Services Shimmer
                            ShimmerLoader.buildSleekShimmer(width: 150, height: 20),
                            const SizedBox(height: 12),
                            ...List.generate(3, (index) => ShimmerLoader.buildServiceCardShimmer()),
                            const SizedBox(height: 24),
                            // Offers Shimmer
                            ShimmerLoader.buildSleekShimmer(width: 150, height: 20),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 150,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 3,
                                itemBuilder: (context, index) => ShimmerLoader.buildOfferCardShimmer(),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        // Categories Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                            const Text(
                              "Categories",
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: "Pop600",
                                color: Colors.black87,
                              ),
                            ),
                            // TextButton(
                            //   onPressed: () {
                            //     CommonWidget.navigateToScreen(
                            //       context,
                            //       const AllCategoriesScreen(),
                            //     );
                            //   },
                            //   child: Text(
                            //     "See All",
                            //     style: TextStyle(
                            //       color: ColorClass.base_color,
                            //       fontFamily: "Pop500",
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 12),
                Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: SizedBox(
                            height: 120,
                  child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 2),
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryData.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                                  CommonWidget.navigateToScreen(
                                    context,
                                    CategoriesListActivity(categoryData[index]),
                                  );
                          },
                          child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                      Container(
                                        width: 50,
                                  height: 50,
                                        decoration: BoxDecoration(
                                          color: ColorClass.base_color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        child: Icon(
                                          Icons.car_repair,
                                  color: ColorClass.base_color,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        categoryData[index].categoryTitle ?? "",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: "Pop500",
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ],
                            ),
                          ),
                        );
                            },
                          ),
                        ),
                      ),
                        const SizedBox(height: 24),
                        // Quick Actions
                        const Text(
                          "Quick Actions",
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: "Pop600",
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                  children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                "Book Service",
                                Icons.calendar_today,
                                () async {
                                  // Fetch all services and navigate
                                  await _loadAllServices();
                                  if (mounted) {
                                    List<dynamic> allItems = _extractAllServicesAndVendors();
                                    CommonWidget.navigateToScreen(context, SeviceListScreen(allItems));
                                  }
                                },
                                iconColor: Colors.blue[600],
                                backgroundColor: Colors.blue.withOpacity(0.1),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildQuickActionCard(
                                "My Bookings",
                                Icons.list_alt,
                                () {
                                  CommonWidget.navigateToScreen(context, const BookingListActivity());
                                },
                                iconColor: Colors.orange[600],
                                backgroundColor: Colors.orange.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                "Explore Map",
                                Icons.map,
                                () {
                                  CommonWidget.navigateToScreen(context, const ExploreActivity());
                                },
                                iconColor: Colors.green[600],
                                backgroundColor: Colors.green.withOpacity(0.1),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildQuickActionCard(
                                "Bookmarks",
                                Icons.bookmark,
                                () {
                                  CommonWidget.navigateToScreen(context, const BookmarkActivity());
                                },
                                iconColor: Colors.purple[600],
                                backgroundColor: Colors.purple.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Specialists Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                            Text(
                              _searchQuery.isNotEmpty ? "Search Results" : "Nearby Specialists",
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: "Pop600",
                                color: Colors.black87,
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
                        // Show nearby specialists
                        _buildVendorsSection(),
                        const SizedBox(height: 24),
                        // Offers Section
                        const Text(
                          "Special Offers",
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: "Pop600",
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                        itemCount: offerListData.length,
                        itemBuilder: (context, index) {
                              final offer = offerListData[index];
                              if (offer == null) {
                                return const SizedBox.shrink();
                              }
                              return _buildOfferCard(offer);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Floating minimized header
          if (_scrollOffset > 100)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: 80,
                padding: EdgeInsets.only(
                  top: statusBarHeight + 5, 
                  bottom: 10, 
                  left: 20, 
                  right: 20
                ),
                decoration: BoxDecoration(
                  color: ColorClass.base_color,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                                            children: [
                                              Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                                                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Current Location",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontFamily: "Pop300",
                            ),
                          ),
                          Text(
                            sharedPreferences?.getString(Constant.location) ?? "Select Location",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                              fontFamily: "Pop500",
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Floating minimized header
          if (_scrollOffset > 100)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: 80,
                padding: EdgeInsets.only(
                  top: statusBarHeight + 5, 
                  bottom: 10, 
                  left: 20, 
                  right: 20
                ),
                decoration: BoxDecoration(
                  color: ColorClass.base_color,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _scrollController.animateTo(
                          0,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sharedPreferences?.getString(Constant.location) ?? "Select Location",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: "Pop500",
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isUserLoggedIn)
                      GestureDetector(
                        onTap: () {
                          CommonWidget.navigateToScreen(
                              context, NotificationActivity([]));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, VoidCallback onTap, {Color? iconColor, Color? backgroundColor}) {
    final defaultIconColor = iconColor ?? ColorClass.base_color;
    final defaultBackgroundColor = backgroundColor ?? ColorClass.base_color.withOpacity(0.1);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: defaultBackgroundColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: defaultIconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: "Pop500",
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCard(MixedVendorData vendor) {
    return GestureDetector(
      onTap: vendor.isOpen ? () {
        if (vendor.isAppVendor) {
          CommonWidget.navigateToScreen(
            context,
            SpecialistsActivity(vendor.id),
          );
        } else {
          _openInMaps(vendor);
        }
      } : null,
      child: Container(
                              width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: vendor.isOpen ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: vendor.isOpen 
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
                                      child: Container(
              height: 110,
              width: double.infinity,
              color: Colors.grey[200],
              child: vendor.imageUrl != null && vendor.imageUrl!.isNotEmpty
                  ? Image.network(
                      vendor.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          vendor.isAppVendor ? Icons.local_car_wash : Icons.location_on,
                          size: 48,
                          color: vendor.isAppVendor ? ColorClass.base_color : Colors.blue,
                        );
                      },
                    )
                  : Icon(
                      vendor.isAppVendor ? Icons.local_car_wash : Icons.location_on,
                      size: 48,
                      color: vendor.isAppVendor ? ColorClass.base_color : Colors.blue,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vendor.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: "Pop600",
                          color: vendor.isOpen ? Colors.black87 : Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!vendor.isOpen) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "OFFLINE",
                          style: TextStyle(
                            fontSize: 8,
                            fontFamily: "Pop600",
                            color: Colors.red[600],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  vendor.address ?? "Address not available",
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: "Pop400",
                    color: vendor.isOpen ? Colors.grey[600] : Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber[600],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      "${vendor.rating?.toStringAsFixed(1) ?? "0.0"}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: "Pop500",
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${(vendor.distance * 0.000621371).toStringAsFixed(1)} miles",
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: "Pop600",
                        color: vendor.isAppVendor ? ColorClass.base_color : Colors.blue,
                      ),
                    ),
                    // Only show bookmark icon for app vendors
                    if (vendor.isAppVendor) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _toggleBookmark(vendor);
                        },
                        child: Icon(
                          vendor.isBookmarked == true ? Icons.bookmark : Icons.bookmark_border,
                          size: 16,
                          color: vendor.isBookmarked == true ? ColorClass.base_color : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                  ),
              ],
            ),
          ),
        ],
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
                setState(() {
                  _isLoading = true;
                });
                await getMixedVendors(context);
                setState(() {
                  _isLoading = false;
                });
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

  Widget _buildOfferCard(OfferListModelData offer) {
    // Add null safety check
    if (offer == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  fontFamily: "Pop500",
                  color: Colors.grey,
                ),
              ),
            ),
              ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Open external link or show contact info
                _launchUrl("https://cahrz.com/become-vendor");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorClass.base_color,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "Learn More",
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
      CommonWidget.successShowSnackBarFor(context, "Could not open the link");
    }
  }

  Future<void> getCategory(BuildContext context) async {
    try {
    var response = await dataManager!.getcategory(context);
      if (response != null) {
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
      print('Error getting categories: $e');
    }
  }

  Future<void> getServices(BuildContext context) async {
    try {
    var response = await dataManager!.getAllServices(context);
      if (response != null) {
      setState(() {
        servicesData.clear();
          servicesData.addAll(response);
          filteredServicesData = List.from(servicesData);
        });
      }
    } catch (e) {
      print('Error getting services: $e');
      // Continue without services if API fails
    }
  }

  Future<void> getOffer(BuildContext context) async {
    try {
      var response = await dataManager!.getOffer(context);
      if (response != null) {
        var responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          setState(() {
            offerListData.clear();
            // Parse the offers data properly
            List<dynamic> offersJson = responseData['data'] as List;
            for (var offerJson in offersJson) {
              if (offerJson != null) {
                offerListData.add(OfferListModelData.fromJson(offerJson));
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error getting offers: $e');
      // Continue without offers if API fails
    }
  }

  Future<void> getMixedVendors(BuildContext context) async {
    try {
      final vendors = await dataManager!.getMixedVendors(context);
      
      // Calculate distances for all vendors
      final userLocation = _getUserLocation();
      final userLat = userLocation['lat']!;
      final userLng = userLocation['lng']!;
      
      for (var vendor in vendors) {
        if (vendor.latitude != 0 && vendor.longitude != 0) {
          vendor.distance = MixedVendorData.calculateDistanceBetween(
            userLat, userLng, vendor.latitude, vendor.longitude
          );
        }
      }
      
      setState(() {
        mixedVendorsData.clear();
        mixedVendorsData.addAll(vendors);
        filteredMixedVendorsData = List.from(mixedVendorsData);
      });
      
      print('✅ Mixed vendors loaded successfully. Count: ${mixedVendorsData.length}');
    } catch (e) {
      print('Error getting mixed vendors: $e');
      // Continue without vendors if API fails
    }
  }

  Map<String, double> _getUserLocation() {
    try {
      final latStr = sharedPreferences?.getString(Constant.lat);
      final lngStr = sharedPreferences?.getString(Constant.long);
      
      if (latStr != null && lngStr != null && latStr != "null" && lngStr != "null") {
        return {
          'lat': double.parse(latStr),
          'lng': double.parse(lngStr),
        };
      }
      
      // If no stored location, use default location (Chandigarh)
      return {
        'lat': 30.7200094,
        'lng': 76.7080831,
      };
    } catch (e) {
      print('Error getting location: $e');
      // Return default location on error
      return {
        'lat': 30.7200094,
        'lng': 76.7080831,
      };
    }
  }

  void _handleGoogleVendorTap(MixedVendorData vendor) {
    // Show a dialog with options for Google vendors
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vendor.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: "Pop600",
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "This is a Google Places vendor. You can:",
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: "Pop400",
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vendor.address ?? "Address not available",
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: "Pop400",
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "Rating: ${vendor.rating?.toStringAsFixed(1) ?? "N/A"}",
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: "Pop400",
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: "Pop500",
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openInMaps(vendor);
              },
              icon: const Icon(Icons.map, size: 16),
              label: const Text("Open in Maps"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openInMaps(MixedVendorData vendor) {
    // Open the vendor location in Google Maps
    final lat = vendor.latitude;
    final lng = vendor.longitude;
    final name = Uri.encodeComponent(vendor.name);
    final address = Uri.encodeComponent(vendor.address ?? "");
    
    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$name";
    
    // You can use url_launcher here if available
    // launchUrl(Uri.parse(url));
    
    // For now, show a message
    CommonWidget.successShowSnackBarFor(context, "Opening in Maps...");
  }

  Future<void> _toggleBookmark(MixedVendorData vendor) async {
    try {
      if (vendor.isBookmarked) {
        // Remove bookmark
        var response = await bookmarkDataManager!.removeBookmark(context, vendor.id);
        var data = jsonDecode(response.body);
        if (data['status'] == "success") {
          setState(() {
            vendor.isBookmarked = false;
          });
          CommonWidget.successShowSnackBarFor(context, "Removed from bookmarks");
        } else {
          CommonWidget.errorShowSnackBarFor(context, data['message'] ?? "Failed to remove bookmark");
        }
      } else {
        // Add bookmark
        var response = await bookmarkDataManager!.postBookmark(context, vendor.id);
        var data = jsonDecode(response.body);
        if (data['status'] == "success") {
          setState(() {
            vendor.isBookmarked = true;
          });
          CommonWidget.successShowSnackBarFor(context, "Added to bookmarks");
        } else {
          CommonWidget.errorShowSnackBarFor(context, data['message'] ?? "Failed to add bookmark");
        }
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
      CommonWidget.errorShowSnackBarFor(context, "Error updating bookmark");
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
        itemCount: filteredMixedVendorsData.length,
        itemBuilder: (context, index) {
          final vendor = filteredMixedVendorsData[index];
          return _buildVendorCard(vendor);
        },
      ),
    );
  }

}