import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class ExploreListDataManager {

  SharedPreferences sharedPreferences;
  ExploreListDataManager(this.sharedPreferences);
  ApiFuntions apiFuntions = ApiFuntions();
  getAllServices(BuildContext context) {
    return apiFuntions.getdatauser(context, "${Constant.getAllService}pageNumber=1&count=12&lat=${sharedPreferences.getString(Constant.lat)}&long=${sharedPreferences.getString(Constant.long
    )}&maxDistance=30000&sortBy=createdAt");
  }
  postBookmark(BuildContext context, String id) {
    return apiFuntions.postdatauser(context, "${Constant.postBookmark}",
        <String, dynamic>{"serviceId": id});
  }
  postPlaceId(BuildContext context, String id) {
    return apiFuntions.postdatauser(context, "${Constant.postPlaceId}",
        <String, dynamic>{"placeId": id});
  }

  removeBookmark(BuildContext context, String id) {
    return apiFuntions.putdatauser(context, "${Constant.removeBookmark}$id",
        {});
  }

}