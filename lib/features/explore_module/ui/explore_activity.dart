import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../../home_module/model/services_model_data.dart';
import '../../home_module/model/mixed_vendor_data.dart';
import '../../home_module/data_manager/home_data_manager.dart';
import '../../booking_model/ui/booking_activity.dart';
import '../../specialists_module/ui/specialists_activity.dart';
import '../../home_module/ui/location_picker_screen.dart';
import '../../log_in/ui/new_login_activity.dart';
import '../../../Common/ShimmerLoader.dart';

class ExploreActivity extends StatefulWidget {
  final bool startWithMap;
  const ExploreActivity({this.startWithMap = false, super.key});

  @override
  State<ExploreActivity> createState() => ExploreActivityState();
}

class ExploreActivityState extends State<ExploreActivity> {
  List<MixedVendorData> allVendors = [];
  List<MixedVendorData> filteredVendors = [];
  late bool isMapView;
  bool isLoading = true;
  String searchQuery = "";
  String selectedFilter = "All";
  String? selectedLocation;
  double? selectedRadius; // in meters
  List<String> radiusOptions = ["1 mile", "5 miles", "10 miles", "25 miles", "50 miles"];
  String selectedRadiusOption = "10 miles";
  TextEditingController? _searchController;
  
  HomeDataManager? dataManager;
  SharedPreferences? sharedPreferences;
  String? _lastFetchedLat; // tracks location used for last fetch

  List<String> filterOptions = ["All"]; // will be loaded dynamically
  
  // Map related variables
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;

  BitmapDescriptor? _vendorIcon;
  
  // Zoom and radius tracking
  double _currentZoom = 12.0;
  double _lastFetchedRadius = 16093.44; // 10 miles default
  Timer? _debounceTimer;

  // Pagination & Distance states
  final ScrollController _scrollController = ScrollController();
  int _pageNumber = 1;
  bool _isLoadingMore = false;
  bool _isLastPage = false;
  final int _pageSize = 20;
  int _currentDistance = 30000;
  final int _maxDistanceLimit = 150000;


  @override
  void initState() {
    super.initState();
    isMapView = widget.startWithMap;
    _searchController = TextEditingController();
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.95 &&
        !isLoading &&
        !_isLoadingMore &&
        !isMapView) {
      if (!_isLastPage) {
        _loadMoreVendors();
      } else if (_currentDistance < _maxDistanceLimit) {
        debugPrint("🔄 ExploreActivity: Auto-expanding distance from ${_currentDistance/1000}km...");
        _loadMoreVendors(isExpandingDistance: true);
      }
    }
  }


  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  Future<void> _initializeData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = HomeDataManager(sharedPreferences!);
    selectedLocation = sharedPreferences?.getString(Constant.location);
    selectedRadius = _parseRadius(selectedRadiusOption);
    _currentDistance = selectedRadius?.toInt() ?? 30000;
    await _loadIcons();
    await _loadCategories();
    await _getCurrentLocation(); // get real GPS before loading vendors
    await _loadVendors();
  }

  double _parseRadius(String radiusOption) {
    // Convert miles to meters (1 mile = 1609.34 meters)
    switch (radiusOption) {
      case "1 mile":
        return 1609.34; // 1 mile in meters
      case "5 miles":
        return 8046.72; // 5 miles in meters
      case "10 miles":
        return 16093.44; // 10 miles in meters
      case "25 miles":
        return 40233.6; // 25 miles in meters
      case "50 miles":
        return 80467.2; // 50 miles in meters
      default:
        return 16093.44; // 10 miles default
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await dataManager!.getcategory(context);
      final body = await response.body;
      final data = body is String ? body : body.toString();
      final decoded = jsonDecode(data);
      if (mounted && decoded['status'] == 'success' && decoded['data'] != null) {
        final List<dynamic> cats = decoded['data'];
        setState(() {
          filterOptions = ["All"];
          for (final c in cats) {
            if (c is Map && c['categoryTitle'] != null && (c['isActive'] == true || c['isActive'] == null)) {
              filterOptions.add(c['categoryTitle']);
            }
          }
        });
      }
    } catch (e) {
      // Keep default 'All' if categories fail
    }
  }

  Future<void> _loadIcons() async {
    try {
      _vendorIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/car_loction.png',
      );
    } catch (_) {
      _vendorIcon = null;
    }
  }

  /// Called by dashboard when switching to explore tab — re-fetches if location changed.
  void refreshIfLocationChanged() {
    final currentLat = sharedPreferences?.getString(Constant.lat);
    if (currentLat != null && currentLat != "null" && currentLat != "0.0" && currentLat != _lastFetchedLat) {
      _loadVendors();
    }
  }

  Future<void> _loadVendors() async {
    _lastFetchedLat = sharedPreferences?.getString(Constant.lat);
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          _pageNumber = 1;
          _isLastPage = false;
          _currentDistance = selectedRadius?.toInt() ?? 30000;
        });
      }

      // Get mixed vendors (app + Google Places)
      debugPrint("🔵 Explore: Fetching items page $_pageNumber at ${_currentDistance/1000}km");
      final mixedVendors = await dataManager!.getMixedVendors(
        context, 
        pageNumber: _pageNumber, 
        count: _pageSize,
        maxDistance: _currentDistance,
      );
      
      // Get current location
      await _getCurrentLocation();
      
      if (mounted) {
        MixedVendorData.sortVendors(mixedVendors);
        setState(() {
          allVendors = mixedVendors;
          filteredVendors = List.from(allVendors);
          _pageNumber++;
          if (mixedVendors.length < _pageSize) {
            _isLastPage = true;
            debugPrint("🛑 Explore: Last page reached at ${_currentDistance/1000}km");
            
            // If we reached last page and have very few results, expand immediately
            if (allVendors.length < 5 && _currentDistance < _maxDistanceLimit) {
              _loadMoreVendors(isExpandingDistance: true);
            }
          }
          isLoading = false;
        });
      }
      
      // Auto-expand if empty
      if (allVendors.isEmpty && _currentDistance < _maxDistanceLimit) {
        _loadMoreVendors(isExpandingDistance: true);
      }

      // Create markers for map
      _createMarkers();
    } catch (e) {
      debugPrint("🔴 Explore: Fetch error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _filterVendors() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          _pageNumber = 1;
          _isLastPage = false;
          _currentDistance = selectedRadius?.toInt() ?? 30000;
          allVendors.clear();
          filteredVendors.clear();
        });
      }
      List<MixedVendorData> vendors = [];

      if (_currentLocation == null) return;
      final lat = _currentLocation!.latitude;
      final lng = _currentLocation!.longitude;
      final radius = selectedRadius ?? _currentDistance.toDouble();

      debugPrint("🔵 Explore: Filtering page $_pageNumber with filter=$selectedFilter, search=$searchQuery at ${radius/1000}km");

      if (selectedFilter != "All") {
        vendors = await dataManager!.getMixedVendorsByCategoryWithRadius(
          context,
          selectedFilter,
          lat,
          lng,
          radius,
          pageNumber: _pageNumber,
          count: _pageSize,
        );
      } else if (searchQuery.isNotEmpty) {
        vendors = await dataManager!.searchVendors(
          context, 
          searchQuery,
          pageNumber: _pageNumber,
          count: _pageSize,
          maxDistance: radius.toInt(),
        );

        // If no vendors found by name, try to check if it's a location (e.g., "Amritsar")
        if (vendors.isEmpty && _pageNumber == 1) {
          try {
            List<geo.Location> locations =
                await geo.locationFromAddress(searchQuery);
            if (locations.isNotEmpty) {
              final newLocation =
                  LatLng(locations[0].latitude, locations[0].longitude);

              // Get a friendly name for the location
              String locationName = searchQuery;
              try {
                List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
                    newLocation.latitude, newLocation.longitude);
                if (placemarks.isNotEmpty) {
                  locationName = placemarks[0].locality ??
                      placemarks[0].subAdministrativeArea ??
                      placemarks[0].name ??
                      searchQuery;
                }
              } catch (_) {}

              // Update in-memory state only — do NOT write to SharedPreferences.
              // Writing here would permanently overwrite the user's real/set location
              // with whatever they typed in the search box.
              if (mounted) {
                setState(() {
                  _currentLocation = newLocation;
                  selectedLocation = locationName;
                });
              }

              // Fetch vendors at this new location
              vendors = await dataManager!.getMixedVendorsWithRadius(
                context,
                newLocation.latitude,
                newLocation.longitude,
                radius,
                pageNumber: _pageNumber,
                count: _pageSize,
              );

              // Move map if in map view
              if (_mapController != null) {
                _mapController!
                    .animateCamera(CameraUpdate.newLatLng(newLocation));
              }

              if (mounted) {
                CommonWidget.successShowSnackBarFor(
                    context, "Showing vendors in $locationName");
              }
            }
          } catch (_) {
            // Not a valid location, just show empty results
          }
        }
      } else {
        vendors = await dataManager!.getMixedVendorsWithRadius(
          context,
          lat,
          lng,
          radius,
          pageNumber: _pageNumber,
          count: _pageSize,
        );
      }

      if (mounted) {
        MixedVendorData.sortVendors(vendors);
        setState(() {
          allVendors = vendors;
          filteredVendors = List.from(allVendors);
          _lastFetchedRadius = radius;
          _pageNumber++;
          if (vendors.length < _pageSize) {
            _isLastPage = true;
            debugPrint("🛑 Explore: Last page reached at ${_currentDistance/1000}km");
            
            // If filtering yields few results, expand immediately
            if (allVendors.length < 5 && _currentDistance < _maxDistanceLimit) {
               _loadMoreVendors(isExpandingDistance: true);
            }
          }
          isLoading = false;
        });
      }
      
      // Auto-expand if still empty
      if (allVendors.isEmpty && _currentDistance < _maxDistanceLimit) {
        _loadMoreVendors(isExpandingDistance: true);
      }

      _createMarkers();
    } catch (e) {
      debugPrint("🔴 Explore: Filter error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreVendors({bool isExpandingDistance = false}) async {
    if (_isLoadingMore) return;
    if (_isLastPage && !isExpandingDistance) return;

    try {
      if (mounted) {
        setState(() {
          _isLoadingMore = true;
          if (isExpandingDistance) {
            _currentDistance += 20000;
            _isLastPage = false;
            _pageNumber = 1;
          }
        });
      }

      if (_currentLocation == null) return;
      final lat = _currentLocation!.latitude;
      final lng = _currentLocation!.longitude;
      // Always use _currentDistance when expanding, or if it has been expanded already
      final radius = (isExpandingDistance || _currentDistance > (selectedRadius?.toInt() ?? 0))
          ? _currentDistance.toDouble() 
          : (selectedRadius ?? _currentDistance.toDouble());

      debugPrint("🔵 Explore: Loading more page $_pageNumber at ${radius/1000}km");
      List<MixedVendorData> nextVendors = [];

      if (selectedFilter != "All") {
        nextVendors = await dataManager!.getMixedVendorsByCategoryWithRadius(
          context,
          selectedFilter,
          lat,
          lng,
          radius,
          pageNumber: _pageNumber,
          count: _pageSize,
        );
      } else if (searchQuery.isNotEmpty) {
        nextVendors = await dataManager!.searchVendors(
          context, 
          searchQuery,
          pageNumber: _pageNumber,
          count: _pageSize,
          maxDistance: radius.toInt(),
        );
      } else {
        nextVendors = await dataManager!.getMixedVendorsWithRadius(
          context,
          lat,
          lng,
          radius,
          pageNumber: _pageNumber,
          count: _pageSize,
        );
      }

      debugPrint("🟢 Explore: Received ${nextVendors.length} more items");

      if (mounted) {
        setState(() {
          if (nextVendors.isNotEmpty) {
            // Avoid duplicates if we reset page number (though currently we don't reset, but distance expansion might overlap)
            for (var v in nextVendors) {
              if (!allVendors.any((existing) => existing.id == v.id)) {
                allVendors.add(v);
              }
            }
            MixedVendorData.sortVendors(allVendors);
            filteredVendors = List.from(allVendors);
            _pageNumber++;
            if (nextVendors.length < _pageSize) {
              _isLastPage = true;
              debugPrint("🛑 Explore: Last page reached at current distance");
            }
          } else {
            _isLastPage = true;
            debugPrint("🛑 Explore: No more items at current distance (${_currentDistance/1000}km)");
            // If we reached the end during scroll, expand immediately
            if (_currentDistance < _maxDistanceLimit) {
              _isLoadingMore = false;
              _loadMoreVendors(isExpandingDistance: true);
              return;
            }
          }
          _isLoadingMore = false;
        });
      }

      // If we expanded search and still have no items, and haven't hit limit, try one more time
      if (allVendors.isEmpty && _currentDistance < _maxDistanceLimit && isExpandingDistance) {
        _loadMoreVendors(isExpandingDistance: true);
      }

      _createMarkers();
    } catch (e) {
      debugPrint("🔴 Explore: Load more error: $e");
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }


  bool _isVendorMatchingFilter(MixedVendorData vendor, String filter) {
    if (filter == "All") return true;
    
    // Check if vendor name contains the filter term
    if (vendor.name.toLowerCase().contains(filter.toLowerCase())) {
      return true;
    }
    
    // Check if any service matches the filter
    if (vendor.services.isNotEmpty) {
      for (String service in vendor.services) {
        if (_isServiceMatchingFilter(service, filter)) {
          return true;
        }
      }
    }
    
    // Check if category matches
    if (vendor.category != null && 
        vendor.category!.toLowerCase().contains(filter.toLowerCase())) {
      return true;
    }
    
    return false;
  }

  bool _isServiceMatchingFilter(String service, String filter) {
    String serviceLower = service.toLowerCase();
    String filterLower = filter.toLowerCase();
    
    // Direct match
    if (serviceLower.contains(filterLower)) {
      return true;
    }
    
    // Special mappings for common car service terms
    Map<String, List<String>> serviceMappings = {
      "Car Wash": ["car_wash", "carwash", "wash", "cleaning", "detailing"],
      "Car Repair": ["car_repair", "repair", "maintenance", "service", "fix"],
      "Car Service": ["service", "maintenance", "repair", "checkup"],
      "Auto Parts": ["parts", "accessories", "spare", "replacement"],
    };
    
    if (serviceMappings.containsKey(filter)) {
      return serviceMappings[filter]!.any((term) => serviceLower.contains(term));
    }
    
    return false;
  }

  Future<void> _getCurrentLocation() async {
    // Use stored location first (respects user's manual selection from home)
    try {
      String? latStr = sharedPreferences?.getString(Constant.lat);
      String? lngStr = sharedPreferences?.getString(Constant.long);
      if (latStr != null && lngStr != null && latStr != "null" && lngStr != "null" && latStr != "0.0") {
        _currentLocation = LatLng(double.parse(latStr), double.parse(lngStr));
        return;
      }
    } catch (_) {}

    // Only try GPS if no location is stored at all
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
      _currentLocation = LatLng(position.latitude, position.longitude);
      await sharedPreferences?.setString(Constant.lat, position.latitude.toString());
      await sharedPreferences?.setString(Constant.long, position.longitude.toString());
      dataManager?.syncLocationToApi(context, sharedPreferences?.getString(Constant.location) ?? "Current Location", position.latitude, position.longitude);
    } catch (_) {}
  }

  void _createMarkers() {
    _markers.clear();
    
    for (int i = 0; i < filteredVendors.length; i++) {
      final vendor = filteredVendors[i];
      
      // Check if vendor is offline (only for app vendors)
      bool isOffline = vendor.isAppVendor && !vendor.isOpen;
      
      _markers.add(
        Marker(
          markerId: MarkerId(vendor.id),
          position: LatLng(vendor.latitude, vendor.longitude),
          infoWindow: InfoWindow(
            title: vendor.name,
            snippet: vendor.isAppVendor ? "Vendor App" : "Google Places",
          ),
          onTap: () {
            if (vendor.isAppVendor) {
              _navigateToBooking(vendor);
            } else {
              _showGoogleVendorBottomSheet(vendor);
            }
          },
          // Pins: Custom blue for Vendor App, Red for Google Places
          icon: vendor.isAppVendor
              ? (_vendorIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure))
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  void _handleCameraMove(CameraPosition position) {
    _currentZoom = position.zoom;
    
    // Calculate radius based on zoom level
    double newRadius = _calculateRadiusFromZoom(_currentZoom);
    
    // Only fetch new data if radius has increased significantly (user zoomed out)
    if (newRadius > _lastFetchedRadius * 1.5) {
      _lastFetchedRadius = newRadius;
      
      // Debounce the API call to avoid too many requests
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        _loadVendorsForRadius(newRadius, position.target);
      });
    }
  }

  double _calculateRadiusFromZoom(double zoom) {
    // Convert zoom level to approximate radius in meters
    // Higher zoom = smaller radius, lower zoom = larger radius
    // Values converted from miles to meters (1 mile = 1609.34 meters)
    if (zoom >= 15) return 1609.34;  // 1 mile
    if (zoom >= 14) return 3218.69;  // 2 miles
    if (zoom >= 13) return 8046.72;  // 5 miles
    if (zoom >= 12) return 16093.44; // 10 miles
    if (zoom >= 11) return 32186.88; // 20 miles
    if (zoom >= 10) return 80467.2;  // 50 miles
    return 160934.4; // 100 miles for very low zoom
  }

  Future<void> _loadVendorsForRadius(double radius, LatLng center) async {
    try {
      
      // Get mixed vendors with new radius
      final mixedVendors = await dataManager!.getMixedVendorsWithRadius(
        context, 
        center.latitude, 
        center.longitude, 
        radius
      );
      
      if (mounted) {
        setState(() {
          allVendors = mixedVendors;
          filteredVendors = List.from(allVendors);
        });
      }
      
      // Update markers
      _createMarkers();
    } catch (e) {
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
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // Header
            Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF166534),
                  Color(0xFF192028),
                  Color(0xFF00E676),
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
            child: Column(
              children: [
                // Top Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CommonWidget.buildGreenHeaderBackButton(context),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Explore Nearby",
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: "Pop600",
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // View Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildToggleButton("List", Icons.list, !isMapView),
                          _buildToggleButton("Map", Icons.map, isMapView),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      // Only update the search query state, don't call API
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    onSubmitted: (value) {
                      // Call API only when user presses enter/submit
                      _filterVendors();
                    },
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: "Search vendors or location...",
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontFamily: "Pop400",
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[500]),
                              onPressed: () {
                                setState(() {
                                  searchQuery = "";
                                  _searchController?.clear();
                                });
                                _filterVendors(); // Refresh to show all vendors
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.search, color: ColorClass.base_color),
                              onPressed: () {
                                // Trigger search on icon tap
                                _filterVendors();
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Dropdowns - Category, Location, and Radius (Uniform Design)
                Row(
                  children: [
                    // Category Dropdown
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: DropdownButton<String>(
                          value: selectedFilter,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
                          items: filterOptions.map((String filter) {
                            return DropdownMenuItem<String>(
                              value: filter,
                              child: Row(
                                children: [
                                  if (filter == selectedFilter)
                                    Icon(
                                      Icons.check,
                                      size: 18,
                                      color: ColorClass.base_color,
                                    )
                                  else
                                    const SizedBox(width: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    filter,
                                    style: TextStyle(
                                      fontFamily: "Pop500",
                                      fontSize: 14,
                                      color: filter == selectedFilter 
                                          ? ColorClass.base_color 
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedFilter = newValue;
                              });
                              _filterVendors();
                            }
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Location Filter Button (Uniform size)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LocationPickerScreen(
                                  currentLocation: selectedLocation,
                                ),
                              ),
                            );
                            
                            if (result != null && mounted) {
                              setState(() {
                                selectedLocation = result['location'] as String?;
                                _currentLocation = LatLng(
                                  result['lat'] as double,
                                  result['lng'] as double,
                                );
                                // Save to shared preferences
                                sharedPreferences?.setString(Constant.location, selectedLocation ?? "");
                                sharedPreferences?.setString(Constant.lat, result['lat'].toString());
                                sharedPreferences?.setString(Constant.long, result['lng'].toString());
                              });
                              await _filterVendors();
                            }
                          },
                          child: Center(
                            child: Icon(
                              Icons.location_on,
                              color: selectedLocation != null ? ColorClass.base_color : Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Radius Dropdown (Uniform size)
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: PopupMenuButton<String>(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          height: 44,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune,
                                size: 18,
                                color: selectedRadiusOption != "10 miles" 
                                    ? ColorClass.base_color 
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                selectedRadiusOption,
                                style: TextStyle(
                                  color: selectedRadiusOption != "10 miles" 
                                      ? ColorClass.base_color 
                                      : Colors.black87,
                                  fontFamily: "Pop500",
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                        onSelected: (String value) async {
                          setState(() {
                            selectedRadiusOption = value;
                            selectedRadius = _parseRadius(value);
                          });
                          await _filterVendors();
                        },
                        itemBuilder: (BuildContext context) {
                          return radiusOptions.map((String option) {
                            return PopupMenuItem<String>(
                              value: option,
                              child: Row(
                                children: [
                                  if (option == selectedRadiusOption)
                                    Icon(
                                      Icons.check,
                                      size: 18,
                                      color: ColorClass.base_color,
                                    )
                                  else
                                    const SizedBox(width: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    option,
                                    style: TextStyle(
                                      fontFamily: "Pop500",
                                      fontSize: 14,
                                      color: option == selectedRadiusOption 
                                          ? ColorClass.base_color 
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: isLoading
                ? SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ShimmerLoader.buildListShimmer(itemCount: 8),
                    ),
                  )
                : isMapView
                    ? _buildMapView()
                    : RefreshIndicator(
                        onRefresh: () async {
                          if (mounted && context.mounted) {
                            await _loadVendors();
                          }
                        },
                        child: _buildListView(),
                      ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildToggleButton(String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isMapView = label == "Map";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? ColorClass.base_color : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontFamily: "Pop500",
                color: isSelected ? ColorClass.base_color : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (filteredVendors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No vendors found",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontFamily: "Pop500",
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentDistance > 30000 
                  ? "Searching within ${_currentDistance/1000}km..." 
                  : "Try adjusting your search or filters",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: "Pop400",
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredVendors.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredVendors.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  if (_isLastPage && _currentDistance < _maxDistanceLimit)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text("Expanding search radius to ${_currentDistance/1000 + 20}km...", 
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                    ),
                ],
              ),
            ),
          );
        }
        final vendor = filteredVendors[index];
        return _buildVendorCard(vendor);
      },
    );
  }

  Widget _buildMapView() {
    if (_currentLocation == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          child: GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              // Add a small delay to ensure map is fully loaded
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_markers.isNotEmpty) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngBounds(
                      _getBoundsForMarkers(),
                      100.0,
                    ),
                  );
                }
              });
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation!,
              zoom: 12.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            onTap: (LatLng position) {
              // Handle map tap if needed
            },
            onCameraMove: (CameraPosition position) {
              // Handle camera movement for zoom-based data fetching
              _handleCameraMove(position);
            },
          ),
        ),
        // Fallback for when Google Maps fails to load
        if (false) // This will be shown if Google Maps fails
          Container(
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Map temporarily unavailable",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontFamily: "Pop500",
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please try again later",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontFamily: "Pop400",
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Map controls overlay
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              // Current location button
              FloatingActionButton(
                mini: true,
                onPressed: () {
                  if (_mapController != null && _currentLocation != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLng(_currentLocation!),
                    );
                  }
                },
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.my_location,
                  color: ColorClass.base_color,
                ),
              ),
              const SizedBox(height: 8),
              // Zoom to fit all markers button
              FloatingActionButton(
                mini: true,
                onPressed: () {
                  if (_mapController != null && _markers.isNotEmpty) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        _getBoundsForMarkers(),
                        100.0,
                      ),
                    );
                  }
                },
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.fit_screen,
                  color: ColorClass.base_color,
                ),
              ),
            ],
          ),
        ),
        // Vendor count overlay
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${filteredVendors.length} vendors found",
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: "Pop500",
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Vendors",
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: "Pop400",
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Google Places",
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
          ),
        ),
      ],
    );
  }

  LatLngBounds _getBoundsForMarkers() {
    if (_markers.isEmpty) {
      return LatLngBounds(
        southwest: _currentLocation!,
        northeast: _currentLocation!,
      );
    }

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (Marker marker in _markers) {
      minLat = min(minLat, marker.position.latitude);
      maxLat = max(maxLat, marker.position.latitude);
      minLng = min(minLng, marker.position.longitude);
      maxLng = max(maxLng, marker.position.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Widget _buildVendorCard(MixedVendorData vendor) {
    final isAppVendor = vendor.isAppVendor;
    final isOffline = isAppVendor && !vendor.isOpen;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isOffline ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOffline ? Border.all(color: Colors.grey[300]!) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isAppVendor) {
              _navigateToBooking(vendor);
            } else {
              _showGoogleVendorBottomSheet(vendor);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Vendor Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: vendor.imageUrl != null && vendor.imageUrl!.isNotEmpty
                        ? Image.network(
                            vendor.imageUrl!,
                            fit: BoxFit.cover,
                            headers: const {
                              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildVendorIcon(isAppVendor);
                            },
                          )
                        : _buildVendorIcon(isAppVendor),
                  ),
                ),
                const SizedBox(width: 16),
                // Vendor Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vendor Type Tag
                      _buildVendorTypeTag(vendor.isAppVendor),
                      const SizedBox(height: 4),
                      // Vendor Name and Offline Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vendor.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: "Pop600",
                                color: isOffline ? Colors.grey[600] : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: vendor.isOpen ? ColorClass.base_light_color : Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                vendor.isOpen ? "OPEN NOW" : "CLOSED",
                                style: TextStyle(
                                  color: vendor.isOpen ? ColorClass.base_color : Colors.red[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Location
                      Text(
                        vendor.address ?? "Location not available",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: "Pop400",
                          color: isOffline ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Distance and Type
                      Row(
                        children: [
                          ...[
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${(vendor.distance! * 0.000621371).toStringAsFixed(1)} miles",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: "Pop400",
                              color: isOffline ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                          // Vendor Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOffline
                                  ? Colors.red.withOpacity(0.1)
                                  : isAppVendor 
                                      ? ColorClass.base_color.withOpacity(0.1)
                                      : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOffline 
                                  ? "Offline" 
                                  : isAppVendor 
                                      ? "App Vendor" 
                                      : "Google Places",
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: "Pop500",
                                color: isOffline
                                    ? Colors.red
                                    : isAppVendor 
                                        ? ColorClass.base_color 
                                        : Colors.blue,
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
        ),
      ),
    );
  }

  Widget _buildVendorIcon(bool isAppVendor) {
    return Container(
      decoration: BoxDecoration(
        color: (isAppVendor ? ColorClass.base_color : Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isAppVendor ? Icons.business : Icons.location_on,
        size: 40,
        color: isAppVendor ? ColorClass.base_color : Colors.blue,
      ),
    );
  }

  void _navigateToBooking(MixedVendorData vendor) {
    // Navigate to specialists page for app vendors
    CommonWidget.navigateToScreen(
      context,
      SpecialistsActivity(vendor.id),
    );
  }

  void _showGoogleVendorBottomSheet(MixedVendorData vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Vendor Image and Name
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: vendor.imageUrl != null && vendor.imageUrl!.isNotEmpty
                          ? Image.network(
                              vendor.imageUrl!,
                              fit: BoxFit.cover,
                              headers: const {
                                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return _buildVendorIcon(false);
                              },
                            )
                          : _buildVendorIcon(false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: "Pop600",
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vendor.address ?? "Location not available",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Pop400",
                            color: Colors.grey[600],
                          ),
                        ),
                        ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${(vendor.distance! * 0.000621371).toStringAsFixed(1)} miles away",
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: "Pop400",
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                      ],
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
                      onPressed: () {
                        _openGoogleMaps(vendor);
                      },
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text(
                        "Navigate",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Pop500",
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorClass.base_color,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _callVendor(vendor);
                      },
                      icon: const Icon(Icons.phone, color: Colors.white),
                      label: const Text(
                        "Call",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Pop500",
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorClass.base_color,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Additional Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
            ],
          ),
        ),
      ),
    );
  }

  void _openGoogleMaps(MixedVendorData vendor) async {
    final String userId = sharedPreferences?.getString(Constant.id) ?? "";
    if (userId.isEmpty) {
      _showLoginRequiredDialog(context, "Sign in to view directions.");
      return;
    }
    if (vendor.latitude != 0 && vendor.longitude != 0) {
      final lat = vendor.latitude;
      final lng = vendor.longitude;
      final url = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng";
      
      try {
        if (await canLaunch(url)) {
          await launch(url);
        } else {
        }
      } catch (e) {
      }
    }
  }

  void _callVendor(MixedVendorData vendor) async {
    final String userId = sharedPreferences?.getString(Constant.id) ?? "";
    if (userId.isEmpty) {
      _showLoginRequiredDialog(context, "Sign in to call this vendor.");
      return;
    }
    final raw = vendor.phone?.trim();
    if (raw == null || raw.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number not available for this vendor')),
        );
      }
      return;
    }
    final phone = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number not available for this vendor')),
        );
      }
      return;
    }
    try {
      final Uri telUri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open phone dialer')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start call')),
        );
      }
    }
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

  void _showOfflineMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("This vendor is currently offline"),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildVendorTypeTag(bool isAppVendor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAppVendor ? ColorClass.base_color.withOpacity(0.1) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAppVendor ? ColorClass.base_color.withOpacity(0.3) : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAppVendor ? Icons.verified_user_rounded : Icons.location_on,
            color: isAppVendor ? ColorClass.base_color : Colors.blue.shade700,
            size: 11,
          ),
          const SizedBox(width: 5),
          Text(
            isAppVendor ? "PARTNER" : "GOOGLE",
            style: TextStyle(
              color: isAppVendor ? ColorClass.base_color : Colors.blue.shade700,
              fontSize: 10,
              fontFamily: "Pop700",
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
