import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../categories_module/data_manager/categories_list_data_manager.dart';
import '../../categories_module/model/services_post_bean.dart';
import '../../home_module/model/services_model_data.dart';
import '../../specialists_module/ui/specialists_activity.dart';
import '../model/bookmark_model_bean.dart';

class BookmarkActivity extends StatefulWidget {
  const BookmarkActivity({super.key});

  @override
  State<BookmarkActivity> createState() => _BookmarkActivityState();
}

class _BookmarkActivityState extends State<BookmarkActivity> {
  List<BookmarkModelData> servicesData = [];

  CategoriesListDataManager? dataManager;
  SharedPreferences? sharedPreferences;
  List<String> offerList = ["car_image.png", "car_image.png"];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = CategoriesListDataManager(sharedPreferences!);
    getServices(context);
  }

  getServices(BuildContext context) async {
    var response = await dataManager!.getBooksMark(
      context,
    );
    var data = BookmarkModelBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        servicesData.clear();
        servicesData.addAll(data.data!);
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: ColorClass.base_color,
            padding: EdgeInsets.only(top: 45, bottom: 10),
            child: Stack(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 10, right: 10),
                  color: ColorClass.base_color,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Image.asset(
                          CommonWidget.getImagePath("backspace.png"),
                          height: 40,
                          width: 40,
                        ),
                      ),
                      Expanded(
                          child: CommonWidget.getTextWidget500("Bookmark",
                              color: Colors.white, size: 18)),
                      Container(
                        height: 40,
                        width: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: Container(
            margin: EdgeInsets.all(15),
            child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: servicesData.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      CommonWidget.navigateToScreen(context,
                          SpecialistsActivity(servicesData[index].serviceId!.sId??""));
                    },
                    child: Container(
                        margin: EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // ClipOval(
                            //     child: Image.network(
                            //   servicesData[index].serviceId?.coverImage ?? "",
                            //   height: 70,
                            //   width: 70,
                            //   fit: BoxFit.fill,
                            //   errorBuilder: (
                            //     BuildContext context,
                            //     Object error,
                            //     StackTrace? stackTrace,
                            //   ) {
                            //     return Image.asset(
                            //       CommonWidget.getImagePath("loading.png"),
                            //       width: 70,
                            //       // Adjust the width as needed
                            //       height: 70,
                            //     );
                            //   },
                            // )),
                            SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CommonWidget.getTextWidget500(
                                      servicesData[index]
                                              .serviceId
                                              ?.displayName ??
                                          "",
                                      textAlign: TextAlign.start,
                                      color: ColorClass.base_color),
                                  // CommonWidget.getTextWidget300(
                                  //     "${servicesData[index].serviceId?.categoryName ?? ""} Service",
                                  //     14,
                                  //     textAlign: TextAlign.start),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            InkWell(
                              onTap: () {
                                removeBookmark(
                                    context,
                                    servicesData[index]
                                        .serviceId!
                                        .sId
                                        .toString());
                              },
                              child: Container(
                                padding: EdgeInsets.all(5),
                                child: Icon(
                                  Icons.bookmarks,
                                  size: 20,
                                  color: ColorClass.base_color,
                                ), /*Icon(
                                      servicesData[index].serviceId?.isBookmarkAdded == true
                                          ? Icons.bookmarks
                                          : Icons.bookmarks_outlined,
                                      size: 20,
                                      color: ColorClass.base_color,
                                    ),*/
                              ),
                            ),
                          ],
                        )),
                  );
                }),
          ))
        ],
      ),
    );
  }

  postBookmark(BuildContext context, String id) async {
    var response = await dataManager!.postBookmark(context, id);
    var data = ServicesPostBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      getServices(context);
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  removeBookmark(BuildContext context, String id) async {
    var response = await dataManager!.removeBookmark(context, id);
    var data = ServicesPostBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      getServices(context);
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
}
