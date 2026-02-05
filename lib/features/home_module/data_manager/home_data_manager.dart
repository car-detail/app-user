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
  postPlaceId(BuildContext context, String id) {
    return apiFuntions.postdatauser(context, Constant.postPlaceId,
        <String, dynamic>{"placeId": id});
  }

  getAllServices(BuildContext context) {
    String? lat = sharedPreferences.getString(Constant.lat);
    String? long = sharedPreferences.getString(Constant.long);
    
    String url = "${Constant.getAllService}pageNumber=1&count=12";
    
    if (lat != null && long != null && lat != "null" && long != "null") {
      url += "&lat=$lat&long=$long&maxDistance=30000";
    }
    
    url += "&sortBy=createdAt";
    
    return apiFuntions.getdatauser(context, url);
  }

  getAllServicesWithLocation(BuildContext context, Map<String, double>? location) {
    String url = "${Constant.getAllService}pageNumber=1&count=12";
    
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
    // 50 miles = 80,467 meters
    const int maxDistanceMeters = 80467;
    return apiFuntions.getdatauser(context,
        "${Constant.getOffer}lat=${sharedPreferences.getString(Constant.lat) ?? "30.7200094"}&long=${sharedPreferences.getString(Constant.long) ?? "76.7080831"}&maxDistance=$maxDistanceMeters");
  }

  getNotification(BuildContext context) {
    return apiFuntions.getdatauser(context,
        "${Constant.getNotifications}?limit=100&page=1&userId=${sharedPreferences.getString(Constant.id) ?? ""}");
  }

  /// Get vendors from backend (app vendors + Google Places vendors combined)
  Future<List<MixedVendorData>> getMixedVendors(BuildContext context) async {
    try {
      // Add includeGooglePlaces parameter to get Google Places vendors
      final lat = sharedPreferences.getString(Constant.lat) ?? "30.7200094";
      final lng = sharedPreferences.getString(Constant.long) ?? "76.7080831";
      
      final response = await apiFuntions.getdatauser(
        context,
        "${Constant.getAllService}lat=$lat&long=$lng&pageNumber=1&count=12&sortBy=createdAt&includeGooglePlaces=true",
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
    double radius
  ) async {
    try {
      final response = await apiFuntions.getdatauser(
        context,
        "${Constant.getAllService}lat=$lat&long=$lng&pageNumber=1&count=50&sortBy=createdAt&includeGooglePlaces=true&maxDistance=${radius.toInt()}",
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
    String category
  ) async {
    try {
      final lat = sharedPreferences.getString(Constant.lat) ?? "30.7200094";
      final lng = sharedPreferences.getString(Constant.long) ?? "76.7080831";
      
      final response = await apiFuntions.getdatauser(
        context,
        "${Constant.getAllService}lat=$lat&long=$lng&pageNumber=1&count=50&sortBy=createdAt&includeGooglePlaces=true&filterBycategory=${Uri.encodeComponent(category)}",
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
    double radius
  ) async {
    try {
      final response = await apiFuntions.getdatauser(
        context,
        "${Constant.getAllService}lat=$lat&long=$lng&pageNumber=1&count=50&sortBy=createdAt&includeGooglePlaces=true&maxDistance=${radius.toInt()}&filterBycategory=${Uri.encodeComponent(category)}",
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
    String searchQuery
  ) async {
    try {
      final lat = sharedPreferences.getString(Constant.lat) ?? "30.7200094";
      final lng = sharedPreferences.getString(Constant.long) ?? "76.7080831";
      
      final response = await apiFuntions.getdatauser(
        context,
        "${Constant.getAllService}lat=$lat&long=$lng&pageNumber=1&count=50&sortBy=createdAt&includeGooglePlaces=true&searchByName=${Uri.encodeComponent(searchQuery)}",
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
