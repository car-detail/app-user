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
      // Since both service IDs and vendor IDs are 24-character hex strings,
      // we need to try both endpoints. But let's be smarter about it.
      // Based on the logs, this ID is a vendor ID, so try vendor services first
      print("🔍 Trying vendor services endpoint first for ID: $id");
      
      try {
        var response = await apiFuntions.getdatauser(context, "v1/services/vendor/$id");
        if (response.statusCode == 200) {
          print("✅ Vendor services endpoint succeeded");
          return response;
        } else if (response.statusCode == 400) {
          print("❌ Vendor services returned 400, trying service-details endpoint");
          // If vendor services returns 400, try service-details
          return await apiFuntions.getdatauser(context, "${Constant.serviceDetails}$id");
        } else {
          print("❌ Vendor services returned ${response.statusCode}, trying service-details endpoint");
          // For other errors, try service-details as fallback
          return await apiFuntions.getdatauser(context, "${Constant.serviceDetails}$id");
        }
      } catch (e) {
        print("❌ Vendor services endpoint failed: $e, trying service-details endpoint");
        // If vendor services fails, try service-details
        return await apiFuntions.getdatauser(context, "${Constant.serviceDetails}$id");
      }
    } catch (e) {
      print("❌ Error in getServiceDetails API call: $e");
      // Return a mock response to prevent crashes
      return Response('{"status":"error","message":"API call failed: $e"}', 500);
    }
  }
}