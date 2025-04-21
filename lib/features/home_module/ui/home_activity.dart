import 'dart:convert';
import 'dart:ffi';

import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/categories_module/ui/categories_list_activity.dart';
import 'package:car_app/features/home_module/data_manager/home_data_manager.dart';
import 'package:car_app/features/home_module/model/offer_list_model.dart';
import 'package:car_app/features/specialists_module/ui/specialists_activity.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Common/CommonBean.dart';
import '../../categories_module/ui/sevice_list_screen.dart';
import '../../notification_model/ui/notification_activity.dart';
import '../model/category_model_data.dart';
import '../model/services_model_data.dart';

class HomeActivity extends StatefulWidget {
  const HomeActivity({super.key});

  @override
  State<HomeActivity> createState() => _HomeActivityState();
}

class _HomeActivityState extends State<HomeActivity> {
  List<CategoryData> categoryData = [];
  List<ServicesData> servicesData = [];
  List<OfferListModelData> offerListData = [];
  HomeDataManager? dataManager;
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
    dataManager = HomeDataManager(sharedPreferences!);
    getCategory(context);
    getServices(context);
    getOffer(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(top: 45, bottom: 10),
            color: ColorClass.base_color,
            child: Row(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 10),
                  height: 10,
                  width: 10,
                ),
                Expanded(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                    CommonWidget.getTextWidget500(
                        sharedPreferences?.getString(Constant.location) ?? "",
                        color: Colors.white),
                  ],
                )),
                GestureDetector(
                  onTap: () {
                    CommonWidget.navigateToScreen(
                        context, NotificationActivity());
                  },
                  child: Container(
                      margin: EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 30,
                      )),
                )
              ],
            ),
          ),
          Expanded(
              child: Container(
            margin: EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonWidget.getTextWidget500("Categories"),
                Container(
                  height: 100,
                  child: ListView.builder(
                      itemCount: categoryData.length,
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            CommonWidget.navigateToScreen(context,
                                CategoriesListActivity(categoryData[index]));
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 30),
                            width: 60,
                            height: 70,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.network(
                                  categoryData[index].logoImage ?? "",
                                  height: 50,
                                  width: 50,
                                  color: ColorClass.base_color,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/car_image.png',
                                      fit: BoxFit.cover,
                                      height: 70,
                                      width: 70,
                                    );
                                  },
                                ),
                                CommonWidget.getTextWidget300(
                                    categoryData[index].categoryTitle ?? "", 14,
                                    color: ColorClass.base_color),
                              ],
                            ),
                          ),
                        );
                      }),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CommonWidget.getTextWidget500("Specialists"),
                    CommonWidget.getTextWidget300("See All", 14,
                        color: ColorClass.base_color)
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  height: 165,
                  child: ListView.builder(
                      itemCount: servicesData.length,
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {if (servicesData[index].services.length > 0) {
                            CommonWidget.navigateToScreen(context,
                                SeviceListScreen(servicesData[index].services));
                          } else {
                            _showBottomSheet(
                                servicesData[index].displayName ?? "",
                                servicesData[index].location?.coordinates?.lat ?? 0.0,
                                servicesData[index].location?.coordinates?.long ?? 0.0,
                                servicesData[index].location?.name ?? "",
                                servicesData[index].sId ?? "", servicesData[index].distance??0.0);
                          }
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 30),
                            width: 110,
                            height: 140,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                  child: Image.network(
                                    servicesData[index].displayPicture ?? "",
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.fill,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/car_image.png',
                                        fit: BoxFit.cover,
                                        height: 100,
                                        width: 100,
                                      );
                                    },
                                  ),
                                ),
                                // CommonWidget.getTextWidget500(
                                //     servicesData[index].serviceTitle ?? "", size: 12,
                                //     color: ColorClass.base_color),
                                // if (servicesData[index].totalReviews != 0 &&
                                //     servicesData[index].totalReviews != null)
                                //   Row(
                                //     mainAxisAlignment: MainAxisAlignment.center,
                                //     children: [
                                //       Image.asset(
                                //         CommonWidget.getImagePath("stars1.png"),
                                //         height: 15,
                                //         width: 15,
                                //       ),
                                //       CommonWidget.getTextWidget300(
                                //           " ${servicesData[index].averageRating.toString() ?? ""} (${servicesData[index].totalReviews.toString() ?? ""} views)",
                                //           10)
                                //     ],
                                //   ),
                              ],
                            ),
                          ),
                        );
                      }),
                ),
                if (offerListData.length > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CommonWidget.getTextWidget500("Offers"),
                      /*CommonWidget.getTextWidget300("See All", 14,
                        color: ColorClass.base_color)*/
                    ],
                  ),
                if (offerListData.length > 0)
                  Container(
                    height: 150,
                    child: ListView.builder(
                        itemCount: offerListData.length,
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              CommonWidget.navigateToScreen(
                                  context,
                                  SpecialistsActivity(
                                      offerListData[index].service ?? ""));
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: 10),
                              width: 280,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(20)),
                                      child: Image.network(
                                        offerListData[index].image ?? "",
                                        height: 150,
                                        fit: BoxFit.fill,
                                        width: 270,
                                      )),
                                  Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Container(
                                          margin:
                                              EdgeInsets.fromLTRB(0, 0, 0, 0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                color: Colors.black
                                                    .withOpacity(0.5),
                                                margin:
                                                    EdgeInsets.only(right: 10),
                                                padding: EdgeInsets.only(
                                                  left: 5,
                                                  right: 5,
                                                ),
                                                child: CommonWidget
                                                    .getTextWidget500(
                                                        "Get ${offerListData[index].discount}% off",
                                                        size: 14,
                                                        color: Colors.white,
                                                        textAlign:
                                                            TextAlign.start),
                                              ),
                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.5),
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      bottomRight:
                                                          Radius.circular(15),
                                                      bottomLeft:
                                                          Radius.circular(15),
                                                    )),
                                                margin: const EdgeInsets.only(
                                                    right: 10),
                                                padding: const EdgeInsets.only(
                                                    right: 5,
                                                    left: 5,
                                                    bottom: 5),
                                                child: Text(
                                                  maxLines: 2,
                                                  offerListData[index]
                                                          .description ??
                                                      "",
                                                  style: const TextStyle(
                                                    fontFamily: "Pop500",
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.start,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ))),
                                ],
                              ),
                            ),
                          );
                        }),
                  ),
              ],
            ),
          ))
        ],
      ),
    );
  }

  void _showBottomSheet(
      String name, double lat, double lng, String address, String placeId ,num distance) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text("Addesss : $address"),),
                  CommonWidget.getTextWidget500(
                      "${((distance ?? 0.0) / 1609.34).toStringAsFixed(2)} miles",color: Colors.grey[500]!
                  )
                ],
              ),

              SizedBox(height: 16),
              ElevatedButton(
                //onPressed: () => openGoogleMapsNavigation(lat, lng),
                onPressed: () => getServicesNew(context, placeId, lat, lng),
                // Open Google Maps
                child: Text("Open in Google Maps"),
              ),
            ],
          ),
        );
      },
    );
  }
  getServicesNew(BuildContext context, String id, double lat, double lng) async {
    var response = await dataManager!.postPlaceId(context, id);
    var data = CommonBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      openGoogleMapsNavigation(lat, lng);
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
      openGoogleMapsNavigation(lat, lng);
    }
  }
  void openGoogleMapsNavigation(double lat, double lng) async {
    Uri googleUrl = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    } else {
      throw 'Could not open Google Maps.';
    }
  }

  getCategory(BuildContext context) async {
    var response = await dataManager!.getcategory(context);
    var data = CategoryModelData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        categoryData.clear();
        categoryData.addAll(data.data!);
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
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

  getOffer(BuildContext context) async {
    var response = await dataManager!.getOffer(context);
    var data = OfferListModelBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      setState(() {
        offerListData.clear();
        offerListData.addAll(data.data!);
      });
      //CommonWidget.successShowSnackBarFor(context, data.message ?? "");
    } else {
      //CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }
}
