import 'dart:async';
import 'dart:convert';
import 'package:car_app/Api/ApiFuntion.dart';
import 'package:car_app/Common/CommonBean.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Common/Color.dart';
import '../../categories_module/ui/sevice_list_screen.dart';
import '../../home_module/model/services_model_data.dart';
import '../../specialists_module/ui/specialists_activity.dart';
import '../data_manager/explore_list_data_manager.dart';
import '../model/location_list_model_bean.dart';

class ExploreListMapActivity extends StatefulWidget {
  const ExploreListMapActivity({super.key});

  @override
  State<ExploreListMapActivity> createState() => _ExploreListMapActivityState();
}

class _ExploreListMapActivityState extends State<ExploreListMapActivity> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  List<ServicesData> servicesData = [];
  String selectedCategory = 'All';
  List<String> categories = ['All']; // Will be loaded dynamically from API
  String searchTerm = '';
  final TextEditingController _searchController = TextEditingController();
  int googleVendorCount = 0;
  int appVendorCount = 0;
  CameraPosition _kGooglePlex = const CameraPosition(
    target: LatLng(0.0, 0.0),
    zoom: 14.4746,
  );
  ExploreListDataManager? dataManager;
  LatLng _current = const LatLng(0.0, 0.0);
  Set<Marker> markers = {};
  late SharedPreferences? sharedPreferences;
  BitmapDescriptor? carIcon;

  // Pagination & Distance states
  final ScrollController _scrollController = ScrollController();
  int _pageNumber = 1;
  bool _isLoading = false;
  bool _isLastPage = false;
  final int _pageSize = 20;
  int _currentDistance = 30000;
  final int _maxDistanceLimit = 150000;


  Future<void> loadCustomMarker() async {
    carIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/car_loction.png',
    );
  }
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    start();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.95 &&
        !_isLoading) {
      if (!_isLastPage) {
        getVendorsWithCategory(selectedCategory, isLoadMore: true);
      } else if (_currentDistance < _maxDistanceLimit) {
        debugPrint("🔄 Auto-expanding distance on map list...");
        getVendorsWithCategory(selectedCategory, isLoadMore: true, isExpandingDistance: true);
      }
    }
  }

  start() async {
    loadCustomMarker();
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = ExploreListDataManager(sharedPreferences!);

    // Resolve real location BEFORE loading vendors so API gets correct coords
    final storedLat = sharedPreferences!.getString(Constant.lat);
    final storedLng = sharedPreferences!.getString(Constant.long);
    final hasStoredLocation = storedLat != null && storedLat != "" && storedLat != "0.0" && storedLat != "null";

    if (hasStoredLocation) {
      // Use stored coords (already updated by home screen GPS refresh)
      final lat = double.parse(storedLat!);
      final lng = double.parse(sharedPreferences!.getString(Constant.long) ?? "0.0");
      setState(() {
        _current = LatLng(lat, lng);
        _kGooglePlex = CameraPosition(target: _current, zoom: 14.4746);
      });
    } else if (await _handleLocationPermission()) {
      // No stored coords — get GPS directly
      var position = await _determinePosition();
      await sharedPreferences!.setString(Constant.lat, position.latitude.toString());
      await sharedPreferences!.setString(Constant.long, position.longitude.toString());
      setState(() {
        _current = LatLng(position.latitude, position.longitude);
        _kGooglePlex = CameraPosition(target: _current, zoom: 14.4746);
      });
    }

    // Now load vendors with correct coords in SharedPreferences
    await loadAllVendors();

    // Animate map and add current location marker
    try {
      final GoogleMapController controller = await _controller.future;
      await controller.animateCamera(CameraUpdate.newCameraPosition(_kGooglePlex));
    } catch (_) {}

    if (mounted) {
      setState(() {
        markers.add(Marker(
          markerId: const MarkerId("Current Location"),
          position: _current,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      });
    }
  }

  Future<void> loadAllVendors() async {
    await loadCategories();
    _currentDistance = 30000;
    await getVendorsWithCategory(selectedCategory);
  }

  Future<void> loadCategories() async {
    try {
      var response = await dataManager!.getCategories(context);
      var data = jsonDecode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        setState(() {
          categories = ['All'];
          for (var category in data['data']) {
            if (category['categoryTitle'] != null && category['isActive'] == true) {
              categories.add(category['categoryTitle']);
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
  }

  Future<void> getVendorsWithCategory(String category, {bool isLoadMore = false, bool isExpandingDistance = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (!isLoadMore) {
        _pageNumber = 1;
        _isLastPage = false;
        _currentDistance = 30000;
      }
      if (isExpandingDistance) {
        _currentDistance += 20000;
        _isLastPage = false;
        _pageNumber = 1;
      }
    });

    try {
      debugPrint("🔵 Fetching map page $_pageNumber at ${_currentDistance/1000}km");
      var response = await dataManager!.getAllVendors(
        context, 
        pageNumber: _pageNumber,
        count: _pageSize,
        category: category,
        searchTerm: searchTerm.isNotEmpty ? searchTerm : null,
        maxDistance: _currentDistance,
      );
      
      var data = ServicesModelData.fromJson(jsonDecode(response.body));

      if (data.status == "success") {
        setState(() {
          if (!isLoadMore) {
            servicesData.clear();
            markers.clear();
            googleVendorCount = 0;
            appVendorCount = 0;
            markers.add(
              Marker(
                markerId: const MarkerId("Current Location"),
                position: _current,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            );
          }

          if (data.data != null && data.data!.isNotEmpty) {
            servicesData.addAll(data.data!);
            _pageNumber++;
            
            if (data.data!.length < _pageSize) {
              _isLastPage = true;
              debugPrint("🛑 Explore Map: Last page reached at ${_currentDistance/1000}km");
              
              // If we reached last page and have very few results, expand immediately
              if (servicesData.length < 5 && _currentDistance < _maxDistanceLimit) {
                _isLoading = false;
                getVendorsWithCategory(category, isLoadMore: true, isExpandingDistance: true);
                return;
              }
            }

            for (var vendor in data.data!) {
              double lat = vendor.location?.coordinates?.lat ?? 0.0;
              double lng = vendor.location?.coordinates?.long ?? 0.0;
              String name = vendor.displayName ?? "";
              
              final vendorCategory = (vendor.category ?? '').toLowerCase();
              final isAppVendor = (vendor.isAppVendor == true) || (!vendorCategory.contains('google'));
              final isGoogleVendor = !isAppVendor;
              bool isOffline = isAppVendor && !(vendor.isShopOpen ?? true);
              
              if (isGoogleVendor) googleVendorCount++; else appVendorCount++;
              
              markers.add(
                Marker(
                  markerId: MarkerId("${vendor.sId}_$name"),
                  position: LatLng(lat, lng),
                  onTap: () {
                    CommonWidget.navigateToScreen(context, SpecialistsActivity(vendor.sId ?? ''));
                  },
                  icon: isGoogleVendor 
                      ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed) 
                      : (carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)),
                  infoWindow: InfoWindow(
                    title: name,
                    snippet: isGoogleVendor ? "Google Places" : "Vendor App",
                  ),
                ),
              );
            }
          } else {
            _isLastPage = true;
            debugPrint("🛑 Explore Map: No more items at ${_currentDistance/1000}km");
            
            if (_currentDistance < _maxDistanceLimit) {
              _isLoading = false;
              getVendorsWithCategory(category, isLoadMore: true, isExpandingDistance: true);
              return;
            }
          }
          _isLoading = false;
        });
        
        // Auto-expand once if empty
        if (servicesData.isEmpty && _currentDistance < _maxDistanceLimit && !isExpandingDistance) {
           getVendorsWithCategory(selectedCategory, isLoadMore: true, isExpandingDistance: true);
        }
      } else {
        setState(() => _isLoading = false);
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error: $e");
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition();
  }

  var isList = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CommonWidget.gettopbar(
            "Explore",
            context,
            isBack: false,
          ),
          Container(
            margin: const EdgeInsets.all(5),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.all(Radius.circular(25))),
            child: Row(
              children: [
                Expanded(
                    child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isList = true;
                    });
                  },
                  child: CommonWidget.getButtonWidget(
                      "List View",
                      isList ? ColorClass.base_color : Colors.grey[300]!,
                      isList ? ColorClass.base_color : Colors.grey[300]!,
                      textcolor: isList ? Colors.white : ColorClass.base_color),
                )),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isList = false;
                      });
                    },
                    child: CommonWidget.getButtonWidget(
                        "Map View",
                        !isList ? ColorClass.base_color : Colors.grey[300]!,
                        !isList ? ColorClass.base_color : Colors.grey[300]!,
                        textcolor:
                            !isList ? Colors.white : ColorClass.base_color),
                  ),
                ),
              ],
            ),
          ),
          // Search Field
          Container(
            margin: const EdgeInsets.all(5),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search vendors...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchTerm = '';
                          });
                          getVendorsWithCategory(selectedCategory);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: ColorClass.base_color),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchTerm = value;
                });
              },
              onSubmitted: (value) {
                getVendorsWithCategory(selectedCategory);
              },
            ),
          ),
          // Category Filter
          Container(
            margin: const EdgeInsets.all(5),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        bool isSelected = selectedCategory == categories[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategory = categories[index];
                              });
                              getVendorsWithCategory(selectedCategory);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? ColorClass.base_color : Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: isSelected ? ColorClass.base_color : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                categories[index],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await loadCategories();
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Categories',
                ),
              ],
            ),
          ),
          if (!isList)
            Expanded(
              child: GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _kGooglePlex,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  markers: markers
              ),
            ),
          if (!isList)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "${servicesData.length} vendors found",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_currentDistance > 30000)
                    Text("Searching within ${_currentDistance/1000}km", style: TextStyle(fontSize: 12, color: ColorClass.base_color)),
                  const SizedBox(height: 4),
                  Text(
                    "Google Places: $googleVendorCount | Vendors: $appVendorCount",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text("Google Places", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text("Vendors", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (isList)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    if (_currentDistance > 30000 && servicesData.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text("Showing results up to ${_currentDistance / 1000}km", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        itemCount: servicesData.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == servicesData.length) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    const CircularProgressIndicator(),
                                    if (_isLastPage && _currentDistance < _maxDistanceLimit)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text("Expanding range to ${_currentDistance/1000 + 20}km...", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }
                          var vendor = servicesData[index];
                          bool isOffline = (vendor.isAppVendor ?? false) && !(vendor.isShopOpen ?? true);
                          
                          return GestureDetector(
                            onTap: () {
                              CommonWidget.navigateToScreen(context, SpecialistsActivity(vendor.sId ?? ''));
                            },
                            child: Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: isOffline ? Colors.grey[50] : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(vendor.displayName ?? "", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isOffline ? Colors.grey : ColorClass.base_color)),
                                        ),
                                        if (isOffline)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                                            child: Text("OFFLINE", style: TextStyle(color: Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(child: Text(vendor.location?.name ?? "", style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        const SizedBox(width: 8),
                                        Text("${(vendor.distance ?? 0.0).toStringAsFixed(1)} km", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _buildVendorImage(vendor, isOffline),
                                    ),
                                  ],
                                )),
                          );
                        }),
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildVendorImage(ServicesData vendor, bool isOffline) {
    String? imageUrl = vendor.displayPicture;
    if ((imageUrl == null || imageUrl.isEmpty) && vendor.services.isNotEmpty) {
      imageUrl = vendor.services.first.coverImage;
    }

    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              color: isOffline ? Colors.grey : null,
              colorBlendMode: isOffline ? BlendMode.saturation : null,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(child: Icon(Icons.store, size: 50, color: Colors.grey));
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      CommonWidget.errorShowSnackBarFor(context, 'Location services are disabled. Please enable them.');
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        CommonWidget.errorShowSnackBarFor(context, 'Location permissions are denied');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      CommonWidget.errorShowSnackBarFor(context, 'Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }
    return true;
  }
}
