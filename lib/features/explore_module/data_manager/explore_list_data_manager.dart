import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class ExploreListDataManager {

  SharedPreferences sharedPreferences;
  ExploreListDataManager(this.sharedPreferences);
  ApiFuntions apiFuntions = ApiFuntions();
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
  postBookmark(BuildContext context, String id) {
    return apiFuntions.postdatauser(context, Constant.postBookmark,
        <String, dynamic>{"serviceId": id});
  }
  postPlaceId(BuildContext context, String id) {
    return apiFuntions.postdatauser(context, Constant.postPlaceId,
        <String, dynamic>{"placeId": id});
  }

  removeBookmark(BuildContext context, String id) {
    return apiFuntions.putdatauser(context, "${Constant.removeBookmark}$id",
        {});
  }

  getCategories(BuildContext context) {
    return apiFuntions.getdatauser(context, Constant.category);
  }

  getAllVendors(BuildContext context, {String? category, String? searchTerm}) {
    String? lat = sharedPreferences.getString(Constant.lat);
    String? long = sharedPreferences.getString(Constant.long);
    
    String url = "${Constant.getAllVendors}pageNumber=1&count=50&includeGooglePlaces=true";
    
    if (lat != null && long != null && lat != "null" && long != "null") {
      url += "&lat=$lat&long=$long&maxDistance=30000";
    }
    
    if (category != null && category.isNotEmpty && category != 'All') {
      url += "&filterBycategory=${Uri.encodeComponent(category)}";
    }
    
    if (searchTerm != null && searchTerm.isNotEmpty) {
      url += "&searchByName=${Uri.encodeComponent(searchTerm)}";
    }
    
    url += "&sortBy=createdAt";
    
    return apiFuntions.getdatauser(context, url);
  }

}