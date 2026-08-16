import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_places_autocomplete_widgets/address_autocomplete_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';

class LocationPickerScreen extends StatefulWidget {
  final String? currentLocation;

  const LocationPickerScreen({super.key, this.currentLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _locationController = TextEditingController();
  SharedPreferences? _sharedPreferences;
  bool _isLoading = false;
  double? _selectedLat;
  double? _selectedLng;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    _locationController.text = widget.currentLocation ?? "";
  }

  Future<void> _initSharedPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          CommonWidget.errorShowSnackBarFor(
              context, 'Location services are disabled. Please enable them.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            CommonWidget.errorShowSnackBarFor(
                context, 'Location permissions are denied');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          CommonWidget.errorShowSnackBarFor(
              context, 'Location permissions are permanently denied');
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
          position.latitude, position.longitude);

      String address = placemarks[0].locality ??
          placemarks[0].subAdministrativeArea ??
          placemarks[0].administrativeArea ??
          placemarks[0].name ??
          "Current Location";
      
      // If we have both locality and administrativeArea, format it nicely
      if (placemarks[0].locality != null && placemarks[0].administrativeArea != null) {
        address = "${placemarks[0].locality}, ${placemarks[0].administrativeArea}";
      }

      setState(() {
        _locationController.text = address;
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
        _selectedAddress = address;
        _isLoading = false;
      });

      if (mounted) {
        CommonWidget.successShowSnackBarFor(
            context, 'Location detected successfully!');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CommonWidget.errorShowSnackBarFor(
            context, 'Error getting location: ${e.toString()}');
      }
    }
  }

  Future<void> _saveLocation() async {
    String typedAddress = _locationController.text.trim();
    
    if (typedAddress.isEmpty) {
      CommonWidget.errorShowSnackBarFor(context, 'Please enter or select a location');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double? lat = _selectedLat;
      double? lng = _selectedLng;
      String address = typedAddress;

      // If user didn't select from suggestion but typed something, try to geocode it
      if (lat == null || lng == null || _selectedAddress != typedAddress) {
        try {
          List<geo.Location> locations = await geo.locationFromAddress(typedAddress);
          if (locations.isNotEmpty) {
            lat = locations[0].latitude;
            lng = locations[0].longitude;
            
            // Try to get a cleaner name for the typed address
            try {
              List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(lat, lng);
              if (placemarks.isNotEmpty) {
                address = placemarks[0].locality ?? 
                         placemarks[0].subAdministrativeArea ?? 
                         typedAddress;
              }
            } catch (_) {}
          }
        } catch (e) {
          // If geocoding fails, we can't save because we need coordinates for distance calc
          if (mounted) {
            CommonWidget.errorShowSnackBarFor(context, 'Could not find coordinates for this location. Please try a more specific area or select from the list.');
            setState(() { _isLoading = false; });
            return;
          }
        }
      }

      if (lat == null || lng == null) {
        if (mounted) {
          CommonWidget.errorShowSnackBarFor(context, 'Location coordinates are missing');
          setState(() { _isLoading = false; });
          return;
        }
        return;
      }

      _sharedPreferences?.setString(Constant.location, address);
      _sharedPreferences?.setString(Constant.lat, lat.toString());
      _sharedPreferences?.setString(Constant.long, lng.toString());

      setState(() {
        _isLoading = false;
      });

      if (context.mounted) {
        Navigator.of(context).pop({
          'location': address,
          'lat': lat,
          'lng': lng,
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CommonWidget.errorShowSnackBarFor(context, 'An error occurred while saving location');
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Location',
          style: TextStyle(
            fontFamily: "Pop600",
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF166534), Color(0xFF192028), Color(0xFF00E676)],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF166534),
                  Color(0xFF192028),
                  Color(0xFF00E676),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select your location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: "Pop400",
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search for an address or use your current location',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontFamily: "Pop300",
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Google Places Autocomplete
                  AddressAutocompleteTextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: ColorClass.base_color),
                      hintText: "Search for an address...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ColorClass.base_color, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    mapsApiKey: 'AIzaSyBFtrosISezP-8z2NwTWKhD_5pNHoi0wRw',
                    controller: _locationController,
                    onSuggestionClick: (place) {
                      setState(() {
                        final address = place.formattedAddress ?? place.name ?? '';
                        _locationController.text = address;
                        _selectedLat = place.lat ?? 0.0;
                        _selectedLng = place.lng ?? 0.0;
                        _selectedAddress = address;
                      });
                    },
                    language: 'en-US',
                    types: const [
                      AutoCompleteType.locality,
                      AutoCompleteType.sublocality,
                      AutoCompleteType.neighborhood,
                      AutoCompleteType.postalCode
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Divider with "OR"
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontFamily: "Pop500",
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Use Current Location Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getCurrentLocation,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.my_location, size: 20),
                      label: Text(
                        _isLoading ? 'Getting location...' : 'Use Current Location',
                        style: const TextStyle(
                          fontFamily: "Pop500",
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorClass.base_color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Selected Location Display
                  if (_selectedAddress != null && _selectedAddress!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorClass.base_color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ColorClass.base_color.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: ColorClass.base_color,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected Location',
                                  style: TextStyle(
                                    fontFamily: "Pop500",
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedAddress!,
                                  style: const TextStyle(
                                    fontFamily: "Pop500",
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorClass.base_color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Save Location',
                        style: TextStyle(
                          fontFamily: "Pop600",
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

