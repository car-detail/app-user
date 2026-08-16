import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class BookingDataManager {
  SharedPreferences sharedPreferences;

  BookingDataManager(this.sharedPreferences);

  ApiFuntions apiFuntions = ApiFuntions();

  getServiceDetails(BuildContext context, String id) async {
    try {
      // Since both service IDs and vendor IDs are 24-character hex strings,
      // we need to try both endpoints. But let's be smarter about it.
      // Based on the logs, this ID is a vendor ID, so try vendor services first
      
      try {
        var response = await apiFuntions.getdatauser(context, "v1/services/vendor/$id");
        if (response.statusCode == 200) {
          // If data is an empty list, $id is a service ID not a vendor ID — fall back
          try {
            final body = jsonDecode(response.body);
            if (body['data'] is List && (body['data'] as List).isEmpty) {
              return await apiFuntions.getdatauser(context, "${Constant.serviceDetails}$id");
            }
          } catch (_) {}
          return response;
        } else if (response.statusCode == 400) {
          return await apiFuntions.getdatauser(context, "${Constant.serviceDetails}$id");
        } else {
          return await apiFuntions.getdatauser(context, "${Constant.serviceDetails}$id");
        }
      } catch (e) {
        return await apiFuntions.getdatauser(context, "${Constant.serviceDetails}$id");
      }
    } catch (e) {
      // Return a mock response to prevent crashes
      return Response('{"status":"error","message":"API call failed: $e"}', 500);
    }
  }

  postBooking(
      BuildContext context,
      String vendorId,
      List<String> serviceIds,
      String price,
      String date,
      String time,
      String timeZone,
      {String? packageId, String? packageName, int? packagePrice, int? pointsRedeemed}) {
    Map<String, dynamic> bookingData = {
      "vendorId": vendorId,
      "serviceIds": serviceIds,
      "price": price,
      "date": date,
      "timeSlot": time,
      "timeZone": timeZone.isEmpty ? "UTC" : timeZone
    };
    
    if (pointsRedeemed != null && pointsRedeemed > 0) {
      bookingData["pointsRedeemed"] = pointsRedeemed;
    }
    
    // Add package information if a package is selected
    if (packageId != null && packageName != null && packagePrice != null) {
      bookingData["packageId"] = packageId;
      bookingData["packageName"] = packageName;
      bookingData["packagePrice"] = packagePrice;
      // Update the main price to package price if package is selected
      bookingData["price"] = packagePrice.toString();
    }
    
    return apiFuntions.postdatauser(context, Constant.postBooking, bookingData);
  }

  getBookingListFilter(BuildContext context, String filterType) {
    return apiFuntions.getdatauser(context,
        "${Constant.myBooking}?pageNumber=1&bookingStatusFilter=$filterType&count=12");
  }

  putStatusCancel(BuildContext context, String reason,String sId) {
    return apiFuntions.putdatauser(
        context,
        "${Constant.cancelBooking}$sId",
        <String, dynamic>{
          "commentByUser": reason
        });
  }
}
