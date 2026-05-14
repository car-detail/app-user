import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';
import '../model/mixed_vendor_data.dart';

class HomeDataManager {
  SharedPreferences sharedPreferences;

  HomeDataManager(this.sharedPreferences);

  ApiFuntions apiFuntions = ApiFuntions();

  getcategory(BuildContext context) {
    return apiFuntions.getdatauser(context, Constant.category);
  }

  Future<void> syncLocationToApi(BuildContext context, String locationName, double lat, double lng) async {
    final userId = sharedPreferences.getString(Constant.id);
    if (userId == null || userId.isEmpty) return;
    try {
      await apiFuntions.putdatauser(context, "${Constant.updateUserDetails}$userId", {
        "location": {
          "name": locationName,
          "coordinates": {"lat": lat, "long": lng}
        }
      });
    } catch (_) {}
  }
  postPlaceId(BuildContext context, String id) {
    return apiFuntions.postdatauser(context, Constant.postPlaceId,
        <String, dynamic>{"placeId": id});
  }

  getAllServices(BuildContext context, {int pageNumber = 1, int count = 12}) {
    String? lat = sharedPreferences.getString(Constant.lat);
    String? long = sharedPreferences.getString(Constant.long);
    
    String url = "${Constant.getAllService}pageNumber=$pageNumber&count=$count";
    
    if (lat != null && long != null && lat != "null" && long != "null") {
      url += "&lat=$lat&long=$long&maxDistance=30000";
    }
    
    url += "&sortBy=createdAt";
    
    return apiFuntions.getdatauser(context, url);
  }

  getAllServicesWithLocation(BuildContext context, Map<String, double>? location, {int pageNumber = 1, int count = 12}) {
    String url = "${Constant.getAllService}pageNumber=$pageNumber&count=$count";
    
    if (location != null && location['lat'] != null && location['lng'] != null) {
      url += "&lat=${location['lat']}&long=${location['lng']}&maxDistance=30000&includeGooglePlaces=true";
    } else {
      // Fallback to stored location
      String? lat = sharedPreferences.getString(Constant.lat);
      String? long = sharedPreferences.getString(Constant.long);
      
      if (lat != null && long != null && lat != "null" && long != "null") {
        url += "&lat=$lat&long=$long&maxDistance=30000&includeGooglePlaces=true";
      }
    }
    
    url += "&sortBy=createdAt";
    
    return apiFuntions.getdatauser(context, url);
  }

  getOffer(BuildContext context) {
    const int maxDistanceMeters = 80467;
    final lat = sharedPreferences.getString(Constant.lat);
    final lng = sharedPreferences.getString(Constant.long);
    if (lat == null || lng == null || lat == "null" || lng == "null" || lat == "0.0") {
      // Backend expects lat and long for $geoNear aggregation.
      // Pass a very large max distance (e.g. 40,000 km, approx Earth's circumference)
      // to retrieve all offers when user location is unknown.
      return apiFuntions.getdatauser(context, "${Constant.getOffer}lat=0&long=0&maxDistance=40000000");
    }
    return apiFuntions.getdatauser(context,
        "${Constant.getOffer}lat=$lat&long=$lng&maxDistance=$maxDistanceMeters");
  }

  getNotification(BuildContext context) {
    return apiFuntions.getdatauser(context,
        "${Constant.getNotifications}?limit=100&page=1&userId=${sharedPreferences.getString(Constant.id) ?? ""}");
  }

  /// Get vendors from backend (app vendors + Google Places vendors combined)
  Future<List<MixedVendorData>> getMixedVendors(BuildContext context, {int pageNumber = 1, int count = 12, int? maxDistance}) async {
    try {
      final lat = sharedPreferences.getString(Constant.lat);
      final lng = sharedPreferences.getString(Constant.long);
      final distance = maxDistance ?? 30000;

      String url;
      if (lat != null && lng != null && lat != "null" && lng != "null" && lat != "0.0") {
        url = "${Constant.getAllService}lat=$lat&long=$lng&pageNumber=$pageNumber&count=$count&sortBy=createdAt&includeGooglePlaces=true&maxDistance=$distance";
      } else {
        url = "${Constant.getAllService}pageNumber=$pageNumber&count=$count&sortBy=createdAt&includeGooglePlaces=false";
      }

      final response = await apiFuntions.getdatauser(
        context,
        url,
      );
      
      final responseData = jsonDecode(response.body);
      
      List<MixedVendorData> vendors = [];
      
      if (responseData['status'] == 'success' && responseData['data'] != null) {
        final vendorsData = responseData['data'] as List;
        
        for (var vendor in vendorsData) {
          
          // Check if this is a Google Places vendor (has _id starting with 'ChIJ')
          if (vendor['_id'] != null && vendor['_id'].toString().startsWith('ChIJ')) {
            // Google Places vendor from backend - convert to MixedVendorData
            vendors.add(MixedVendorData.fromBackendGoogleVendor(vendor));
          } else {
            // App vendor - convert to MixedVendorData
            vendors.add(MixedVendorData.fromAppVendor(vendor));
          }
        }
      }
      
      return vendors;
    } catch (e) {
      return [];
    }
  }

  /// Get vendors with specific radius for zoom-based loading
  Future<List<MixedVendorData>> getMixedVendorsWithRadius(
    BuildContext context, 
    double lat, 
    double lng, 
    double radius,
    {int pageNumber = 1, int count = 50}
  ) async {
    try {
      final response = await apiFuntions.getdatauser(
        context,
        "${Constant.getAllService}lat=$lat&long=$lng&pageNumber=$pageNumber&count=$count&sortBy=createdAt&includeGooglePlaces=true&maxDistance=${radius.toInt()}",
      );
      
      final responseData = jsonDecode(response.body);
      
      List<MixedVendorData> vendors = [];
      
      if (responseData['status'] == 'success' && responseData['data'] != null) {
        final vendorsData = responseData['data'] as List;
        
        for (var vendor in vendorsData) {
          // Check if this is a Google Places vendor (has _id starting with 'ChIJ')
          if (vendor['_id'] != null && vendor['_id'].toString().startsWith('ChIJ')) {
            vendors.add(MixedVendorData.fromBackendGoogleVendor(vendor));
          } else {
            vendors.add(MixedVendorData.fromAppVendor(vendor));
          }
        }
      }
      
      return vendors;
    } catch (e) {
      return [];
    }
  }

  /// Get vendors filtered by category
  Future<List<MixedVendorData>> getMixedVendorsByCategory(
    BuildContext context,
    String category,
    {int pageNumber = 1, int count = 50}
  ) async {
    try {
      final lat = sharedPreferences.getString(Constant.lat);
      final lng = sharedPreferences.getString(Constant.long);

      String url;
      if (lat != null && lng != null && lat != "null" && lng != "null" && lat != "0.0") {
        url = "${Constant.getAllService}lat=$lat&long=$lng&pageNumber=$pageNumber&count=$count&sortBy=createdAt&includeGooglePlaces=true&filterBycategory=${Uri.encodeComponent(category)}";
      } else {
        url = "${Constant.getAllService}pageNumber=$pageNumber&count=$count&sortBy=createdAt&filterBycategory=${Uri.encodeComponent(category)}";
      }

      final response = await apiFuntions.getdatauser(
        context,
        url,
      );
      
      final responseData = jsonDecode(response.body);
      
      List<MixedVendorData> vendors = [];
      
      if (responseData['status'] == 'success' && responseData['data'] != null) {
        final vendorsData = responseData['data'] as List;
        
        for (var vendor in vendorsData) {
          // Check if this is a Google Places vendor (has _id starting with 'ChIJ')
          if (vendor['_id'] != null && vendor['_id'].toString().startsWith('ChIJ')) {
            vendors.add(MixedVendorData.fromBackendGoogleVendor(vendor));
          } else {
            vendors.add(MixedVendorData.fromAppVendor(vendor));
          }
        }
      }
      
      return vendors;
    } catch (e) {
      return [];
    }
  }

  /// Get vendors filtered by category with radius
  Future<List<MixedVendorData>> getMixedVendorsByCategoryWithRadius(
    BuildContext context, 
    String category,
    double lat, 
    double lng, 
    double radius,
    {int pageNumber = 1, int count = 50}
  ) async {
    try {
      final response = await apiFuntions.getdatauser(
        context,
        "${Constant.getAllService}lat=$lat&long=$lng&pageNumber=$pageNumber&count=$count&sortBy=createdAt&includeGooglePlaces=true&maxDistance=${radius.toInt()}&filterBycategory=${Uri.encodeComponent(category)}",
      );
      
      final responseData = jsonDecode(response.body);
      
      List<MixedVendorData> vendors = [];
      
      if (responseData['status'] == 'success' && responseData['data'] != null) {
        final vendorsData = responseData['data'] as List;
        
        for (var vendor in vendorsData) {
          // Check if this is a Google Places vendor (has _id starting with 'ChIJ')
          if (vendor['_id'] != null && vendor['_id'].toString().startsWith('ChIJ')) {
            vendors.add(MixedVendorData.fromBackendGoogleVendor(vendor));
          } else {
            vendors.add(MixedVendorData.fromAppVendor(vendor));
          }
        }
      }
      
      return vendors;
    } catch (e) {
      return [];
    }
  }

  /// Search vendors by name using backend search
  Future<List<MixedVendorData>> searchVendors(
    BuildContext context,
    String searchQuery,
    {int pageNumber = 1, int count = 50, int? maxDistance}
  ) async {
    try {
      final lat = sharedPreferences.getString(Constant.lat);
      final lng = sharedPreferences.getString(Constant.long);
      final distance = maxDistance ?? 30000;

      String url;
      if (lat != null && lng != null && lat != "null" && lng != "null" && lat != "0.0") {
        url = "${Constant.getAllService}lat=$lat&long=$lng&pageNumber=$pageNumber&count=$count&sortBy=createdAt&includeGooglePlaces=true&searchByName=${Uri.encodeComponent(searchQuery)}&maxDistance=$distance";
      } else {
        url = "${Constant.getAllService}pageNumber=$pageNumber&count=$count&sortBy=createdAt&searchByName=${Uri.encodeComponent(searchQuery)}";
      }

      final response = await apiFuntions.getdatauser(
        context,
        url,
      );
      
      final responseData = jsonDecode(response.body);
      
      List<MixedVendorData> vendors = [];
      
      if (responseData['status'] == 'success' && responseData['data'] != null) {
        final vendorsData = responseData['data'] as List;
        
        for (var vendor in vendorsData) {
          try {
            // Check if this is a Google Places vendor (has _id starting with 'ChIJ')
            if (vendor['_id'] != null && vendor['_id'].toString().startsWith('ChIJ')) {
              vendors.add(MixedVendorData.fromBackendGoogleVendor(vendor));
            } else {
              vendors.add(MixedVendorData.fromAppVendor(vendor));
            }
          } catch (e) {
          }
        }
      }
      
      return vendors;
    } catch (e) {
      return [];
    }
  }

}
