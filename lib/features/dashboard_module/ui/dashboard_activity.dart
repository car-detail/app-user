import 'package:car_app/features/booking_model/ui/booking_list_activity.dart';
import 'package:car_app/features/home_module/ui/home_activity.dart';
import 'package:car_app/features/log_in/ui/edit_user_details_activity.dart';
import 'package:car_app/features/log_in/ui/profile_activity.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';

import '../../../Common/Color.dart';
import '../../explore_module/ui/explore_activity.dart';

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
    const HomeActivity(),
    const ExploreActivity(),
    const BookingListActivity(),
    const ProfileActivity()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pageNo[selectedpage],
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            index: 0,
            isSelected: selectedpage == 0,
          ),
          _buildNavItem(
            icon: Icons.explore_rounded,
            label: 'Explore',
            index: 1,
            isSelected: selectedpage == 1,
          ),
          _buildNavItem(
            icon: Icons.book_online_rounded,
            label: 'Booking',
            index: 2,
            isSelected: selectedpage == 2,
          ),
          _buildNavItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            index: 3,
            isSelected: selectedpage == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => selectedpage = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? ColorClass.base_color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? ColorClass.base_color : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: ColorClass.base_color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : ColorClass.dark_gray_base,
                size: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? ColorClass.base_color : ColorClass.dark_gray_base,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
