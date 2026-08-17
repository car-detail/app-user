import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../log_in/ui/new_login_activity.dart';

import '../../../Common/Color.dart';
import '../../../Common/Constant.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/ContainerDecoration.dart';
import '../../rating_model/ui/rating_review_screen.dart';
import '../../specialists_module/ui/specialists_activity.dart';
import '../data_model/booking_data_manager.dart';
import '../model/booking_list_bean.dart';
import '../model/complete_model_bean.dart';
import '../../../design_system/components/car_loader.dart';
import 'ride_share_card_activity.dart';

class BookingListActivity extends StatefulWidget {
  const BookingListActivity({super.key});

  static final GlobalKey<BookingListActivityState> bookingListKey = GlobalKey<BookingListActivityState>();
  static String? targetBookingId;
  static String? targetFilterType;

  @override
  State<BookingListActivity> createState() => BookingListActivityState();
}

class BookingListActivityState extends State<BookingListActivity> {
  BookingDataManager? dataManager;
  SharedPreferences? sharedPreferences;
  List<Records> records = [];
  var filterType = "Pending";
  TextEditingController reasone = TextEditingController();
  bool isLoading = true;
  
  void handleDeepLink(String bookingId, String filterType) {
    if (mounted) {
      setState(() {
        this.filterType = filterType;
      });
      getBookingListFilter(context);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = BookingDataManager(sharedPreferences!);
    
    final String userId = sharedPreferences!.getString(Constant.id) ?? "";
    if (userId.isEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }
    
    DateTime dateTime = DateTime.now();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    //getBookingList(context);
    if (BookingListActivity.targetBookingId != null && BookingListActivity.targetFilterType != null) {
      filterType = BookingListActivity.targetFilterType!;
    }
    if (!mounted) return;
    if (mounted && context.mounted) {
      getBookingListFilter(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = sharedPreferences?.getString(Constant.id) ?? "";
    final bool isGuest = userId.isEmpty;
    
    if (isGuest && !isLoading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          body: Column(
            children: [
              // Modern Header
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D1116), Color(0xFF192028), Color(0xFF2A3542)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    CommonWidget.buildGreenHeaderBackButton(context),
                    const SizedBox(width: 16),
                    const Text(
                      "Bookings",
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: "Pop600",
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ColorClass.base_color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_month_outlined,
                            size: 80,
                            color: ColorClass.base_color,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Sign in to view your bookings",
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: "Pop700",
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Log in or register to schedule services, view upcoming bookings, and keep track of your order history.",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Pop400",
                            color: Colors.grey[500],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF192028), Color(0xFF2A3542)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF192028).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NewLoginActivity(returnToPrevious: true),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  // Refresh state if needed
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Log In / Register",
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: "Pop600",
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
        children: [
          // Modern Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1116), Color(0xFF192028), Color(0xFF2A3542)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF192028).withOpacity(0.4),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                CommonWidget.buildGreenHeaderBackButton(context),
                const SizedBox(width: 16),
                const Text(
                  "Bookings",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: "Pop600",
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Filter Tabs - Simple design
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterTab("Completed", filterType == "Completed"),
                ),
                Expanded(
                  child: _buildFilterTab("Pending", filterType == "Pending"),
                ),
                Expanded(
                  child: _buildFilterTab("Cancelled", filterType == "Cancelled"),
                ),
              ],
            ),
          ),
          
          // Bookings List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                BookingListActivity.targetBookingId = null;
                if (mounted && context.mounted) {
                  await getBookingListFilter(context);
                }
              },
            child: isLoading
                ? const Center(child: CarLoader())
                : records.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          var data = records[index];
                          return _buildBookingCard(data);
                        },
                      ),
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        BookingListActivity.targetBookingId = null;
        if (mounted && context.mounted) {
          setState(() {
            filterType = title;
            getBookingListFilter(context);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF192028) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Records data) {
    final bool isHighlighted = BookingListActivity.targetBookingId == data.sId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? const Color(0xFF192028) : const Color(0xFFE0E0E0),
          width: isHighlighted ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted ? const Color(0xFF192028).withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: isHighlighted ? 12 : 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with vendor info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Vendor Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  child: data.vendorDisplayPicture != null && data.vendorDisplayPicture!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            data.vendorDisplayPicture!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          ),
                        )
                      : _buildDefaultAvatar(),
                ),
                const SizedBox(width: 10),
                // Vendor details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.vendorDisplayName ?? "Vendor",
                        style: const TextStyle(
                          fontSize: 15,
                          fontFamily: "Pop600",
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(data.orderStatus ?? "pending"),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.orderStatus ?? "Pending",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isHighlighted) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF192028).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF192028).withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_active, color: Color(0xFF192028), size: 8),
                            SizedBox(width: 4),
                            Text(
                              "Selected",
                              style: TextStyle(
                                color: Color(0xFF192028),
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Booking details
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                // Selected Service or Package Section (show whichever is available)
                if (data.packageName != null && data.packageName!.isNotEmpty)
                  // Show Package if available
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ColorClass.base_color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.inventory_2_rounded,
                            color: ColorClass.base_color,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Selected Package",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontFamily: "Pop400",
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                data.packageName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: "Pop600",
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Show Service if package not available
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ColorClass.base_color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.local_car_wash_rounded,
                            color: ColorClass.base_color,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Selected Service",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontFamily: "Pop400",
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                data.serviceTitle ?? data.serviceCategory ?? "Service",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: "Pop600",
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                _buildDetailRow(Icons.access_time, "Time Slot", CommonWidget.formatTimeSlot(data.timeSlot ?? "")),
                const SizedBox(height: 6),
                _buildDetailRow(Icons.calendar_today, "Date", DateFormat(Constant.dateFormatDigits).format(DateTime.parse(data.date ?? ""))),
                const SizedBox(height: 6),
                if (data.price != null && data.price! > 0)
                  _buildDetailRow(Icons.attach_money, "Price", "\$${data.price}"),
                
                // Action buttons
                if (data.orderStatus == "Pending") ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final raw = data.serviceMobile?.trim();
                            if (raw == null || raw.isEmpty) {
                              if (mounted) CommonWidget.errorShowSnackBarFor(context, 'Phone number not available');
                              return;
                            }
                            final phone = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                            if (phone.isEmpty) {
                              if (mounted) CommonWidget.errorShowSnackBarFor(context, 'Phone number not available');
                              return;
                            }
                            try {
                              final Uri telUri = Uri.parse('tel:$phone');
                              if (await canLaunchUrl(telUri)) {
                                await launchUrl(telUri, mode: LaunchMode.externalApplication);
                              } else {
                                if (mounted) CommonWidget.errorShowSnackBarFor(context, 'Cannot open phone dialer');
                              }
                            } catch (e) {
                              if (mounted) CommonWidget.errorShowSnackBarFor(context, 'Could not start call');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorClass.base_color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.call, size: 16),
                              SizedBox(width: 4),
                              Text("Call", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => showDetailPopUp(context, data),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close, size: 16),
                              SizedBox(width: 4),
                              Text("Cancel", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Add Review + Share buttons for completed bookings
                if (data.orderStatus == "Completed") ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navigate to rating screen
                            // CommonWidget.navigateToScreen(context, RatingReviewScreen(data.sId.toString()));
                          },
                          icon: const Icon(Icons.star, size: 16),
                          label: const Text("Add Review", style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            CommonWidget.navigateToScreen(context, RideShareCardActivity(data));
                          },
                          icon: const Icon(Icons.ios_share_rounded, size: 16),
                          label: const Text("Share", style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorClass.base_color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Cancellation details
                if (data.orderStatus == "Cancelled") ...[
                  const SizedBox(height: 6),
                  if (data.cancelledBy != null && data.cancelledBy!.isNotEmpty) ...[
                    _buildDetailRow(Icons.person_off, "Cancelled By", data.cancelledBy!),
                    const SizedBox(height: 4),
                  ],
                  if (data.commentByUser != null && data.commentByUser!.isNotEmpty) ...[
                    _buildDetailRow(Icons.comment, "User Remark", data.commentByUser!),
                    const SizedBox(height: 4),
                  ],
                  if (data.commentByVendor != null && data.commentByVendor!.isNotEmpty)
                    _buildDetailRow(Icons.comment, "Vendor Remark", data.commentByVendor!),
                ],

                // View Vendor button — always visible
                if (data.vendorId != null && data.vendorId!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        CommonWidget.navigateToScreen(
                          context,
                          SpecialistsActivity(data.vendorId!),
                        );
                      },
                      icon: Icon(Icons.storefront_rounded,
                          size: 16, color: ColorClass.base_color),
                      label: Text(
                        "View Vendor",
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: "Pop600",
                          color: ColorClass.base_color,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorClass.base_color,
                        side: BorderSide(
                            color: ColorClass.base_color, width: 1.2),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 12,
            fontFamily: "Pop500",
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: "Pop400",
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.business,
      size: 20,
      color: Colors.grey[600],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No Bookings Found",
            style: TextStyle(
              fontSize: 20,
              fontFamily: "Pop600",
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No $filterType bookings available",
            style: TextStyle(
              fontSize: 14,
              fontFamily: "Pop400",
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return ColorClass.base_color;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  getBookingListFilter(BuildContext context) async {
    if (!mounted || !context.mounted) return;
    
    final String userId = sharedPreferences?.getString(Constant.id) ?? "";
    if (userId.isEmpty) {
      setState(() {
        isLoading = false;
        records.clear();
      });
      return;
    }
    
    setState(() {
      isLoading = true;
    });
    
    try {
      var response = await dataManager!.getBookingListFilter(context, filterType);
      
      if (!mounted || !context.mounted) return;
      
      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        setState(() {
          isLoading = false;
        });
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        if (mounted) {
          setState(() {
            records.clear();
          });
        }
        return;
      }
      
      // Check response status code
      if (response.statusCode != 200) {
        setState(() {
          isLoading = false;
        });
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to load bookings. Please check your connection and try again.");
        }
        if (mounted) {
          setState(() {
            records.clear();
          });
        }
        return;
      }
      
      try {
        var data = BookingListBean.fromJson(jsonDecode(response.body));
        if (data.status == "success") {
          if (mounted) {
            setState(() {
              isLoading = false;
              records.clear();
              List<Records> fetchedRecords = data.data!.records!;
              // Sort records by date and timeSlot (descending - most recent first)
              fetchedRecords.sort((a, b) {
                int dateCompare = (b.date ?? "").compareTo(a.date ?? "");
                if (dateCompare != 0) return dateCompare;
                return (b.timeSlot ?? "").compareTo(a.timeSlot ?? "");
              });
              
              // If targetBookingId is set, find and put it at the top of the list
              if (BookingListActivity.targetBookingId != null) {
                int targetIndex = fetchedRecords.indexWhere((r) => r.sId == BookingListActivity.targetBookingId);
                if (targetIndex != -1) {
                  var targetRecord = fetchedRecords.removeAt(targetIndex);
                  fetchedRecords.insert(0, targetRecord);
                }
              }
              
              records.addAll(fetchedRecords);
            });
          }
        } else {
          if (mounted) {
            setState(() {
              isLoading = false;
              records.clear();
            });
          }
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to load bookings. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted) {
          setState(() {
            isLoading = false;
            records.clear();
          });
        }
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error parsing bookings data. Please try again.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          records.clear();
        });
      }
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error loading bookings. Please check your connection and try again.");
      }
    }
  }

  putStatusCancel(BuildContext context, Records datas) async {
    if (!mounted || !context.mounted) return;
    
    try {
      var response = await dataManager!
          .putStatusCancel(context, reasone.text, datas.sId.toString());
      
      if (!mounted || !context.mounted) return;
      
      // Check response status code
      if (response.statusCode != 200) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Unable to cancel booking. Please try again.");
        }
        return;
      }
      
      try {
        var data = CompletedModelBean.fromJson(jsonDecode(response.body));
        if (data.status == "success") {
          reasone.text = "";
          if (mounted && context.mounted) {
            CommonWidget.successShowSnackBarFor(context, data.message ?? "Booking cancelled successfully!");
          }
          if (mounted && context.mounted) {
            getBookingListFilter(context);
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to cancel booking. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error processing request. Please try again.");
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error cancelling booking. Please check your connection and try again.");
      }
    }
  }

  showDetailPopUp(
    BuildContext context,
    Records data,
  ) {
    AlertDialog alert = AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      content: SizedBox(
          height: 330,
          child: Stack(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: GestureDetector(
                  onTap: () {
                    if (mounted && context.mounted) {
                      CommonWidget.safePop(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.only(top: 10, right: 10),
                    child: const Image(
                      image: AssetImage("assets/images/cross.png"),
                      height: 25,
                      width: 25,
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 25, right: 25),
                      width: double.infinity,
                      child: Text(
                        "Reason For Cancel", // ?? "",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: ColorClass.base_color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: const Divider(
                          height: 3,
                          color: Color(0xffdedede),
                        )),
                    Container(
                        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: Column(
                          children: [
                            CommonWidget.getTextWidgetPopReg(
                                "You will not be able to undo this process once continue! Are you want to cancel this booking request?",
                                textsize: 12),
                            Container(
                              margin: const EdgeInsets.only(top: 10, bottom: 10),
                              height: 120,
                              child: TextField(
                                controller: reasone,
                                maxLines: 5,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontFamily: "Krub500",
                                    fontSize: 16),
                                decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        borderSide: BorderSide(
                                            color: ColorClass.light_browne,
                                            width: 1,
                                            style: BorderStyle.solid)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        borderSide: BorderSide(
                                            color: ColorClass.light_browne,
                                            width: 1,
                                            style: BorderStyle.solid)),
                                    contentPadding:
                                        const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                    filled: true,
                                    fillColor: ColorClass.base_light_color,
                                    hintText: "Enter Reason....",
                                    hintStyle: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500),
                                    border: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        borderSide: BorderSide(
                                            color: ColorClass.light_browne))),
                                //controller: userid,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: GestureDetector(
                                  onTap: () {
                                    CommonWidget.safePop(context);
                                  },
                                  child: Container(
                                      margin: const EdgeInsets.only(right: 5),
                                      child: CommonWidget.getButtonWidget(
                                          "No",
                                          ColorClass.base_color!,
                                          ColorClass.base_color!)),
                                )),
                                Expanded(
                                    child: GestureDetector(
                                  onTap: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    //FocusManager.instance.primaryFocus?.unfocus();
                                    CommonWidget.safePop(context);
                                    putStatusCancel(context, data);
                                  },
                                  child: Container(
                                      margin: const EdgeInsets.only(left: 5),
                                      child: CommonWidget.getButtonWidget("Yes",
                                          Colors.red[400]!, Colors.red[400]!)),
                                ))
                              ],
                            )
                          ],
                        )),
                  ],
                ),
              ),
            ],
          )),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
