import 'package:car_app/Common/Constants.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';

class NotificationDataManager {
  SharedPreferences sharedPreferences;

  NotificationDataManager(this.sharedPreferences);

  ApiFuntions apiFuntions = ApiFuntions();

  getNotifications(BuildContext context, {int page = 1, int limit = 30, String? status, String sort = 'createdAt:desc'}) async {
    // Get user ID from shared preferences
    String? userId = sharedPreferences.getString(Constant.id);
    print('NotificationDataManager - User ID: $userId');
    print('NotificationDataManager - All keys: ${sharedPreferences.getKeys()}');
    
    if (userId == null || userId.isEmpty) {
      throw Exception('User ID not found. Please login again.');
    }
    
    String url = "${Constant.getNotifications}?userId=$userId&page=$page&limit=$limit&sort=$sort";
    print('NotificationDataManager - API URL: $url');
    
    if (status != null && status.isNotEmpty) {
      url += "&status=$status";
    }
    
    return apiFuntions.getdatauser(context, url);
  }

  getNotificationsByStatus(BuildContext context, String status) async {
    return getNotifications(context, status: status);
  }

  getRecentNotifications(BuildContext context, {int limit = 10}) async {
    return getNotifications(context, limit: limit);
  }
}
