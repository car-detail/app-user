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
      String price, String date, String time) {
    return apiFuntions
        .postdatauser(context, Constant.postBooking, <String, dynamic>{
      "vendorId": vendorId,
      "serviceId": serviceId,
      "price": price,
      "date": date,
      "timeSlot": time,
      "timeZone": "Asia/Kolkata"
    });
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
