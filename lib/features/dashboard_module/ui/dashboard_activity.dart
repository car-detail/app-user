import 'package:car_app/features/booking_model/ui/booking_list_activity.dart';
import 'package:car_app/features/home_module/ui/home_activity.dart';
import 'package:car_app/features/log_in/ui/edit_user_details_activity.dart';
import 'package:car_app/features/log_in/ui/profile_activity.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';

import '../../../Common/Color.dart';
import '../../../Common/ModernDesignSystem.dart';
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
      body: SafeArea(
        child: IndexedStack(
          index: selectedpage,
          children: _pageNo,
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: ModernDesignSystem.shadowLarge,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(ModernDesignSystem.radiusXL),
          topRight: Radius.circular(ModernDesignSystem.radiusXL),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                isSelected: selectedpage == 0,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                icon: Icons.explore_rounded,
                label: 'Explore',
                index: 1,
                isSelected: selectedpage == 1,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                icon: Icons.book_online_rounded,
                label: 'Booking',
                index: 2,
                isSelected: selectedpage == 2,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                index: 3,
                isSelected: selectedpage == 3,
              ),
            ),
          ],
        ),
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
      onTap: () {
        if (mounted) {
          setState(() => selectedpage = index);
        }
      },
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 0,
          maxWidth: double.infinity,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? ColorClass.base_color : Colors.transparent,
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : ColorClass.dark_gray_base,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: TextStyle(
                color: isSelected ? ColorClass.base_color : ColorClass.dark_gray_base,
                fontSize: isSelected ? 10 : 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
                height: 1.1,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
