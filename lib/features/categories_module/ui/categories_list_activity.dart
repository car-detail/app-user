import 'dart:convert';
import 'dart:math' as math;

import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/categories_module/ui/sevice_list_screen.dart';
import 'package:car_app/features/home_module/model/category_model_data.dart';
import 'package:car_app/features/home_module/data_manager/home_data_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Common/CommonWidget.dart';
import '../../../Common/ShimmerLoader.dart';
import '../../bookmark_model/ui/bookmark_activity.dart';
import '../../home_module/model/services_model_data.dart';
import '../../home_module/model/mixed_vendor_data.dart';
import '../../specialists_module/ui/specialists_activity.dart';
import '../data_manager/categories_list_data_manager.dart';
import '../model/services_post_bean.dart';

class CategoriesListActivity extends StatefulWidget {
  CategoryData categoryData;

  CategoriesListActivity(this.categoryData, {super.key});

  @override
  State<CategoriesListActivity> createState() => _CategoriesListActivityState();
}

class _CategoriesListActivityState extends State<CategoriesListActivity> {
  List<ServicesData> servicesData = [];
  List<MixedVendorData> mixedVendorsData = [];
  List<MixedVendorData> filteredVendorsData = [];
  CategoriesListDataManager? dataManager;
  HomeDataManager? homeDataManager;
  SharedPreferences? sharedPreferences;
  List<String> offerList = ["car_image.png", "car_image.png"];
  
  // Search and filter variables
  TextEditingController searchController = TextEditingController();
  String selectedSortBy = 'distance'; // distance, rating, name
  double maxDistance = 31.0; // in miles (50km = 31 miles)
  double minRating = 0.0;
  
  // Loading state
  bool _isLoading = true;
  
  // Parallax animation
  ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    start();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = CategoriesListDataManager(sharedPreferences!);
    homeDataManager = HomeDataManager(sharedPreferences!);
    await getMixedVendors(context);
  }

  getMixedVendors(BuildContext context) async {
    try {
      final categoryTitle = widget.categoryData.categoryTitle ?? '';
      print('🔍 Fetching vendors for category: $categoryTitle'); // Debug log
      
      // Show loading state
      setState(() {
        _isLoading = true;
      });
      
      // Use category-specific API call
      final vendors = await homeDataManager!.getMixedVendorsByCategory(context, categoryTitle);
      
      print('🔍 Total vendors from API: ${vendors.length}'); // Debug log
      
      // Debug: Print all vendor types
      for (var vendor in vendors) {
        print('Vendor: ${vendor.name}, isAppVendor: ${vendor.isAppVendor}, services: ${vendor.services}');
      }
      
      // Calculate distances for all vendors
      final userLat = double.tryParse(sharedPreferences?.getString(Constant.lat) ?? "0") ?? 0;
      final userLng = double.tryParse(sharedPreferences?.getString(Constant.long) ?? "0") ?? 0;
      
      for (var vendor in vendors) {
        if (vendor.distance == 0 && vendor.latitude != 0 && vendor.longitude != 0) {
          vendor.distance = MixedVendorData.calculateDistanceBetween(
            userLat, userLng, vendor.latitude, vendor.longitude
          );
        }
      }
      
      print('🔍 Vendors after distance calculation: ${vendors.length}'); // Debug log
      
      setState(() {
        mixedVendorsData = vendors;
        filteredVendorsData = List.from(vendors);
        _isLoading = false;
      });
      
      applyFilters();
      
      // Show success message if vendors found
      if (vendors.isNotEmpty) {
        CommonWidget.successShowSnackBarFor(context, "Found ${vendors.length} vendors for ${categoryTitle}");
      } else {
        CommonWidget.errorShowSnackBarFor(context, "No vendors found for ${categoryTitle}. Try adjusting your location or filters.");
      }
    } catch (e) {
      print('❌ Error loading vendors: $e');
      CommonWidget.errorShowSnackBarFor(context, "Error loading vendors: $e");
      
      // Set empty state on error
      setState(() {
        mixedVendorsData = [];
        filteredVendorsData = [];
        _isLoading = false;
      });
    }
  }

  getServices(BuildContext context) async {
    var response = await dataManager!
        .getAllServices(context, widget.categoryData.categoryTitle ?? "");
    var data = ServicesModelData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        servicesData.clear();
        servicesData.addAll(data.data!);
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  void applyFilters() {
    List<MixedVendorData> filtered = List.from(mixedVendorsData);
    
    print('🔍 Applying filters - Total vendors: ${filtered.length}');
    print('🔍 Max distance: ${maxDistance} miles');
    print('🔍 Min rating: ${minRating}');
    
    // Apply search filter
    if (searchController.text.isNotEmpty) {
      final searchTerm = searchController.text.toLowerCase();
      filtered = filtered.where((vendor) =>
        vendor.name.toLowerCase().contains(searchTerm) ||
        vendor.address?.toLowerCase().contains(searchTerm) == true ||
        vendor.category?.toLowerCase().contains(searchTerm) == true
      ).toList();
      print('🔍 After search filter: ${filtered.length} vendors');
    }
    
    // Apply distance filter (convert meters to miles)
    final beforeDistanceFilter = filtered.length;
    filtered = filtered.where((vendor) {
      final distanceInMiles = vendor.distance * 0.000621371;
      final passesFilter = distanceInMiles <= maxDistance;
      if (!passesFilter) {
        print('🔍 Filtering out ${vendor.name}: ${distanceInMiles.toStringAsFixed(2)} miles > ${maxDistance} miles');
      }
      return passesFilter;
    }).toList();
    print('🔍 After distance filter: ${filtered.length} vendors (removed ${beforeDistanceFilter - filtered.length})');
    
    // Apply rating filter
    final beforeRatingFilter = filtered.length;
    filtered = filtered.where((vendor) => 
      (vendor.rating ?? 0) >= minRating
    ).toList();
    print('🔍 After rating filter: ${filtered.length} vendors (removed ${beforeRatingFilter - filtered.length})');
    
    // Apply sorting
    switch (selectedSortBy) {
      case 'distance':
        filtered.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      case 'rating':
        filtered.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    
    print('🔍 Final filtered vendors: ${filtered.length}');
    
    setState(() {
      filteredVendorsData = filtered;
    });
  }

  void applyFiltersAndRefetch() async {
    print('🔄 Refetching data with new distance filter: ${maxDistance} miles');
    
    // Show loading state
    setState(() {
      _isLoading = true;
    });
    
    // Convert miles to meters for API call
    final maxDistanceMeters = (maxDistance * 1609.34).round();
    final categoryTitle = widget.categoryData.categoryTitle ?? '';
    
    try {
      // Refetch vendors with new distance parameter and category filter
      final vendors = await homeDataManager!.getMixedVendorsByCategoryWithRadius(
        context, 
        categoryTitle,
        double.tryParse(sharedPreferences?.getString(Constant.lat) ?? "0") ?? 0,
        double.tryParse(sharedPreferences?.getString(Constant.long) ?? "0") ?? 0,
        maxDistanceMeters.toDouble()
      );
      
      print('🔄 Refetched ${vendors.length} vendors for category "$categoryTitle" within ${maxDistance} miles');
      
      // Calculate distances for all vendors
      final userLat = double.tryParse(sharedPreferences?.getString(Constant.lat) ?? "0") ?? 0;
      final userLng = double.tryParse(sharedPreferences?.getString(Constant.long) ?? "0") ?? 0;
      
      for (var vendor in vendors) {
        if (vendor.distance == 0 && vendor.latitude != 0 && vendor.longitude != 0) {
          vendor.distance = MixedVendorData.calculateDistanceBetween(
            userLat, userLng, vendor.latitude, vendor.longitude
          );
        }
      }
      
      print('🔄 After distance calculation: ${vendors.length} vendors');
      
      // Apply additional filters (search, rating)
      List<MixedVendorData> finalFiltered = List.from(vendors);
      
      // Apply search filter
      if (searchController.text.isNotEmpty) {
        final searchTerm = searchController.text.toLowerCase();
        finalFiltered = finalFiltered.where((vendor) =>
          vendor.name.toLowerCase().contains(searchTerm) ||
          vendor.address?.toLowerCase().contains(searchTerm) == true ||
          vendor.category?.toLowerCase().contains(searchTerm) == true
        ).toList();
        print('🔄 After search filter: ${finalFiltered.length} vendors');
      }
      
      // Apply rating filter
      finalFiltered = finalFiltered.where((vendor) => 
        (vendor.rating ?? 0) >= minRating
      ).toList();
      print('🔄 After rating filter: ${finalFiltered.length} vendors');
      
      // Apply sorting
      switch (selectedSortBy) {
        case 'distance':
          finalFiltered.sort((a, b) => a.distance.compareTo(b.distance));
          break;
        case 'rating':
          finalFiltered.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
          break;
        case 'name':
          finalFiltered.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
      
      print('🔄 Final filtered vendors: ${finalFiltered.length}');
      
      setState(() {
        mixedVendorsData = vendors;
        filteredVendorsData = finalFiltered;
        _isLoading = false;
      });
      
      // Show success message
      if (finalFiltered.isNotEmpty) {
        CommonWidget.successShowSnackBarFor(context, "Found ${finalFiltered.length} vendors within ${maxDistance.toStringAsFixed(1)} miles");
      } else {
        CommonWidget.errorShowSnackBarFor(context, "No vendors found within ${maxDistance.toStringAsFixed(1)} miles. Try increasing the distance or adjusting other filters.");
      }
      
    } catch (e) {
      print('❌ Error refetching vendors: $e');
      setState(() {
        _isLoading = false;
      });
      // Fallback to local filtering if API call fails
      applyFilters();
      CommonWidget.errorShowSnackBarFor(context, "Error refetching vendors. Using local filters instead.");
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Filter Options'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Distance filter
                  Text('Max Distance: ${maxDistance.toStringAsFixed(1)} miles'),
                  Slider(
                    value: maxDistance,
                    min: 1.0,
                    max: 62.0, // 100km = 62 miles
                    divisions: 99,
                    onChanged: (value) {
                      setState(() {
                        maxDistance = value;
                      });
                    },
                  ),
                  
                  // Rating filter
                  Text('Min Rating: ${minRating.toStringAsFixed(1)}'),
                  Slider(
                    value: minRating,
                    min: 0.0,
                    max: 5.0,
                    divisions: 50,
                    onChanged: (value) {
                      setState(() {
                        minRating = value;
                      });
                    },
                  ),
                  
                  // Sort by
                  DropdownButton<String>(
                    value: selectedSortBy,
                    items: [
                      DropdownMenuItem(value: 'distance', child: Text('Distance')),
                      DropdownMenuItem(value: 'rating', child: Text('Rating')),
                      DropdownMenuItem(value: 'name', child: Text('Name')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedSortBy = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    applyFiltersAndRefetch();
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate parallax effect
    double parallaxOffset = _scrollOffset * 0.5;
    double toolbarHeight = 100.0 - (_scrollOffset * 0.3).clamp(0.0, 30.0);
    
    return Scaffold(
      body: Column(
        children: [
          // Animated toolbar with parallax effect
          AnimatedContainer(
            duration: Duration(milliseconds: 100),
            height: toolbarHeight,
            child: Container(
            color: ColorClass.base_color,
              padding: EdgeInsets.only(top: 45, bottom: 10),
            child: Stack(
              children: [
                  // Parallax background
                  Transform.translate(
                    offset: Offset(0, parallaxOffset),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            ColorClass.base_color,
                            ColorClass.base_color.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                Container(
                  margin: const EdgeInsets.only(left: 10, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Image.asset(
                          CommonWidget.getImagePath("backspace.png"),
                          height: 40,
                          width: 40,
                        ),
                      ),
                      Expanded(
                          child: CommonWidget.getTextWidget500(
                              widget.categoryData.categoryTitle ?? "",
                              color: Colors.white,
                              size: 18)),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                _showFilterDialog();
                              },
                              child: Icon(
                                Icons.filter_list,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          CommonWidget.navigateToScreen(
                              context, const BookmarkActivity());
                        },
                        child: Image.asset(
                          CommonWidget.getImagePath("bookmark.png"),
                          height: 40,
                          width: 40,
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
          // Category header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.category,
                  color: ColorClass.base_color,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Category: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: "Pop400",
                  ),
                ),
                Text(
                  widget.categoryData.categoryTitle ?? 'All Categories',
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorClass.base_color,
                    fontFamily: "Pop600",
                  ),
                ),
                Spacer(),
                if (filteredVendorsData.isNotEmpty)
                  Text(
                    '${filteredVendorsData.length} vendors',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: "Pop400",
                    ),
                  ),
              ],
            ),
          ),
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search vendors...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                applyFilters();
              },
            ),
                            ),
                            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading vendors...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontFamily: "Pop500",
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Finding ${widget.categoryData.categoryTitle} services near you',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              fontFamily: "Pop400",
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : filteredVendorsData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No vendors found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontFamily: "Pop600",
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No ${widget.categoryData.categoryTitle} services found in your area.\nTry adjusting your location or filters.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                  fontFamily: "Pop400",
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  getMixedVendors(context);
                                },
                                icon: Icon(Icons.refresh, size: 18),
                                label: Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorClass.base_color,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          margin: const EdgeInsets.all(15),
                          child: ListView.builder(
                              controller: _scrollController,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: filteredVendorsData.length,
                              itemBuilder: (context, index) {
                                final vendor = filteredVendorsData[index];
                                return _buildVendorCard(vendor);
                              }),
                        ))
        ],
      ),
    );
  }

  postBookmark(BuildContext context, String id) async {
    var response = await dataManager!.postBookmark(context, id);
    var data = ServicesPostBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      getServices(context);
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  removeBookmark(BuildContext context, String id) async {
    var response = await dataManager!.removeBookmark(context, id);
    var data = ServicesPostBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      getServices(context);
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  Widget _buildVendorCard(MixedVendorData vendor) {
    // Check if vendor is offline (only for app vendors)
    final isOffline = vendor.isAppVendor && !vendor.isOpen;
    
    return GestureDetector(
      onTap: () {
        print('Tapped vendor: ${vendor.name}, isAppVendor: ${vendor.isAppVendor}, isOffline: $isOffline'); // Debug log
        
        // Prevent navigation for offline vendors
        if (isOffline) {
          _showOfflineMessage();
          return;
        }
        
        if (vendor.isAppVendor) {
          // For app vendors, navigate to booking page
          if (vendor.services.isNotEmpty) {
            List<Services> services = vendor.services.map((serviceName) {
              return Services(
                sId: vendor.id,
                serviceTitle: serviceName,
                price: 0, // Default price
                categoryName: vendor.category,
                averageRating: vendor.rating?.round(),
                totalReviews: vendor.reviewCount,
              );
            }).toList();
            CommonWidget.navigateToScreen(context, SeviceListScreen(services));
          } else {
            // If no services, show vendor info
            _showVendorInfoBottomSheet(vendor);
          }
        } else {
          // For Google Places vendors, show bottom sheet with navigation options
          print('Showing Google vendor bottom sheet for: ${vendor.name}'); // Debug log
          _showGoogleVendorBottomSheet(vendor);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOffline ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isOffline ? Border.all(color: Colors.grey[300]!) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Vendor image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: vendor.imageUrl != null && vendor.imageUrl!.isNotEmpty
                  ? Image.network(
                      vendor.imageUrl!,
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                      headers: {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 70,
                          width: 70,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Image load error for ${vendor.name}: $error'); // Debug log
                        print('Image URL: ${vendor.imageUrl}'); // Debug log
                        return Container(
                          height: 70,
                          width: 70,
                          color: vendor.isAppVendor ? ColorClass.base_light_color : Colors.blue[100],
                          child: Icon(
                            vendor.isAppVendor ? Icons.business : Icons.location_on,
                            color: vendor.isAppVendor ? ColorClass.base_color : Colors.blue,
                            size: 32,
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 70,
                      width: 70,
                      color: vendor.isAppVendor ? ColorClass.base_light_color : Colors.blue[100],
                      child: Icon(
                        vendor.isAppVendor ? Icons.business : Icons.location_on,
                        color: vendor.isAppVendor ? ColorClass.base_color : Colors.blue,
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            
            // Vendor details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                vendor.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isOffline ? Colors.grey[600] : ColorClass.base_color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // OFFLINE badge
                            if (isOffline)
                              Container(
                                margin: EdgeInsets.only(left: 8),
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'OFFLINE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Category indicator
                      if (vendor.category != null && vendor.category!.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            vendor.category!,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      // Vendor type indicator
                      if (vendor.isAppVendor)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ColorClass.base_color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'App',
                            style: TextStyle(
                              fontSize: 10,
                              color: ColorClass.base_color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Google',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  if (vendor.address != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      vendor.address!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: 6),
                  
                  Row(
                    children: [
                      // Distance
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${(vendor.distance * 0.000621371).toStringAsFixed(1)} miles",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Rating
                      if (vendor.rating != null) ...[
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vendor.rating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      
                      const Spacer(),
                      
                      // Status
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: vendor.isOpen ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          vendor.isOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }

  bool _isCarRelatedCategory(String category) {
    final carKeywords = [
      'car', 'auto', 'vehicle', 'wash', 'repair', 'service', 'detailing', 
      'maintenance', 'tire', 'oil', 'brake', 'engine', 'garage', 'mechanic'
    ];
    return carKeywords.any((keyword) => category.contains(keyword));
  }

  bool _isServiceRelatedToCategory(String service, String category) {
    // Define mapping between services and categories
    final serviceCategoryMap = {
      'car_wash': ['wash', 'cleaning', 'detailing'],
      'car_repair': ['repair', 'fix', 'maintenance', 'service'],
      'tire_shop': ['tire', 'wheel', 'alignment'],
      'gas_station': ['fuel', 'gas', 'petrol'],
      'auto_parts': ['parts', 'accessories', 'spare'],
    };
    
    // Check if service matches any category keywords
    for (final entry in serviceCategoryMap.entries) {
      if (service.contains(entry.key)) {
        return entry.value.any((keyword) => category.contains(keyword));
      }
    }
    
    // Direct keyword matching
    final categoryKeywords = category.split(' ');
    return categoryKeywords.any((keyword) => service.contains(keyword));
  }

  void _showVendorInfoBottomSheet(MixedVendorData vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Vendor image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: vendor.imageUrl != null && vendor.imageUrl!.isNotEmpty
                          ? Image.network(
                              vendor.imageUrl!,
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 60,
                                  width: 60,
                                  color: ColorClass.base_light_color,
                                  child: Icon(
                                    Icons.business,
                                    color: ColorClass.base_color,
                                    size: 28,
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 60,
                              width: 60,
                              color: ColorClass.base_light_color,
                              child: Icon(
                                Icons.business,
                                color: ColorClass.base_color,
                                size: 28,
                              ),
                            ),
                    ),
                    
                    SizedBox(width: 16),
                    
                    // Vendor info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: ColorClass.base_color,
                            ),
                          ),
                          SizedBox(height: 4),
                          if (vendor.address != null)
                            Text(
                              vendor.address!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                              SizedBox(width: 4),
                              Text(
                                "${(vendor.distance * 0.000621371).toStringAsFixed(1)} miles",
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              SizedBox(width: 16),
                              if (vendor.rating != null) ...[
                                Icon(Icons.star, size: 16, color: Colors.amber[600]),
                                SizedBox(width: 4),
                                Text(
                                  vendor.rating!.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              
              Divider(height: 1),
              
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Services Available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ColorClass.base_color,
                        ),
                      ),
                      SizedBox(height: 12),
                      if (vendor.services.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: vendor.services.map((service) {
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: ColorClass.base_light_color,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                service.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ColorClass.base_color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'No specific services listed',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      
                      SizedBox(height: 20),
                      
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ColorClass.base_color,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: vendor.isOpen ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              vendor.isOpen ? 'Open Now' : 'Closed',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to booking or service list
                          if (vendor.services.isNotEmpty) {
                            List<Services> services = vendor.services.map((serviceName) {
                              return Services(
                                sId: vendor.id,
                                serviceTitle: serviceName,
                                price: 0,
                                categoryName: vendor.category,
                                averageRating: vendor.rating?.round(),
                                totalReviews: vendor.reviewCount,
                              );
                            }).toList();
                            CommonWidget.navigateToScreen(context, SeviceListScreen(services));
                          }
                        },
                        icon: Icon(Icons.calendar_today, size: 18),
                        label: Text('Book Service'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorClass.base_color,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
    );
  }

  void _showGoogleVendorBottomSheet(MixedVendorData vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Vendor image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: vendor.imageUrl != null && vendor.imageUrl!.isNotEmpty
                          ? Image.network(
                              vendor.imageUrl!,
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 60,
                                  width: 60,
                                  color: Colors.blue[100],
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.blue,
                                    size: 28,
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 60,
                              width: 60,
                              color: Colors.blue[100],
                              child: Icon(
                                Icons.location_on,
                                color: Colors.blue,
                                size: 28,
                              ),
                            ),
                    ),
                    
                    SizedBox(width: 16),
                    
                    // Vendor info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vendor.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Google',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          if (vendor.address != null)
                            Text(
                              vendor.address!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                              SizedBox(width: 4),
                              Text(
                                "${(vendor.distance * 0.000621371).toStringAsFixed(1)} miles",
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              SizedBox(width: 16),
                              if (vendor.rating != null) ...[
                                Icon(Icons.star, size: 16, color: Colors.amber[600]),
                                SizedBox(width: 4),
                                Text(
                                  vendor.rating!.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              
              Divider(height: 1),
              
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Services',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 12),
                      if (vendor.services.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: vendor.services.map((service) {
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Text(
                                service.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'Car wash and repair services',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      
                      SizedBox(height: 20),
                      
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: vendor.isOpen ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              vendor.isOpen ? 'Open Now' : 'Closed',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20),
                      
                      Text(
                        'Note',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Text(
                          'This is a Google Places vendor. You can navigate to their location or call them directly. For booking services, please contact them directly.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToVendor(vendor);
                        },
                        icon: Icon(Icons.directions, size: 18),
                        label: Text('Navigate'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          side: BorderSide(color: Colors.blue[300]!),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _callVendor(vendor);
                        },
                        icon: Icon(Icons.phone, size: 18),
                        label: Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
    );
  }

  void _navigateToVendor(MixedVendorData vendor) {
    // Open Google Maps with vendor location
    final lat = vendor.latitude;
    final lng = vendor.longitude;
    final name = Uri.encodeComponent(vendor.name);
    
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$name';
    
    // You can use url_launcher here
    print('Navigate to: $googleMapsUrl');
    CommonWidget.successShowSnackBarFor(context, 'Opening navigation to ${vendor.name}');
  }

  void _callVendor(MixedVendorData vendor) {
    if (vendor.phone != null) {
      // You can use url_launcher here to make phone calls
      print('Calling: ${vendor.phone}');
      CommonWidget.successShowSnackBarFor(context, 'Calling ${vendor.name} at ${vendor.phone}');
    } else {
      CommonWidget.errorShowSnackBarFor(context, 'Phone number not available for this vendor');
    }
  }

  void _showOfflineMessage() {
    CommonWidget.errorShowSnackBarFor(context, "This vendor is currently offline and not accepting bookings");
  }

}
