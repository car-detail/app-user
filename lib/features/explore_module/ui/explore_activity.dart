import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../../home_module/model/services_model_data.dart';
import '../../home_module/model/mixed_vendor_data.dart';
import '../../home_module/data_manager/home_data_manager.dart';
import '../../booking/ui/booking_activity.dart';
import '../../specialists_module/ui/specialists_activity.dart';

class ExploreActivity extends StatefulWidget {
  const ExploreActivity({super.key});

  @override
  State<ExploreActivity> createState() => _ExploreActivityState();
}

class _ExploreActivityState extends State<ExploreActivity> {
  List<MixedVendorData> allVendors = [];
  List<MixedVendorData> filteredVendors = [];
  bool isMapView = false;
  bool isLoading = true;
  String searchQuery = "";
  String selectedFilter = "All";
  
  HomeDataManager? dataManager;
  SharedPreferences? sharedPreferences;

  List<String> filterOptions = ["All"]; // will be loaded dynamically
  
  // Map related variables
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _currentLocation;
  LatLng _defaultLocation = LatLng(30.7200094, 76.7080831); // Chandigarh
  BitmapDescriptor? _vendorIcon;
  
  // Zoom and radius tracking
  double _currentZoom = 12.0;
  double _lastFetchedRadius = 10000; // 10km default
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = HomeDataManager(sharedPreferences!);
    await _loadIcons();
    await _loadCategories();
    await _loadVendors();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await dataManager!.getcategory(context);
      final body = await response.body;
      final data = body is String ? body : body.toString();
      final decoded = jsonDecode(data);
      if (decoded['status'] == 'success' && decoded['data'] != null) {
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

  Future<void> _loadVendors() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get mixed vendors (app + Google Places)
      final mixedVendors = await dataManager!.getMixedVendors(context);
      
      // Get current location
      await _getCurrentLocation();
      
      setState(() {
        allVendors = mixedVendors;
        filteredVendors = List.from(allVendors);
        isLoading = false;
      });
      
      // Create markers for map
      _createMarkers();
    } catch (e) {
      print('Error loading vendors: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _filterVendors() async {
    print('Filtering vendors with query: "$searchQuery" and filter: "$selectedFilter"');
    try {
      List<MixedVendorData> vendors = [];

      final lat = _currentLocation?.latitude ?? _defaultLocation.latitude;
      final lng = _currentLocation?.longitude ?? _defaultLocation.longitude;

      if (selectedFilter != "All") {
        vendors = await dataManager!.getMixedVendorsByCategoryWithRadius(
          context,
          selectedFilter,
          lat,
          lng,
          _lastFetchedRadius,
        );
      } else if (searchQuery.isNotEmpty) {
        vendors = await dataManager!.searchVendors(context, searchQuery);
      } else {
        vendors = await dataManager!.getMixedVendorsWithRadius(
          context,
          lat,
          lng,
          _lastFetchedRadius,
        );
      }

      setState(() {
        allVendors = vendors;
        filteredVendors = List.from(allVendors);
      });

      _createMarkers();
      print('Filtered vendors count (from API): ${filteredVendors.length}');
    } catch (e) {
      print('Error filtering vendors: $e');
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
    try {
      String? latStr = sharedPreferences?.getString(Constant.lat);
      String? lngStr = sharedPreferences?.getString(Constant.long);
      
      if (latStr != null && lngStr != null && latStr != "null" && lngStr != "null") {
        _currentLocation = LatLng(double.parse(latStr), double.parse(lngStr));
      } else {
        _currentLocation = _defaultLocation;
      }
    } catch (e) {
      print('Error getting current location: $e');
      _currentLocation = _defaultLocation;
    }
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
            // Prevent navigation for offline vendors
            if (isOffline) {
              _showOfflineMessage();
              return;
            }
            
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
      _debounceTimer = Timer(Duration(seconds: 2), () {
        _loadVendorsForRadius(newRadius, position.target);
      });
    }
  }

  double _calculateRadiusFromZoom(double zoom) {
    // Convert zoom level to approximate radius in meters
    // Higher zoom = smaller radius, lower zoom = larger radius
    if (zoom >= 15) return 1000;  // 1km
    if (zoom >= 14) return 2000;  // 2km
    if (zoom >= 13) return 5000;  // 5km
    if (zoom >= 12) return 10000; // 10km
    if (zoom >= 11) return 20000; // 20km
    if (zoom >= 10) return 50000; // 50km
    return 100000; // 100km for very low zoom
  }

  Future<void> _loadVendorsForRadius(double radius, LatLng center) async {
    try {
      print('Loading vendors for radius: ${radius}m at ${center.latitude}, ${center.longitude}');
      
      // Get mixed vendors with new radius
      final mixedVendors = await dataManager!.getMixedVendorsWithRadius(
        context, 
        center.latitude, 
        center.longitude, 
        radius
      );
      
      setState(() {
        allVendors = mixedVendors;
        filteredVendors = List.from(allVendors);
      });
      
      // Update markers
      _createMarkers();
    } catch (e) {
      print('Error loading vendors for radius: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) {
          CommonWidget.safePop(context);
          return false;
        }
        return true;
      },
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
              color: ColorClass.base_color,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                // Top Row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => CommonWidget.safePop(context),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
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
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                      _filterVendors();
                    },
                    decoration: InputDecoration(
                      hintText: "Search vendors...",
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontFamily: "Pop400",
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterOptions.map((filter) {
                      final isSelected = selectedFilter == filter;
                      return Container(
                        margin: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? ColorClass.base_color : Colors.black87,
                              fontFamily: "Pop500",
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedFilter = filter;
                            });
                            _filterVendors();
                          },
                          backgroundColor: Colors.white.withOpacity(0.9),
                          selectedColor: Colors.white,
                          checkmarkColor: ColorClass.base_color,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
                    ),
                  )
                : isMapView
                    ? _buildMapView()
                    : _buildListView(),
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
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              "Try adjusting your search or filters",
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
      padding: EdgeInsets.all(16),
      itemCount: filteredVendors.length,
      itemBuilder: (context, index) {
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
              Future.delayed(Duration(milliseconds: 500), () {
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${filteredVendors.length} vendors found",
                  style: TextStyle(
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
                      decoration: BoxDecoration(
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
                      decoration: BoxDecoration(
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
            // Prevent navigation for offline vendors
            if (isOffline) {
              _showOfflineMessage();
              return;
            }
            
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
                            headers: {
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
                          if (isOffline)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "OFFLINE",
                                style: TextStyle(
                                  color: Colors.red[700],
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
                          if (vendor.distance != null) ...[
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
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                // Action Icon
                Icon(
                  isOffline 
                      ? Icons.block 
                      : isAppVendor 
                          ? Icons.book_online 
                          : Icons.info_outline,
                  size: 20,
                  color: isOffline 
                      ? Colors.red 
                      : isAppVendor 
                          ? ColorClass.base_color 
                          : Colors.blue,
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
        decoration: BoxDecoration(
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
                              headers: {
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
                          style: TextStyle(
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
                        if (vendor.distance != null) ...[
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
                      icon: Icon(Icons.directions, color: Colors.white),
                      label: Text(
                        "Navigate",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Pop500",
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorClass.base_color,
                        padding: EdgeInsets.symmetric(vertical: 12),
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
                      icon: Icon(Icons.phone, color: Colors.white),
                      label: Text(
                        "Call",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Pop500",
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 12),
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
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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
    if (vendor.latitude != 0 && vendor.longitude != 0) {
      final lat = vendor.latitude;
      final lng = vendor.longitude;
      final url = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng";
      
      try {
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          print("Could not launch $url");
        }
      } catch (e) {
        print("Error launching maps: $e");
      }
    }
  }

  void _callVendor(MixedVendorData vendor) {
    // You can implement phone calling functionality here
    // For now, just show a message
    print("Calling vendor: ${vendor.name}");
  }

  void _showOfflineMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("This vendor is currently offline"),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
