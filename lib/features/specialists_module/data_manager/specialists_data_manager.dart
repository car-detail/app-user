import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class SpecialistsDataManager{
  SharedPreferences sharedPreferences;
  SpecialistsDataManager(this.sharedPreferences);
  ApiFuntions apiFuntions = ApiFuntions();

  getServiceDetails(BuildContext context, String id) async {
    try {
      // Validate ID before making API call
      if (id.isEmpty || id.trim().isEmpty) {
        return Response('{"status":"error","message":"Invalid vendor ID"}', 400);
      }
      
      // Check if this is a Google Places ID (starts with "ChIJ")
      // Google Places IDs cannot be used with MongoDB ObjectId queries
      if (id.startsWith('ChIJ')) {
        return Response('{"status":"error","message":"Google Places vendors cannot be loaded as app vendors"}', 400);
      }
      
      // Since both service IDs and vendor IDs are 24-character hex strings,
      // we need to try both endpoints. But let's be smarter about it.
      // Based on the logs, this ID is a vendor ID, so try vendor services first
      
      // Don't show loader dialog - we have our own loading state in the UI
      // Pass cycle: false to prevent blocking loader dialog
      try {
        var response = await apiFuntions.getdatauser(context, "v1/services/vendor/$id", cycle: false);
        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode == 400) {
          // If vendor services returns 400, try service-details
          return await apiFuntions.getdatauser(context, "${Constant.serviceDetails}$id", cycle: false);
        } else {
          // For other errors, try service-details as fallback
          return await apiFuntions.getdatauser(context, "${Constant.serviceDetails}$id", cycle: false);
        }
      } catch (e) {
        // If vendor services fails, try service-details
        return await apiFuntions.getdatauser(context, "${Constant.serviceDetails}$id", cycle: false);
      }
    } catch (e) {
      // Return a mock response to prevent crashes
      return Response('{"status":"error","message":"API call failed: $e"}', 500);
    }
  }

  Future<Response> getVendorPackages(BuildContext context, String vendorId) async {
    try {
      return await apiFuntions.getdatauser(
        context,
        "${Constant.getVendorPackages}$vendorId",
      );
    } catch (e) {
      return Response('{"status":"error","message":"API call failed: $e"}', 500);
    }
  }
}