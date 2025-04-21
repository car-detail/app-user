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
  CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(30.707600, 76.715126),
    zoom: 14.4746,
  );
  ExploreListDataManager? dataManager;
  CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      zoom: 19.151926040649414);
  LatLng _current = LatLng(30.707600, 76.715126);
  Set<Marker> markers = {};
  late SharedPreferences? sharedPreferences;
  BitmapDescriptor? carIcon;

  Future<void> loadCustomMarker() async {
    carIcon = await BitmapDescriptor.asset(
      ImageConfiguration(size: Size(48, 48)),
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
    getServicesNew(context);
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
            markerId: MarkerId("Current Location"),
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
              markerId: MarkerId("Current Location"),
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

  Future<void> _fetchNearbyPetrolPumps() async {
    if (_current == null) return;
    ApiFuntions.showLoaderDialog(context);
    print(
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_current.latitude},${_current.longitude}&radius=10000&type=car_wash&key=AIzaSyBFtrosISezP-8z2NwTWKhD_5pNHoi0wRw");
    String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_current.latitude},${_current.longitude}&radius=10000&type=car_wash&key=AIzaSyBFtrosISezP-8z2NwTWKhD_5pNHoi0wRw";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Navigator.pop(context);
      final data = LocationListModelBean.fromJson(jsonDecode(response.body));
      if (data.status == "OK") {
        print("========================================${response.statusCode}");
        print("========================================${response.body}");
        for (var place in data.results) {
          double lat = place!.geometry!.location!.lat!;
          double lng = place!.geometry!.location!.lng!;
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
      Navigator.pop(context);
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
                  if(place.services.length>0){
                    CommonWidget.navigateToScreen(context,
                        SeviceListScreen(place.services));
                  }else
                  _showBottomSheet(name, lat, lng, place.location?.name ?? "",
                      place.sId ?? "", place.distance??0.0);
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
            margin: EdgeInsets.all(5),
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.all(Radius.circular(25))),
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
                SizedBox(
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
          if (isList)
            Expanded(
                child: Container(
              margin: EdgeInsets.all(15),
              child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: servicesData.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        if (servicesData[index].services.length > 0) {
                          CommonWidget.navigateToScreen(context,
                              SeviceListScreen(servicesData[index].services));
                        } else {
                          _showBottomSheet(
                              servicesData[index].displayName ?? "",
                              servicesData[index].location?.coordinates?.lat ?? 0.0,
                              servicesData[index].location?.coordinates?.long ?? 0.0,
                              servicesData[index].location?.name ?? "",
                              servicesData[index].sId ?? "", servicesData[index].distance??0.0);
                        }
                      },
                      child: Container(
                          margin: EdgeInsets.only(bottom: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CommonWidget.getTextWidget600(
                                  servicesData[index].displayName ?? "", 18,
                                  textAlign: TextAlign.start,
                                  color: ColorClass.base_color),
                              SizedBox(
                                height: 0,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: CommonWidget.getTextWidget500(
                                        servicesData[index].location?.name ??
                                            "",
                                        textAlign: TextAlign.start,
                                        color: ColorClass.base_color),
                                  ),
                                  CommonWidget.getTextWidget500(
                                    "${((servicesData[index].distance ?? 0.0) / 1609.34).toStringAsFixed(2)} miles",color: Colors.grey[500]!
                                  )
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Image.network(
                                servicesData[index].displayPicture ?? "",
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) {
                                  return Image.asset(
                                    CommonWidget.getImagePath("loading.png"),
                                    width: double.infinity,
                                    // Adjust the width as needed
                                    height: 200,
                                    fit: BoxFit.fill,
                                  );
                                },
                              ),
                              SizedBox(
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text("Addesss : $address"),),
                  CommonWidget.getTextWidget500(
                      "${((distance ?? 0.0) / 1609.34).toStringAsFixed(2)} miles",color: Colors.grey[500]!
                  )
                ],
              ),

              SizedBox(height: 16),
              ElevatedButton(
                //onPressed: () => openGoogleMapsNavigation(lat, lng),
                onPressed: () => getServices(context, placeId, lat, lng),
                // Open Google Maps
                child: Text("Open in Google Maps"),
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
}
