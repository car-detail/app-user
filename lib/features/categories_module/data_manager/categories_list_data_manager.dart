import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/Constant.dart';

class CategoriesListDataManager {
  SharedPreferences sharedPreferences;

  CategoriesListDataManager(this.sharedPreferences);

  ApiFuntions apiFuntions = ApiFuntions();

  getAllServices(BuildContext context, String title) {
    return apiFuntions.getdatauser(context,
        "${Constant.getAllService}pageNumber=1&count=20&sortBy=createdAt&filterBycategory=$title");
  }

  getBooksMark(BuildContext context) {
    return apiFuntions.getdatauser(context,
        "${Constant.getBookmarks}");
  }

  postBookmark(BuildContext context, String id) {
    return apiFuntions.postdatauser(context, "${Constant.postBookmark}",
        <String, dynamic>{"serviceId": id});
  }

  removeBookmark(BuildContext context, String id) {
    return apiFuntions.putdatauser(context, "${Constant.removeBookmark}$id",
        {});
  }
}
