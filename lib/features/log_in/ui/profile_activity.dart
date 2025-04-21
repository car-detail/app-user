import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Api/ApiFuntion.dart';
import '../../../Common/BaseActivity.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonPopUp.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../../../Common/ContainerDecoration.dart';
import '../../../Models/image_module_data.dart';
import '../../dashboard_module/ui/dashboard_activity.dart';
import '../data_manager/LoginDataManager.dart';
import '../model/user_detail_model_bean.dart';
import 'LoginActivity.dart';

class ProfileActivity extends StatefulWidget {
  const ProfileActivity({super.key});

  @override
  State<ProfileActivity> createState() => _ProfileActivityState();
}

class _ProfileActivityState extends State<ProfileActivity> {
  var firstNameController = TextEditingController();
  var lastNameController = TextEditingController();
  var emailController = TextEditingController();
  var profileController = TextEditingController();
  List<File> selectedFiles = [];
  String imageURl = "";
  String profileurl = "";

  ApiFuntions apiFuntions = ApiFuntions();
  LoginDataManager? loginDataManager;
  late SharedPreferences? sharedPreferences;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    loginDataManager = LoginDataManager(sharedPreferences!);
    getUser(context);
  }

  getUser(BuildContext context) async {
    var response = await loginDataManager!.getUserDetails(context);
    var data = UserDetailsModelBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      sharedPreferences!
          .setString(Constant.firstName, data.data!.firstName ?? "");
      sharedPreferences!
          .setString(Constant.lastName, data.data!.lastName ?? "");
      sharedPreferences!.setString(Constant.email, data.data!.email ?? "");
      sharedPreferences!.setString(Constant.isEmailVerified,
          data.data!.isEmailVerified.toString() ?? "");
      sharedPreferences!.setString(Constant.mobile, data.data!.mobile ?? "");
      sharedPreferences!
          .setString(Constant.isNewUser, data.data!.isNewUser.toString() ?? "");
      sharedPreferences!
          .setString(Constant.roleName, data.data!.roleName ?? "");
      sharedPreferences!
          .setString(Constant.id, data.data!.sId.toString() ?? "");
      setState(() {
        firstNameController.text = data.data!.firstName ?? "";
        lastNameController.text = data.data!.lastName ?? "";
        emailController.text = data.data!.email ?? "";
        profileurl = data.data!.image ?? "";
      });

      print("Profile image url  $profileurl");

      //CommonWidget.navigateToScreen(context, OTPScreenActivity());
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  postUserDetails(BuildContext context) async {
    var response = await loginDataManager!.postUserDetails(
        firstNameController.text,
        lastNameController.text,
        emailController.text,
        imageURl,
        sharedPreferences!.getString(Constant.id) ?? "",
        context);
    var data = UserDetailsModelBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      sharedPreferences!
          .setString(Constant.firstName, data.data!.firstName ?? "");
      sharedPreferences!
          .setString(Constant.lastName, data.data!.lastName ?? "");
      sharedPreferences!.setString(Constant.email, data.data!.email ?? "");
      sharedPreferences!.setString(Constant.isEmailVerified,
          data.data!.isEmailVerified.toString() ?? "");
      sharedPreferences!.setString(Constant.mobile, data.data!.mobile ?? "");
      sharedPreferences!
          .setString(Constant.isNewUser, data.data!.isNewUser.toString() ?? "");
      sharedPreferences!
          .setString(Constant.roleName, data.data!.roleName ?? "");
      sharedPreferences!
          .setString(Constant.id, data.data!.sId.toString() ?? "");
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      //CommonWidget.navigateToKillAllScreen(context, DashboardActivity());
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  postImage(BuildContext context) async {
    List<File> image = [selectedFiles[0]];
    var response = await loginDataManager!.postImage(image, context);
    var data = ImageModuleData.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      imageURl = data.data?.url ?? "";
      //CommonWidget.successShowSnackBarFor(context, data.message??"");
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/login_image.png'),
              fit: BoxFit.cover)),
      child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration:
                    ContainerDecoration.getboderwithshadowfillcolorblueE7F0FF(
                        borderRadius: 30),
                padding: EdgeInsets.all(8),
                height: 40,
                width: 40,
                margin: EdgeInsets.only(top: 45, right: 15),
                child: InkWell(
                  onTap: () {
                    CommonPopUp.showalertDialog(
                        context,
                        "",
                        "Are you sure - You want to logout?",
                        "No",
                        "Yes",
                        "info",
                        () => Navigator.pop(context), () async {
                      Navigator.pop(context);
                      sharedPreferences!.clear();
                      CommonWidget.navigateToKillAllScreen(
                          context, LoginActivity("Login"));
                      //logout();
                    }, 190,
                        positivetitlecolorButton: ColorClass.red,
                        navtextColorButton: ColorClass.green,
                        isboldtitle: false);
                  },
                  child: Image.asset(
                    CommonWidget.getImagePath("log_out.png"),
                    height: 20,
                    width: 20,
                    color: ColorClass.base_color,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: Platform.isIOS
                      ? EdgeInsets.only(
                          top: 245,
                        )
                      : EdgeInsets.only(
                          top: 165,
                        ),
                  child: Column(
                    children: [
                      //Image(image: AssetImage('assets/images/login_image.png')),
                      Expanded(
                          child: Container(
                        margin: EdgeInsets.only(left: 20, right: 20),
                        child: SingleChildScrollView(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CommonWidget.getTextWidget500("Profile Details",
                                    color: ColorClass.base_color, size: 20),
                                Container(
                                  alignment: Alignment.center,
                                  child: Stack(
                                    children: [
                                      if (profileurl != "" &&
                                          selectedFiles.length == 0)
                                        ClipOval(
                                          child: /*Image.asset(
                                        CommonWidget.getImagePath("chat_profile.png"),
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.fill,
                                      ),*/
                                              Image.network(
                                            profileurl,
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      if (profileurl == "")
                                        ClipOval(
                                          child: Image.asset(
                                            CommonWidget.getImagePath(
                                                "chat_profile.png"),
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                      if (selectedFiles.length > 0)
                                        ClipOval(
                                          child:
                                              CommonWidget.determineImageAsset(
                                                  selectedFiles[0].path ?? ""),
                                        ),
                                      Positioned(
                                        bottom: 5,
                                        right: 0,
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: GestureDetector(
                                              child: Image.asset(
                                                  CommonWidget.getImagePath(
                                                      "add_image_icon.png")),
                                              // Icon color and size
                                              onTap: () async {
                                                var data = await BaseActivity
                                                    .pickmedia(false);
                                                if (data != null) {
                                                  setState(() {
                                                    if (data != null) {
                                                      selectedFiles.clear();
                                                      for (int i = 0;
                                                          i < data.length;
                                                          i++) {
                                                        setState(() {
                                                          selectedFiles
                                                              .add(data[i]);
                                                        });
                                                      }
                                                    }
                                                  });
                                                }
                                                print(selectedFiles.length);
                                                postImage(context);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CommonWidget.getTextFieldWithgrayboder(
                                    "Enter First Name", firstNameController),
                                CommonWidget.getTextFieldWithgrayboder(
                                    "Enter Last Name", lastNameController),
                                CommonWidget.getTextFieldWithgrayboder(
                                    "Enter Email Address", emailController),
                                SizedBox(
                                  height: 20,
                                ),
                                GestureDetector(
                                    onTap: () {
                                      //FocusManager.instance.primaryFocus?.unfocus();
                                      if (BaseActivity.checkEmptyField(
                                          editingController:
                                              firstNameController,
                                          message: "Please Enter First Name.",
                                          context: context)) {
                                        return;
                                      } else if (BaseActivity.checkEmptyField(
                                          editingController: lastNameController,
                                          message: "Please Enter Last Name.",
                                          context: context)) {
                                        return;
                                      } else if (BaseActivity.checkEmptyField(
                                          editingController: emailController,
                                          message:
                                              "Please Enter Email Address.",
                                          context: context)) {
                                        return;
                                      } else if (imageURl == "") {
                                        CommonWidget.successShowSnackBarFor(
                                            context,
                                            "Please Select Profile Image");
                                        return;
                                      } else {
                                        postUserDetails(context);
                                      }
                                    },
                                    child: Container(
                                      child: CommonWidget.getGradinetButton(
                                          "Save",
                                          startcolor: 0xff1CA669,
                                          endcolor: 0xff1CA669,
                                          height: 40),
                                    )),
                              ]),
                        ),
                      ))
                    ],
                  ),
                ),
              )
            ],
          )),
    );
  }
}
