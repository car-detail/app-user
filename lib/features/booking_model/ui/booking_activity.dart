import 'dart:convert';

import 'package:car_app/Common/BaseActivity.dart';
import 'package:car_app/features/booking_model/model/booking_model_data.dart';
import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../Common/Color.dart';
import '../../../Common/CommonPopUp.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';
import '../data_model/booking_data_manager.dart';
import '../model/booking_post_bean.dart';
import '../../specialists_module/data_manager/specialists_data_manager.dart';

class BookingActivity extends StatefulWidget {
  String servicesData;

  BookingActivity(this.servicesData, {super.key});

  @override
  State<BookingActivity> createState() => _BookingActivityState();
}

class _BookingActivityState extends State<BookingActivity> {
  BookingDataManager? dataManager;
  SharedPreferences? sharedPreferences;
  BookingModelData bookingdata = BookingModelData(detailImages: []);
  List<String> detailImages = [];
  var isPickUp = false;
  var timeController = TextEditingController();
  var dateController = TextEditingController();
  var dateString = "";
  var timeString = "";
  var postTime = "";
  var messageController = TextEditingController();
  String _userTimeZone = 'UTC';
  List<TimeSlots> timeSlot = [];
  bool isBookmarked = false;
  String? selectedPackageId;
  String? selectedPackageName;
  int? selectedPackagePrice;
  List<Map<String, dynamic>> availablePackages = [];
  List<BookingModelData> availableServices = [];
  List<String> selectedServiceIds = [];
  List<String> selectedServiceNames = [];
  String? selectedServiceCategory;
  int totalServicePrice = 0;
  String? selectedServiceDuration;
  String selectionType = "service"; // "service" or "package"

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = BookingDataManager(sharedPreferences!);
    await _loadUserTimeZone();
    getServicesDetails(context);
  }

  Future<void> _loadUserTimeZone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      if (!mounted) return;
      setState(() {
        _userTimeZone = timezone;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userTimeZone = 'UTC';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
        extendBodyBehindAppBar: true,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CommonWidget.buildAppBarBackButton(
          context,
          backgroundColor: Colors.white.withOpacity(0.9),
          iconColor: Colors.black87,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? const Color(0xFF1CB273) : Colors.black87,
                size: 20,
            ),
            onPressed: _toggleBookmark,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with Real Service/Vendor Image - Full Coverage
          SizedBox(
            height: 320,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Service/Vendor Image - Priority: coverImage > vendor displayPicture > default
                (bookingdata.coverImage != null && bookingdata.coverImage!.isNotEmpty)
                      ? Image.network(
                          bookingdata.coverImage!,
                          fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFallbackImage();
                        },
                      )
                    : (bookingdata.vendorId?.displayPicture != null && 
                       bookingdata.vendorId!.displayPicture!.isNotEmpty)
                        ? Image.network(
                            bookingdata.vendorId!.displayPicture!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultCoverImage();
                          },
                        )
                      : _buildDefaultCoverImage(),
                // Gradient overlay for better text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                
                // Service Title and Location Overlay
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Title
                      Text(
                        bookingdata.serviceTitle ?? "Service",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: "Pop600",
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ],
                        ),
                      ),
                      if (bookingdata.location?.name != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                bookingdata.location?.name ?? "",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 14,
                                  fontFamily: "Pop400",
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Simple Content Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                  // Booking Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF166534), Color(0xFF1CB273)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.event_available_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 10),
                                Text(
                                  "Book A Slot",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: "Pop600",
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                          
                          // Selection Type: Service or Package
                            Text(
                            availablePackages.isNotEmpty 
                                ? "Select Service or Package *"
                                : "Select Service *",
                              style: const TextStyle(
                              fontSize: 15,
                              fontFamily: "Pop600",
                              fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          const SizedBox(height: 12),
                          
                          // Radio buttons for selection type
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectionType = "service";
                                      selectedPackageId = null;
                                      selectedPackageName = null;
                                      selectedPackagePrice = null;
                                      if (availableServices.isNotEmpty) {
                                        selectedServiceIds = [availableServices[0].sId!];
                                        selectedServiceNames = [availableServices[0].serviceTitle!];
                                        selectedServiceCategory = availableServices[0].categoryName;
                                        totalServicePrice = availableServices[0].price ?? 0;
                                        selectedServiceDuration = availableServices[0].serviceDuration;
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: selectionType == "service" 
                                          ? ColorClass.base_color.withOpacity(0.1)
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selectionType == "service"
                                            ? ColorClass.base_color
                                            : Colors.grey[300]!,
                                        width: selectionType == "service" ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          selectionType == "service"
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_unchecked,
                                          color: selectionType == "service"
                                              ? ColorClass.base_color
                                              : Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Service",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: "Pop600",
                                            color: selectionType == "service"
                                                ? ColorClass.base_color
                                                : Colors.grey[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Only show Package option if packages exist
                              if (availablePackages.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectionType = "package";
                                        selectedServiceIds = [];
                                        selectedServiceNames = [];
                                        selectedServiceCategory = null;
                                        totalServicePrice = 0;
                                        selectedServiceDuration = null;
                                        if (availablePackages.isNotEmpty) {
                                          selectedPackageId = availablePackages[0]['id'];
                                          selectedPackageName = availablePackages[0]['name'];
                                          selectedPackagePrice = availablePackages[0]['price'];
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: selectionType == "package" 
                                            ? ColorClass.base_color.withOpacity(0.1)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selectionType == "package"
                                              ? ColorClass.base_color
                                              : Colors.grey[300]!,
                                          width: selectionType == "package" ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            selectionType == "package"
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_unchecked,
                                            color: selectionType == "package"
                                                ? ColorClass.base_color
                                                : Colors.grey[600],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Package",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: "Pop600",
                                              color: selectionType == "package"
                                                  ? ColorClass.base_color
                                                  : Colors.grey[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          // Service Selection List (Multi-select)
                          if (selectionType == "service" && availableServices.isNotEmpty) ...[
                            ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: availableServices.length,
                              itemBuilder: (context, index) {
                                final service = availableServices[index];
                                final isSelected = selectedServiceIds.contains(service.sId);
                                
                                return GestureDetector(
                                  onTap: () {
                                     setState(() {
                                      if (isSelected) {
                                        if (selectedServiceIds.length > 1) {
                                          selectedServiceIds.remove(service.sId);
                                          selectedServiceNames.remove(service.serviceTitle);
                                          totalServicePrice -= (service.price ?? 0);
                                        }
                                      } else {
                                        selectedServiceIds.add(service.sId!);
                                        selectedServiceNames.add(service.serviceTitle!);
                                        totalServicePrice += (service.price ?? 0);
                                        // Keep other details from the first selected
                                        selectedServiceCategory = service.categoryName;
                                        selectedServiceDuration = service.serviceDuration;
                                      }
                                      // Time slots come from the vendor — no need to swap them
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? ColorClass.base_color.withOpacity(0.05) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? ColorClass.base_color : Colors.grey[300]!,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                          color: isSelected ? ColorClass.base_color : Colors.grey[400],
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                service.serviceTitle ?? 'Service',
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontFamily: isSelected ? "Pop600" : "Pop500",
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (service.categoryName != null)
                                                Text(
                                                  service.categoryName!,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontFamily: "Pop400",
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          "\$${service.price ?? 0}",
                                          style: TextStyle(
                                            color: ColorClass.base_color,
                                            fontFamily: "Pop600",
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          
                          // Package Selection List (Radio Buttons)
                          if (selectionType == "package" && availablePackages.isNotEmpty) ...[
                            ListView.builder(
                                                        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: availablePackages.length,
                              itemBuilder: (context, index) {
                                final package = availablePackages[index];
                                final isSelected = selectedPackageId == package['id'];
                                
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedPackageId = package['id'];
                                      selectedPackageName = package['name'];
                                      selectedPackagePrice = package['price'];
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? ColorClass.base_color.withOpacity(0.05) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? ColorClass.base_color : Colors.grey[300]!,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                          color: isSelected ? ColorClass.base_color : Colors.grey[400],
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                package['name'] ?? 'Package',
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontFamily: isSelected ? "Pop600" : "Pop500",
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (package['price'] != null)
                                                Text(
                                                  "\$${package['price']}",
                                                  style: TextStyle(
                                                    color: ColorClass.base_color,
                                                    fontFamily: "Pop600",
                                                    fontSize: 13,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          
                          // Date and Time Selection - Simple design
                          const Text(
                            "Select Date & Time",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    CommonPopUp.showdateNewDialog(context, (date) {
                                      String formattedDate =
                                          DateFormat(Constant.dateFormatDigits).format(date);
                                      setState(() {
                                        dateController.text = formattedDate;
                                        dateString =
                                            DateFormat(Constant.dateFormatDigits).format(date);
                                        // Clear time slot when date changes — a slot valid for
                                        // a future date may be in the past for today.
                                        timeController.text = "";
                                        postTime = "";
                                      });
                                    }, DateTime.now(), DateTime.now(), DateTime(2050));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: dateController.text.isEmpty
                                          ? Colors.grey[50]
                                          : const Color(0xFF1CB273).withOpacity(0.06),
                                      border: Border.all(
                                        color: dateController.text.isEmpty
                                            ? Colors.grey[300]!
                                            : const Color(0xFF1CB273),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          color: dateController.text.isEmpty
                                              ? Colors.grey[400]
                                              : const Color(0xFF1CB273),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            dateController.text.isEmpty ? "Select Date" : dateController.text,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontFamily: "Pop500",
                                              color: dateController.text.isEmpty ? Colors.grey[400] : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    showDetailPopUp(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: timeController.text.isEmpty
                                          ? Colors.grey[50]
                                          : const Color(0xFF1CB273).withOpacity(0.06),
                                      border: Border.all(
                                        color: timeController.text.isEmpty
                                            ? Colors.grey[300]!
                                            : const Color(0xFF1CB273),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          color: timeController.text.isEmpty
                                              ? Colors.grey[400]
                                              : const Color(0xFF1CB273),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            timeController.text.isEmpty ? "Select Time" : timeController.text,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontFamily: "Pop500",
                                              color: timeController.text.isEmpty ? Colors.grey[400] : Colors.black87,
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

                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.timer_rounded, size: 14, color: Color(0xFF1CB273)),
                              const SizedBox(width: 6),
                              Text(
                                "Estimated: ${selectionType == "service" ? (selectedServiceDuration ?? bookingdata.serviceDuration ?? "30") : (bookingdata.serviceDuration ?? "30")} minutes",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: "Pop400",
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Note Section
                          const Text(
                            "Special Instructions (Optional)",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: "Pop600",
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border.all(color: Colors.grey[200]!, width: 1.5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TextField(
                              controller: messageController,
                              decoration: const InputDecoration(
                                hintText: "Add any special instructions...",
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontFamily: "Pop400",
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              maxLines: 3,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
         const SizedBox(height: 24),

                  // Book Now Button (Moved inside scroll)
                  GestureDetector(
                    onTap: () {
                      if (selectionType == "service" && selectedServiceIds.isEmpty) {
                        CommonWidget.errorShowSnackBarFor(context, "Please select at least one service");
                        return;
                      } else if (selectionType == "package" && selectedPackageId == null) {
                        CommonWidget.errorShowSnackBarFor(context, "Please select a package");
                        return;
                      }
                      if (BaseActivity.checkEmptyField(
                          editingController: dateController,
                          message: "Please Select Date.",
                          context: context)) {
                        return;
                      } else if (BaseActivity.checkEmptyField(
                          editingController: timeController,
                          message: "Please Select Time Slot.",
                          context: context)) {
                        return;
                      }
                      final todayFormatted = DateFormat(Constant.dateFormatDigits).format(DateTime.now());
                      if (dateString == todayFormatted) {
                        final matchingSlot = timeSlot.where((s) => s.slot?.toString() == postTime).firstOrNull;
                        if (matchingSlot != null && !_isNotPastSlot(matchingSlot)) {
                          CommonWidget.errorShowSnackBarFor(context, "Selected time slot has already passed. Please choose another.");
                          setState(() {
                            timeController.text = "";
                            postTime = "";
                          });
                          return;
                        }
                      }
                      postBookingDetails(context);
                    },
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF166534),
                            Color(0xFF1CB273),
                            Color(0xFF00E676),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1CB273).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Text(
                            "Confirm Booking",
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: "Pop600",
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 8 : 12),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  getServicesDetails(BuildContext context) async {
    var response = await dataManager!
        .getServiceDetails(context, widget.servicesData);
    
    if (!mounted) return;
    
    // Parse the response as a list of services (vendor endpoint returns array)
    var jsonData = jsonDecode(response.body);
    
    if (jsonData['status'] == "success" && jsonData['data'] != null) {
        // Handle both array (vendor endpoint) and single object (service-details endpoint)
      List servicesList;
      if (jsonData['data'] is List) {
        servicesList = jsonData['data'] as List;
      } else {
        // Single service object — wrap in a list
        servicesList = [jsonData['data']];
      }
      if (servicesList.isNotEmpty) {
        var firstService = servicesList[0];
        
          // Load all available services
          List<BookingModelData> services = [];
          for (var serviceJson in servicesList) {
            services.add(BookingModelData.fromJson(serviceJson));
          }
          
      setState(() {
            // Create BookingModelData from the first service for display
          bookingdata = BookingModelData.fromJson(firstService);
            availableServices = services;
            
            // Set default selected service (first one)
            if (availableServices.isNotEmpty) {
              selectedServiceIds = [availableServices[0].sId!];
              selectedServiceNames = [availableServices[0].serviceTitle!];
              selectedServiceCategory = availableServices[0].categoryName;
              totalServicePrice = availableServices[0].price ?? 0;
              selectedServiceDuration = availableServices[0].serviceDuration;
              selectionType = "service";
            }
            
        detailImages.clear();
        timeSlot.clear();
          if (bookingdata.detailImages != null) {
            detailImages.addAll(bookingdata.detailImages!);
          }
          // Load time slots from the vendor (shared across all vendor services)
          final vendorSlots = bookingdata.vendorId?.timeSlots;
          if (vendorSlots != null && vendorSlots.isNotEmpty) {
            timeSlot.addAll(vendorSlots);
          } else if (bookingdata.timeSlots != null && bookingdata.timeSlots!.isNotEmpty) {
            // Fallback to service-level slots for backward compatibility
            timeSlot.addAll(bookingdata.timeSlots!);
          }
        // Check if this service is bookmarked
          isBookmarked = bookingdata.isBookmarked ?? false;
      });
      // Fetch packages for this vendor
      await fetchVendorPackages();
    } else {
        CommonWidget.errorShowSnackBarFor(context, "No services found for this vendor");
      }
    } else {
      CommonWidget.errorShowSnackBarFor(context, jsonData['message'] ?? "Failed to load service details");
    }
  }

  Widget _buildFallbackImage() {
    // Try vendor display picture as fallback
    if (bookingdata.vendorId?.displayPicture != null && 
        bookingdata.vendorId!.displayPicture!.isNotEmpty) {
      return Image.network(
        bookingdata.vendorId!.displayPicture!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultCoverImage();
        },
      );
    }
    return _buildDefaultCoverImage();
  }

  Widget _buildDefaultCoverImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[300]!,
            Colors.grey[400]!,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_car_wash_rounded,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              bookingdata.serviceTitle ?? "Car Service",
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 20,
                fontFamily: "Pop600",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBookmark() async {
    try {
      if (isBookmarked) {
        // Remove bookmark
        CommonWidget.successShowSnackBarFor(context, "Removed from bookmarks");
        setState(() {
          isBookmarked = false;
        });
      } else {
        // Add bookmark
        CommonWidget.successShowSnackBarFor(context, "Added to bookmarks");
        setState(() {
          isBookmarked = true;
        });
      }
    } catch (e) {
      CommonWidget.errorShowSnackBarFor(context, "Error updating bookmark");
    }
  }

  // Method to fetch packages for the vendor
  Future<void> fetchVendorPackages() async {
    try {
      if (bookingdata.vendorId?.sId == null) {
        if (mounted) {
          setState(() {
            availablePackages = [];
            // Reset to service if no packages
            if (selectionType == "package") {
              selectionType = "service";
              selectedPackageId = null;
              selectedPackageName = null;
              selectedPackagePrice = null;
            }
          });
        }
        return;
      }
      
      // Import SpecialistsDataManager to fetch packages
      final specialistsDataManager = SpecialistsDataManager(sharedPreferences!);
      var response = await specialistsDataManager.getVendorPackages(context, bookingdata.vendorId!.sId!);
      
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == "success" && jsonData['data'] != null) {
          List<Map<String, dynamic>> packages = [];
          var packagesList = jsonData['data'] as List;
          
          for (var packageJson in packagesList) {
            packages.add({
              'id': packageJson['_id']?.toString() ?? '',
              'name': packageJson['title'] ?? packageJson['packageName'] ?? packageJson['name'] ?? 'Package',
              'price': packageJson['price'] ?? 0,
              'description': packageJson['description'] ?? '',
              'duration': packageJson['duration'] ?? packageJson['packageDuration'] ?? '',
            });
          }
          
          if (mounted) {
            setState(() {
              availablePackages = packages;
              // If no packages and currently selected type is package, switch to service
              if (packages.isEmpty && selectionType == "package") {
                selectionType = "service";
                selectedPackageId = null;
                selectedPackageName = null;
                selectedPackagePrice = null;
                  if (availableServices.isNotEmpty) {
                    selectedServiceIds = [availableServices[0].sId!];
                    selectedServiceNames = [availableServices[0].serviceTitle!];
                    selectedServiceCategory = availableServices[0].categoryName;
                    totalServicePrice = availableServices[0].price ?? 0;
                    selectedServiceDuration = availableServices[0].serviceDuration;
                  }
              }
            });
          }
        } else {
          if (mounted) {
            setState(() {
              availablePackages = [];
              // Reset to service if no packages
              if (selectionType == "package") {
                selectionType = "service";
                selectedPackageId = null;
                selectedPackageName = null;
                selectedPackagePrice = null;
              }
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            availablePackages = [];
            // Reset to service if no packages
            if (selectionType == "package") {
              selectionType = "service";
              selectedPackageId = null;
              selectedPackageName = null;
              selectedPackagePrice = null;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
      setState(() {
        availablePackages = [];
        // Reset to service if no packages
        if (selectionType == "package") {
          selectionType = "service";
          selectedPackageId = null;
          selectedPackageName = null;
          selectedPackagePrice = null;
        }
      });
      }
    }
  }

  postBookingDetails(BuildContext context) async {
    debugPrint("🚀 postBookingDetails called");
    if (!mounted || !context.mounted) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF166534), // Using brand green directly for safety
        ),
      ),
    );
    
    try {
      // Use the vendorId from bookingdata if available
      String? vendorId;
      if (bookingdata.vendorId?.sId != null) {
        vendorId = bookingdata.vendorId!.sId;
      } else {
        // Look through available services for a vendor ID
        debugPrint("🔍 vendorId missing in bookingdata, checking availableServices...");
        for (var service in availableServices) {
          if (service.vendorId?.sId != null) {
            vendorId = service.vendorId!.sId;
            debugPrint("✅ Found vendorId in availableServices: $vendorId");
            break;
          }
        }
      }
      
      // Fallback to widget.servicesData if still null
      vendorId ??= widget.servicesData;
      debugPrint("📍 Final Vendor ID to use: $vendorId");
      
      // Backend requires at least one service ID even for packages
      List<String> servicesToPost = [];
      if (selectionType == "package") {
        if (availableServices.isNotEmpty) {
          // Double check that we have a valid sId
          var serviceToUse = availableServices.firstWhere(
            (s) => s.sId != null, 
            orElse: () => availableServices[0]
          );
          
          if (serviceToUse.sId != null) {
            servicesToPost = [serviceToUse.sId!];
          } else {
            debugPrint("❌ No service with valid ID found in availableServices");
            CommonWidget.safePop(context);
            CommonWidget.errorShowSnackBarFor(context, "Cannot complete booking: Service ID missing.");
            return;
          }
        } else {
          // If for some reason availableServices is empty, we can't proceed
          debugPrint("❌ availableServices is empty");
          CommonWidget.safePop(context);
          CommonWidget.errorShowSnackBarFor(context, "Cannot complete booking: No services found for this vendor.");
          return;
        }
      } else {
        servicesToPost = selectedServiceIds;
        if (servicesToPost.isEmpty) {
          debugPrint("❌ No services selected");
          CommonWidget.safePop(context);
          CommonWidget.errorShowSnackBarFor(context, "Please select at least one service.");
          return;
        }
      }

      // Final price to send
      String priceToSend = selectionType == "package" 
          ? (selectedPackagePrice?.toString() ?? "0")
          : totalServicePrice.toString();

      // Format date specifically for backend (ISO 8601: YYYY-MM-DD)
      String isoDate = "";
      try {
        DateTime parsedDate = DateFormat(Constant.dateFormatDigits).parse(dateString);
        isoDate = DateFormat('yyyy-MM-dd').format(parsedDate);
      } catch (e) {
        debugPrint("❌ Error parsing date for ISO format: $e");
        isoDate = dateString; // fallback
      }

      // Log the payload for debugging
      debugPrint("📄 POST Booking Payload:");
      debugPrint("Vendor ID: $vendorId");
      debugPrint("Service IDs: $servicesToPost");
      debugPrint("Price: $priceToSend");
      debugPrint("Date (Original): $dateString");
      debugPrint("Date (ISO): $isoDate");
      debugPrint("Time: $postTime");
      debugPrint("TimeZone: $_userTimeZone");
      if (selectionType == "package") {
        debugPrint("Package ID: $selectedPackageId");
        debugPrint("Package Name: $selectedPackageName");
        debugPrint("Package Price: $selectedPackagePrice");
      }

      var response = await dataManager!.postBooking(
          context,
          vendorId!,
          servicesToPost,
          priceToSend,
          isoDate,
          postTime.replaceAll(' ', ''), // Ensure no spaces (HH:mm-HH:mm)
          _userTimeZone,
          packageId: selectedPackageId,
          packageName: selectedPackageName,
          packagePrice: selectedPackagePrice);
      
      if (!mounted || !context.mounted) {
        CommonWidget.safePop(context);
        return;
      }
      
      CommonWidget.safePop(context);
      
      debugPrint("📄 Response Status: ${response.statusCode}");
      debugPrint("📄 Response Body: ${response.body}");

      // Check if response is HTML (error page) instead of JSON
      if (response.body.startsWith('<!DOCTYPE html>') || response.body.startsWith('<html')) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "API Error: Received HTML instead of JSON. Please check your backend connection.");
        }
        return;
      }
      
      // Check response status code
      if (response.statusCode != 200 && response.statusCode != 201) {
        if (mounted && context.mounted) {
          String errorMessage = "Unable to create booking. Please try again.";
          try {
            var errorData = jsonDecode(response.body);
            if (errorData['message'] != null) {
              if (errorData['message'] is List) {
                errorMessage = (errorData['message'] as List).join(", ");
              } else {
                errorMessage = errorData['message'].toString();
              }
            }
          } catch (e) {
            debugPrint("❌ Error parsing error response: $e");
          }
          CommonWidget.errorShowSnackBarFor(context, errorMessage);
        }
        return;
      }
      
      try {
        var data = BookingPostBean.fromJson(jsonDecode(response.body));
        if (data.status == "success") {
          if (mounted && context.mounted) {
            CommonWidget.successShowSnackBarFor(context, data.message ?? "Booking created successfully!");
            CommonWidget.navigateToKillAllScreen(context, DashboardActivity(currentIndex: 2,));
          }
        } else {
          if (mounted && context.mounted) {
            CommonWidget.errorShowSnackBarFor(context, data.message ?? "Failed to create booking. Please try again.");
          }
        }
      } catch (jsonError) {
        if (mounted && context.mounted) {
          CommonWidget.errorShowSnackBarFor(context, "Error parsing response. Please try again.");
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error creating booking. Please check your connection and try again.");
      }
    }
  }

  getColorPickColor() {
    if (isPickUp) {
      return ColorClass.base_color;
    } else {
      return ColorClass.base_light_color;
    }
  }

  getColorSelfColor() {
    if (isPickUp) {
      return ColorClass.base_light_color;
    } else {
      return ColorClass.base_color;
    }
  }

  showDetailPopUp(BuildContext context) {
    String? selectedTimeSlot;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: ColorClass.base_color,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Select Time Slot",
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: "Pop600",
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => CommonWidget.safePop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Service info
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorClass.base_color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorClass.base_color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: ColorClass.base_color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Service Duration: ${bookingdata.serviceDuration ?? "30"} minutes",
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: "Pop500",
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Available time slots for your selected date",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: "Pop400",
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Time slots grid
              Expanded(
                child: timeSlot.isEmpty
                    ? _buildNoTimeSlotsAvailable()
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 60,
                          ),
                          itemCount: timeSlot.length,
                          itemBuilder: (context, index) {
                            final data = timeSlot[index];
                            final timeText = CommonWidget.formatTimeSlot(data.slot.toString());
                            final isSelected = selectedTimeSlot == timeText;
                            
                            // Check if time slot is available
                            final isAvailable = _isTimeSlotAvailable(data);
                            final isWithinServiceHours = _isWithinServiceHours(data);
                            final isCapacityAvailable = _isCapacityAvailable(data);
                            final isNotPastSlot = _isNotPastSlot(data);
                            final canBook = isAvailable && isWithinServiceHours && isCapacityAvailable && isNotPastSlot;
                            
                            return GestureDetector(
                              onTap: canBook ? () {
                                setSheetState(() {
                                  selectedTimeSlot = timeText;
                                });
                                setState(() {
                                  timeController.text = timeText;
                                  postTime = data.slot?.toString() ?? '';
                                });
                                CommonWidget.safePop(context);
                              } : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: !canBook 
                                      ? Colors.grey[100]
                                      : isSelected 
                                          ? ColorClass.base_color 
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !canBook
                                        ? Colors.grey[300]!
                                        : isSelected 
                                            ? ColorClass.base_color 
                                            : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: !canBook
                                      ? []
                                      : isSelected
                                          ? [
                                              BoxShadow(
                                                color: ColorClass.base_color.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        !canBook ? Icons.block : Icons.schedule,
                                        color: !canBook 
                                            ? Colors.grey[400]
                                            : isSelected ? Colors.white : ColorClass.base_color,
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timeText,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: "Pop600",
                                          color: !canBook 
                                              ? Colors.grey[400]
                                              : isSelected ? Colors.white : Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (!canBook) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          _getUnavailableReasonText(data, isWithinServiceHours, isCapacityAvailable, isNotPastSlot),
                                          style: TextStyle(
                                            color: Colors.red[400],
                                            fontFamily: "Pop400",
                                            fontSize: 8,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              
              // Bottom padding
              const SizedBox(height: 20),
            ],
          ),
        );
          }, // end StatefulBuilder
        );
      },
    );
  }

  Widget _buildNoTimeSlotsAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No Time Slots Available",
            style: TextStyle(
              fontSize: 18,
              fontFamily: "Pop600",
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please try selecting a different date",
            style: TextStyle(
              fontSize: 14,
              fontFamily: "Pop400",
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => CommonWidget.safePop(context),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text("Try Another Date"),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorClass.base_color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for time slot validation
  bool _isTimeSlotAvailable(TimeSlots timeSlot) {
    return timeSlot.slot != null && timeSlot.slot!.isNotEmpty;
  }

  bool _isWithinServiceHours(TimeSlots timeSlot) {
    // Slots are generated server-side from the vendor's open/close times,
    // so they are always within operating hours by construction.
    // Comparing UTC open/close times against slot strings caused incorrect filtering.
    return true;
  }

  bool _isCapacityAvailable(TimeSlots timeSlot) {
    // Capacity is now enforced server-side at the vendor level.
    // The client doesn't have real-time booked count per slot, so
    // we always show slots as available here — the backend will
    // reject the booking if the vendor's slotCapacity is exceeded.
    return true;
  }

  bool _isNotPastSlot(TimeSlots timeSlot) {
    try {
      if (dateString.isEmpty) return true;

      // 1. Parse selected date components
      final selectedDate = DateFormat(Constant.dateFormatDigits).parse(dateString);
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final selectedDateOnly =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

      // 2. Immediate checks for future/past days
      if (selectedDateOnly.isAfter(todayDate)) return true;
      if (selectedDateOnly.isBefore(todayDate)) return false;

      // 3. For today, parse the slot start time
      String slotString = timeSlot.slot ?? "";
      final slotParts = slotString.split(RegExp(r'\s*-\s*|\s*–\s*'));
      if (slotParts.isEmpty) return true;

      String startTimeStr = slotParts[0].trim();
      
      int hour = 0;
      int minute = 0;
      
      // Handle both "09:00 AM" and "09:00" (24h) formats
      if (startTimeStr.toLowerCase().contains("am") || startTimeStr.toLowerCase().contains("pm")) {
        try {
          final timeFormat = DateFormat("hh:mm a");
          final parsedTime = timeFormat.parse(startTimeStr);
          hour = parsedTime.hour;
          minute = parsedTime.minute;
        } catch (e) {
          // Fallback parsing if DateFormat fails
          final cleanTime = startTimeStr.replaceAll(RegExp(r'[AaPp][Mm]'), '').trim();
          final parts = cleanTime.split(':');
          if (parts.length >= 2) {
            hour = int.parse(parts[0]);
            minute = int.parse(parts[1]);
            if (startTimeStr.toLowerCase().contains("pm") && hour < 12) hour += 12;
            if (startTimeStr.toLowerCase().contains("am") && hour == 12) hour = 0;
          }
        }
      } else {
        final parts = startTimeStr.split(':');
        if (parts.length < 2) return true;
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1].split(' ')[0]);
      }

      // 4. Build absolute slot time
      // Logic: The backend slot string represents the UTC time for the selected business day.
      // We anchor the UTC slot to the selected calendar day and convert to local time.
      DateTime slotDateTimeUTC = DateTime.utc(
          selectedDateOnly.year, selectedDateOnly.month, selectedDateOnly.day, hour, minute);
      DateTime slotDateTimeLocal = slotDateTimeUTC.toLocal();

      // 5. Comparison with 10-minute buffer
      final bufferTime = now.add(const Duration(minutes: 10));
      return slotDateTimeLocal.isAfter(bufferTime);
    } catch (e) {
      debugPrint("❌ Error in _isNotPastSlot: $e");
      return true;
    }
  }

  String _getUnavailableReasonText(TimeSlots timeSlot, bool isWithinServiceHours, bool isCapacityAvailable, bool isNotPastSlot) {
    try {
      if (!isNotPastSlot) {
        return "Past slot";
      }
      if (!isWithinServiceHours) {
        return "Outside hours";
      }
      if (!isCapacityAvailable) {
        return "Full";
      }
      return "Unavailable";
    } catch (e) {
      return "Unavailable";
    }
  }

  String _getUnavailableReason(TimeSlots timeSlot, bool isWithinServiceHours, bool isCapacityAvailable, bool isNotPastSlot) {
    return _getUnavailableReasonText(timeSlot, isWithinServiceHours, isCapacityAvailable, isNotPastSlot);
  }
}
