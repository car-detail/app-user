import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class BookingDataManager {
  SharedPreferences sharedPreferences;

  BookingDataManager(this.sharedPreferences);

  ApiFuntions apiFuntions = ApiFuntions();

  getServiceDetails(BuildContext context, String id) {
    return apiFuntions.getdatauser(context, "${Constant.serviceDetails}$id");
  }

  postBooking(BuildContext context, String vendorId, String serviceId,
      String price, String date, String time, {String? packageId, String? packageName, int? packagePrice}) {
    Map<String, dynamic> bookingData = {
      "vendorId": vendorId,
      "serviceId": serviceId,
      "price": price,
      "date": date,
      "timeSlot": time,
      "timeZone": "Asia/Kolkata"
    };
    
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
