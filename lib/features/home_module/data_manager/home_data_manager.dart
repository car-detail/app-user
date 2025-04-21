import 'package:car_app/Common/Constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class HomeDataManager {
  SharedPreferences sharedPreferences;

  HomeDataManager(this.sharedPreferences);

  ApiFuntions apiFuntions = ApiFuntions();

  getcategory(BuildContext context) {
    return apiFuntions.getdatauser(context, Constant.category);
  }
  postPlaceId(BuildContext context, String id) {
    return apiFuntions.postdatauser(context, "${Constant.postPlaceId}",
        <String, dynamic>{"placeId": id});
  }

  getAllServices(BuildContext context) {
    return apiFuntions.getdatauser(context,
        "${Constant.getAllService}pageNumber=1&count=12&lat=${sharedPreferences.getString(Constant.lat)}&long=${sharedPreferences.getString(Constant.long
    )}&maxDistance=30000&sortBy=createdAt");
  }

  getOffer(BuildContext context) {
    return apiFuntions.getdatauser(context,
        "${Constant.getOffer}lat=${sharedPreferences.getString(Constant.lat) ?? "30.7200094"}&long=${sharedPreferences.getString(Constant.long) ?? "76.7080831"}");
  }
}
