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
    target: LatLng(30.707600, 76.715126),
    zoom: 14.4746,
  );
  ExploreListDataManager? dataManager;
  final CameraPosition _kLake = const CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      zoom: 19.151926040649414);
  LatLng _current = const LatLng(30.707600, 76.715126);
  Set<Marker> markers = {};
  late SharedPreferences? sharedPreferences;
  BitmapDescriptor? carIcon;

  Future<void> loadCustomMarker() async {
    carIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/car_loction.png',
    );
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    loadCustomMarker();
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = ExploreListDataManager(sharedPreferences!);
    
    // Load both app vendors and Google Places vendors
    await loadAllVendors();
    if (sharedPreferences!.getString(Constant.lat) != "" &&
        sharedPreferences!.getString(Constant.lat) != null &&
        sharedPreferences!.getString(Constant.lat) != "0.0") {
      setState(() {
        _kGooglePlex = CameraPosition(
          target: LatLng(
              double.parse(sharedPreferences!.getString(Constant.lat) ?? "0.0"),
              double.parse(
                  sharedPreferences!.getString(Constant.long) ?? "0.0")),
          zoom: 14.4746,
        );
        _current = LatLng(
            double.parse(sharedPreferences!.getString(Constant.lat) ?? "0.0"),
            double.parse(sharedPreferences!.getString(Constant.long) ?? "0.0"));
        markers.add(
          Marker(
            markerId: const MarkerId("Current Location"),
            position: _current,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed),
          ),
        );
      });
      final GoogleMapController controller = await _controller.future;
      await controller
          .animateCamera(CameraUpdate.newCameraPosition(_kGooglePlex));
      //_fetchNearbyPetrolPumps();
    } else {
      if (await _handleLocationPermission()) {
        var possition = await _determinePosition();
        setState(() {
          _current = LatLng(possition.latitude, possition.longitude);
          _kGooglePlex = CameraPosition(
            target: LatLng(possition.latitude, possition.longitude),
            zoom: 14.4746,
          );
          markers.add(
            Marker(
              markerId: const MarkerId("Current Location"),
              position: _current,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ),
          );
        });
        final GoogleMapController controller = await _controller.future;
        await controller
            .animateCamera(CameraUpdate.newCameraPosition(_kGooglePlex));
      }
    }
  }

  Future<void> loadAllVendors() async {
    // Load categories first, then vendors
    await loadCategories();
    await getVendorsWithCategory(selectedCategory);
  }

  Future<void> loadCategories() async {
    try {
      print('🔄 Loading categories from API...');
      var response = await dataManager!.getCategories(context);
      print('📋 Categories API response status: ${response.statusCode}');
      print('📋 Categories API response body: ${response.body}');
      
      var data = jsonDecode(response.body);
      
      if (data['status'] == 'success' && data['data'] != null) {
        setState(() {
          categories = ['All']; // Always include 'All' option
          for (var category in data['data']) {
            if (category['categoryTitle'] != null && category['isActive'] == true) {
              categories.add(category['categoryTitle']);
              print('✅ Added category: ${category['categoryTitle']}');
            }
          }
        });
        print('📋 Final categories list: $categories');
      } else {
        print('⚠️ Categories API failed, using defaults');
        setState(() {
          categories = ['All', 'Car Wash', 'Car Repair', 'Car Service', 'Tire Service', 'Electrical Service'];
        });
      }
    } catch (e) {
      print('❌ Error loading categories: $e');
      // Keep default categories if API fails
      setState(() {
        categories = ['All', 'Car Wash', 'Car Repair', 'Car Service', 'Tire Service', 'Electrical Service'];
      });
    }
  }

  Future<void> getVendorsWithCategory(String category) async {
    try {
      print('🔄 Loading vendors for category: $category');
      
      var response = await dataManager!.getAllVendors(
        context, 
        category: category,
        searchTerm: searchTerm.isNotEmpty ? searchTerm : null,
      );
      var data = ServicesModelData.fromJson(jsonDecode(response.body));
      
      print('📊 Vendors API response status: ${data.status}');
      print('📊 Vendors count: ${data.data?.length ?? 0}');
      
      if (data.status == "success") {
        setState(() {
          servicesData.clear();
          servicesData.addAll(data.data!);
          markers.clear();
          
          print('🗺️ Adding markers for ${servicesData.length} vendors');
          
          // Debug: Print vendor data
          for (int i = 0; i < servicesData.length && i < 3; i++) {
            var vendor = servicesData[i];
            print('🔍 Vendor $i: ${vendor.displayName}, isAppVendor: ${vendor.isAppVendor}, isShopOpen: ${vendor.isShopOpen}');
          }
          
          // Reset vendor counts
          googleVendorCount = 0;
          appVendorCount = 0;
          
          // Add current location marker
          markers.add(
            Marker(
              markerId: const MarkerId("Current Location"),
              position: _current,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
          
          // Add vendor markers with different colors for app vs Google vendors
          for (var vendor in servicesData) {
            double lat = vendor.location?.coordinates?.lat ?? 0.0;
            double lng = vendor.location?.coordinates?.long ?? 0.0;
            String name = vendor.displayName ?? "";
            
            // Determine vendor source: App vs Google Places
            final vendorCategory = (vendor.category ?? '').toLowerCase();
            final isAppVendor = (vendor.isAppVendor == true) || (!vendorCategory.contains('google'));
            final isGoogleVendor = !isAppVendor;

            // Check if vendor is offline (only for app vendors)
            bool isOffline = isAppVendor && !(vendor.isShopOpen ?? true);
            
            // Count vendors by type
            if (isGoogleVendor) {
              googleVendorCount++;
            } else {
              appVendorCount++;
            }
            
            print('📍 Vendor: $name, isGoogle: $isGoogleVendor, isAppVendor: ${vendor.isAppVendor}, isShopOpen: ${vendor.isShopOpen}, isOffline: $isOffline, category: ${vendor.category}');
            print('🔍 Raw vendor data: ${vendor.toJson()}');
            
            markers.add(
              Marker(
                markerId: MarkerId(name),
                position: LatLng(lat, lng),
                onTap: () {
                  // Prevent navigation for offline vendors
                  if (isOffline) {
                    CommonWidget.errorShowSnackBarFor(context, "This vendor is currently offline");
                    return;
                  }
                  
                  // Navigate directly to vendor details page
                  CommonWidget.navigateToScreen(
                    context,
                    SpecialistsActivity(vendor.sId ?? ''),
                  );
                },
                icon: isGoogleVendor 
                    ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed) // Red for Google vendors
                    : (carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)), // Custom blue icon for app vendors
                infoWindow: InfoWindow(
                  title: name,
                  snippet: isGoogleVendor 
                      ? "Google Places" 
                      : "Vendor App",
                ),
              ),
            );
          }
          
          print('🗺️ Total markers added: ${markers.length}');
          print('📊 Google vendors: $googleVendorCount, App vendors: $appVendorCount');
        });
      } else {
        CommonWidget.safePop(context);
        print('❌ Vendors API failed: ${data.message}');
        CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
      print('❌ Error loading vendors: $e');
      if (context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error: $e");
      }
    }
  }

  Future<void> _fetchNearbyPetrolPumps() async {
    print(
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_current.latitude},${_current.longitude}&radius=10000&type=car_wash&key=AIzaSyBFtrosISezP-8z2NwTWKhD_5pNHoi0wRw");
    String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_current.latitude},${_current.longitude}&radius=10000&type=car_wash&key=AIzaSyBFtrosISezP-8z2NwTWKhD_5pNHoi0wRw";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
      final data = LocationListModelBean.fromJson(jsonDecode(response.body));
      if (data.status == "OK") {
        print("========================================${response.statusCode}");
        print("========================================${response.body}");
        for (var place in data.results) {
          double lat = place.geometry!.location!.lat!;
          double lng = place.geometry!.location!.lng!;
          String name = place.name ?? "";
          setState(() {
            markers.add(
              Marker(
                markerId: MarkerId(name),
                position: LatLng(lat, lng),
                onTap: () {
                 /* _showBottomSheet(name, lat, lng, place.vicinity ?? "",
                      place.placeId ?? "");*/
                },
                //infoWindow: InfoWindow(title: name),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
              ),
            );
          });
        }
      } else {
        print("========================================${response.statusCode}");
        print("========================================${response.body}");
      }
    } else {
      if (context.mounted && Navigator.canPop(context)) {
        CommonWidget.safePop(context);
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    /*if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }*/

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        permission = await Geolocator.requestPermission();
//        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  var isList = true;

  getServicesNew(BuildContext context) async {
    var response = await dataManager!.getAllServices(context);
    var data = ServicesModelData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        servicesData.clear();
        servicesData.addAll(data.data!);
        for (var place in servicesData) {
          double lat = place.location?.coordinates?.lat??0.0;
          double lng = place.location?.coordinates?.long??0.0;
          String name = place.displayName ?? "";
          setState(() {
            print("=======================$lat =====================$lng");
            markers.add(
              Marker(
                markerId: MarkerId(name),
                position: LatLng(lat, lng),
                onTap: () {
                  // Navigate directly to vendor details page
                  CommonWidget.navigateToScreen(
                    context,
                    SpecialistsActivity(place.sId ?? ''),
                  );
                },
                //infoWindow: InfoWindow(title: name),
                // icon: place.services.length>0?(carIcon ?? BitmapDescriptor.defaultMarker): BitmapDescriptor.defaultMarkerWithHue(
                //     BitmapDescriptor.hueGreen),
                icon: (carIcon ?? BitmapDescriptor.defaultMarker),
              ),
            );
          });
        }
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

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
                  child: Container(
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
                // Refresh categories button
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

                  /*{
          Marker(
              markerId: MarkerId(
                "mohali",
              ),
              icon: BitmapDescriptor.defaultMarker,
              position: _location),
          Marker(
              markerId: MarkerId(
                "_currentlocation",
              ),
              icon: BitmapDescriptor.defaultMarker,
              position: _current)
        },*/
                  ),
            ),
          // Vendor count and legend
          if (!isList)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "${servicesData.length} vendors found",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text("Google Places", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 12),
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
              child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: servicesData.length,
                  itemBuilder: (context, index) {
                    var vendor = servicesData[index];
                    bool isOffline = (vendor.isAppVendor ?? false) && !(vendor.isShopOpen ?? true);
                    
                    return GestureDetector(
                      onTap: () {
                        // Prevent navigation for offline vendors
                        if (isOffline) {
                          CommonWidget.errorShowSnackBarFor(context, "This vendor is currently offline");
                          return;
                        }
                        
                        // Navigate directly to vendor details page
                        CommonWidget.navigateToScreen(
                          context,
                          SpecialistsActivity(vendor.sId ?? ''),
                        );
                      },
                      child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isOffline ? Colors.grey[100] : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: isOffline ? Border.all(color: Colors.grey[300]!) : null,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: CommonWidget.getTextWidget600(
                                        vendor.displayName ?? "", 18,
                                        textAlign: TextAlign.start,
                                        color: isOffline ? (Colors.grey[600] ?? Colors.grey) : ColorClass.base_color),
                                  ),
                                  if (isOffline)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              const SizedBox(
                                height: 0,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: CommonWidget.getTextWidget500(
                                        vendor.location?.name ?? "",
                                        textAlign: TextAlign.start,
                                        color: isOffline ? Colors.grey[500]! : ColorClass.base_color),
                                  ),
                                  CommonWidget.getTextWidget500(
                                    "${((vendor.distance ?? 0.0) / 1609.34).toStringAsFixed(2)} miles",
                                    color: isOffline ? Colors.grey[400]! : Colors.grey[500]!
                                  )
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Stack(
                                children: [
                                  _buildVendorImage(vendor, isOffline),
                                  if (isOffline)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withOpacity(0.3),
                                        child: const Center(
                                          child: Text(
                                            "OFFLINE",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Divider(
                                height: 1,
                                color: ColorClass.base_color,
                              )
                            ],
                          )),
                    );
                  }),
            ))
        ],
      ),
      /*floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _goToTheLake();
        },
        label: const Text('My Location'),
        icon: const Icon(Icons.my_location_outlined),
      ),*/
    );
  }

  void _showBottomSheet(
      String name, double lat, double lng, String address, String placeId ,num distance) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Address: $address",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CommonWidget.getTextWidget500(
                      "${((distance ?? 0.0) / 1609.34).toStringAsFixed(2)} miles",color: Colors.grey[500]!
                  )
                ],
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                //onPressed: () => openGoogleMapsNavigation(lat, lng),
                onPressed: () => getServices(context, placeId, lat, lng),
                // Open Google Maps
                child: const Text("Open in Google Maps"),
              ),
            ],
          ),
        );
      },
    );
  }

  void openGoogleMapsNavigation(double lat, double lng) async {
    Uri googleUrl = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    } else {
      throw 'Could not open Google Maps.';
    }
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  getServices(BuildContext context, String id, double lat, double lng) async {
    var response = await dataManager!.postPlaceId(context, id);
    var data = CommonBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      openGoogleMapsNavigation(lat, lng);
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      openGoogleMapsNavigation(lat, lng);
    }
  }

  /// Build vendor/service image with proper fallback
  Widget _buildVendorImage(ServicesData vendor, bool isOffline) {
    // Try vendor displayPicture first, then first service coverImage
    String? imageUrl = vendor.displayPicture;
    
    if ((imageUrl == null || imageUrl.isEmpty) && vendor.services.isNotEmpty) {
      imageUrl = vendor.services.first.coverImage;
    }

    return imageUrl != null && imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            color: isOffline ? Colors.grey : null,
            colorBlendMode: isOffline ? BlendMode.saturation : null,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage(isOffline);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          )
        : _buildPlaceholderImage(isOffline);
  }

  /// Build placeholder image when no image is available
  Widget _buildPlaceholderImage(bool isOffline) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isOffline ? Colors.grey[300] : ColorClass.base_color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.store,
        size: 60,
        color: isOffline ? Colors.grey[500] : ColorClass.base_color,
      ),
    );
  }
}
