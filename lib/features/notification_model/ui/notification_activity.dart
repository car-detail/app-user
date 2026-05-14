import 'package:car_app/Common/Color.dart';
import 'package:car_app/Common/CommonWidget.dart';
import 'package:car_app/Common/Constant.dart';
import 'package:car_app/features/home_module/model/notification_data_bean.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationActivity extends StatefulWidget {
  List<Notifications> notificationsList;

  NotificationActivity(this.notificationsList, {super.key});

  @override
  State<NotificationActivity> createState() => _NotificationActivityState();
}

class _NotificationActivityState extends State<NotificationActivity> {
  @override
  void initState() {
    super.initState();
    debugPrint('🔔 NotificationActivity initState: ${widget.notificationsList.length} notifications');
    _markAsRead();
  }

  _markAsRead() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constant.lastReadNotificationsAt, DateTime.now().toIso8601String());
    debugPrint('🔔 Notifications marked as read at: ${DateTime.now().toIso8601String()}');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔔 NotificationActivity build: isEmpty=${widget.notificationsList.isEmpty}');
    return Scaffold(
      body: Column(
        children: [
          CommonWidget.gettopbar("Notification", context),
          const SizedBox(
            height: 10,
          ),
          if (widget.notificationsList.isNotEmpty)
            Expanded(
                child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: widget.notificationsList.length,
                    itemBuilder: (context, index) {
                      var data = widget.notificationsList[index];
                      return Container(
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                    color: ColorClass.base_light_color,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(30))),
                                child: Center(
                                    child: Image.asset(
                                  CommonWidget.getImagePath("noti_icon.png"),
                                  height: 25,
                                  width: 25,
                                ))),
                            const SizedBox(
                              width: 5,
                            ),
                            Expanded(
                                child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CommonWidget.getTextWidget500(data.title ?? "",
                                    color: ColorClass.base_color,
                                    textAlign: TextAlign.start,
                                    size: 14),
                                CommonWidget.getTextRich("", data.body ?? "",
                                    textsize: 12)
                              ],
                            )),
                            const SizedBox(
                              width: 5,
                            ),
                            CommonWidget.getTextWidget500(
                                CommonWidget.formatTimeAgo(data.createdAt),
                                size: 10,
                                color: Colors.grey[600]!)
                          ],
                        ),
                      );
                    }))
          else
            Expanded(
                child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No new notifications yet",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontFamily: "Pop500",
                    ),
                  ),
                ],
              ),
            ))
        ],
      ),
    );
  }
}
