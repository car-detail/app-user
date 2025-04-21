import 'package:car_app/features/booking_model/ui/booking_list_activity.dart';
import 'package:car_app/features/home_module/ui/home_activity.dart';
import 'package:car_app/features/log_in/ui/edit_user_details_activity.dart';
import 'package:car_app/features/log_in/ui/profile_activity.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';

import '../../../Common/Color.dart';
import '../../explore_module/ui/explore_list_activity.dart';
import '../../explore_module/ui/explore_list_map_activity.dart';

class DashboardActivity extends StatefulWidget {
  int currentIndex;
  DashboardActivity({this.currentIndex = 0,super.key});

  @override
  State<DashboardActivity> createState() => _DashboardActivityState();
}

class _DashboardActivityState extends State<DashboardActivity> {
  int selectedpage = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectedpage = widget.currentIndex;
  }
  final List<Widget> _pageNo = [
    HomeActivity(),
 //   ExploreListActivity(),
    ExploreListMapActivity(),
    BookingListActivity(),
    ProfileActivity()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pageNo[selectedpage],
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: ColorClass.base_color,
        color: Colors.white,
        items: const [
          TabItem(icon: Icons.home, title: 'Home'),
          TabItem(icon: Icons.travel_explore, title: 'Explore'),
          TabItem(icon: Icons.book_online, title: 'Booking'),
          //TabItem(icon: Icons.chat, title: 'Chat'),
          TabItem(icon: Icons.supervised_user_circle, title: 'Profile'),
        ],
        initialActiveIndex: selectedpage,
        onTap: (int i) => setState(() {
          selectedpage = i;
        }),
      ),
    );
  }
}
