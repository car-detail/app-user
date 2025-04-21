import 'package:flutter/material.dart';

import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../home_module/model/services_model_data.dart';
import '../../specialists_module/ui/specialists_activity.dart';

class SeviceListScreen extends StatefulWidget {
  List<Services> services;
  SeviceListScreen(this.services,{super.key});

  @override
  State<SeviceListScreen> createState() => _SeviceListScreenState();
}

class _SeviceListScreenState extends State<SeviceListScreen> {
  List<Services> servicesData = [];
  @override
  void initState() {
    setState(() {
      servicesData  = widget.services;
    });
  super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CommonWidget.gettopbar(
            "Services",
            context,
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
                          CommonWidget.navigateToScreen(
                              context,
                              SpecialistsActivity(
                                  servicesData[index].sId ?? ''));
                      },
                      child: Container(
                          margin: EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ClipOval(
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
                                  )),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CommonWidget.getTextWidget500(
                                        servicesData[index].serviceTitle ?? "",
                                        textAlign: TextAlign.start,
                                        color: ColorClass.base_color),
                                    CommonWidget.getTextWidget300(
                                        "${servicesData[index].categoryName ?? ""} Service",
                                        14,
                                        textAlign: TextAlign.start),
                                    if (servicesData[index].totalReviews != 0 &&
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
                                      ),
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
                            ],
                          )),
                    );
                  }),
            ))
        ],
      ),
    );
  }
}
