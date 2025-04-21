import 'dart:convert';

import 'package:car_app/Common/Color.dart';
import 'package:car_app/features/home_module/model/category_model_data.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Common/CommonWidget.dart';
import '../../bookmark_model/ui/bookmark_activity.dart';
import '../../categories_module/model/services_post_bean.dart';
import '../../home_module/model/services_model_data.dart';
import '../../specialists_module/ui/specialists_activity.dart';
import '../data_manager/explore_list_data_manager.dart';

class ExploreListActivity extends StatefulWidget {
  ExploreListActivity({super.key});

  @override
  State<ExploreListActivity> createState() => _CategoriesListActivityState();
}

class _CategoriesListActivityState extends State<ExploreListActivity> {
  List<ServicesData> servicesData = [];
  ExploreListDataManager? dataManager;
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
    dataManager = ExploreListDataManager(sharedPreferences!);
    getServices(context);
  }
  getServices(BuildContext context) async {
    var response = await dataManager!.getAllServices(context);
    var data = ServicesModelData.fromJson(jsonDecode(response.body));
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
                        onTap: (){
                          //Navigator.pop(context);
                        },
                        child: Container(
                          height: 40,
                          width: 40,
                        )
                      ),
                      Expanded(child: CommonWidget.getTextWidget500("Explore",color: Colors.white,size: 18)),
                      InkWell(
                        onTap: () {
                          CommonWidget.navigateToScreen(
                              context, BookmarkActivity());
                        },
                        child: Image.asset(
                          CommonWidget.getImagePath("bookmark.png"),
                          height: 40,
                          width: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Container(
            margin: EdgeInsets.all(15),
            child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: servicesData.length,
                itemBuilder: (context, index){
            return GestureDetector(
              onTap: (){
                CommonWidget.navigateToScreen(context, SpecialistsActivity(servicesData[index].sId??''));
              },
              child: Container(
                  margin: EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                     /* ClipOval(
                          child: Image.network(
                            servicesData[index].coverImage ?? "",
                            height: 70,
                            width: 70,
                            fit: BoxFit.fill,
                            errorBuilder: (
                                BuildContext context,
                                Object error,
                                StackTrace? stackTrace,
                                ) {
                              return Image.asset(
                                CommonWidget.getImagePath("loading.png"),
                                width: 70,
                                // Adjust the width as needed
                                height: 70,
                              );
                            },
                          )),*/
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonWidget.getTextWidget500(
                                servicesData[index].displayName ?? "",
                                textAlign: TextAlign.start,
                                color: ColorClass.base_color),
                            /*CommonWidget.getTextWidget300(
                                "${servicesData[index].categoryName ?? ""} Service",
                                14,
                                textAlign: TextAlign.start),*/
                            /*if (servicesData[index].totalReviews != 0 &&
                                servicesData[index].totalReviews != null)
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    CommonWidget.getImagePath(
                                        "stars1.png"),
                                    height: 15,
                                    width: 15,
                                  ),
                                  CommonWidget.getTextWidget300(
                                      " ${servicesData[index].averageRating.toString() ?? ""} (${servicesData[index].totalReviews.toString() ?? ""} views)",
                                      10),
                                ],
                              ),*/
                            SizedBox(height: 5,),
                            // if (servicesData[index].offers.length>0)
                            //   Container(
                            //     child: CommonWidget.getButtonWidget(
                            //       "Offered Applied",
                            //       Colors.orange[300]!,
                            //       Colors.orange[300]!,
                            //       height: 30,
                            //       size: 12,
                            //     ),
                            //     width: 125,
                            //   )
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      // InkWell(
                      //   onTap: () {
                      //     if (servicesData[index].isBookmarkAdded ==
                      //         true) {
                      //       removeBookmark(context,
                      //           servicesData[index].sId.toString());
                      //     } else {
                      //       postBookmark(context,
                      //           servicesData[index].sId.toString());
                      //     }
                      //   },
                      //   child: Container(
                      //     padding: EdgeInsets.all(5),
                      //     child: Icon(
                      //       servicesData[index].isBookmarkAdded == true
                      //           ? Icons.bookmarks
                      //           : Icons.bookmarks_outlined,
                      //       size: 20,
                      //       color: ColorClass.base_color,
                      //     ),
                      //   ),
                      // ),
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
