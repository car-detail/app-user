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
  String? selectedServiceId;
  String? selectedServiceName;
  String? selectedServiceCategory;
  int? selectedServicePrice;
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
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: ColorClass.base_color,
        statusBarIconBrightness: Brightness.light,
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
                  // Service Details Card - Improved design
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: Colors.grey[700],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                        const Text(
                          "Service Details",
                          style: TextStyle(
                                fontSize: 18,
                                fontFamily: "Pop600",
                                fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (bookingdata.about != null && bookingdata.about!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                            bookingdata.about!,
                              style: TextStyle(
                              fontSize: 14,
                                fontFamily: "Pop400",
                                color: Colors.grey[700],
                                height: 1.5,
                            ),
                          ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.access_time, color: Colors.grey, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                            Text(
                                    "Duration",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: "Pop400",
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${selectionType == "service" ? (selectedServiceDuration ?? bookingdata.serviceDuration ?? "30") : (bookingdata.serviceDuration ?? "30")} min",
                              style: const TextStyle(
                                      fontSize: 15,
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
                        // Show price only if > 0
                        Builder(
                          builder: (context) {
                            int? displayPrice;
                            if (selectionType == "service") {
                              displayPrice = selectedServicePrice;
                            } else {
                              displayPrice = selectedPackagePrice;
                            }
                            
                            if (displayPrice != null && displayPrice > 0) {
                              return Column(
                                children: [
                                  const SizedBox(height: 16),
                          Row(
                            children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.attach_money, color: Colors.grey, size: 18),
                                      ),
                                      const SizedBox(width: 12),
                              Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Price",
                                  style: TextStyle(
                                                fontSize: 12,
                                                fontFamily: "Pop400",
                                                color: Colors.grey[600],
                                              ),
                                  ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "\$$displayPrice",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontFamily: "Pop600",
                                                color: ColorClass.base_color,
                                                fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Booking Section
                  Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Book A Slot",
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: "Pop600",
                              color: ColorClass.base_color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
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
                                        selectedServiceId = availableServices[0].sId;
                                        selectedServiceName = availableServices[0].serviceTitle;
                                        selectedServiceCategory = availableServices[0].categoryName;
                                        selectedServicePrice = availableServices[0].price;
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
                                        selectedServiceId = null;
                                        selectedServiceName = null;
                                        selectedServiceCategory = null;
                                        selectedServicePrice = null;
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
                          
                          const SizedBox(height: 16),
                          
                          // Service Selection Dropdown
                          if (selectionType == "service" && availableServices.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedServiceId,
                                  hint: Text(
                                    "Select a service",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontFamily: "Pop400",
                                      fontSize: 14,
                                    ),
                                  ),
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                                  items: availableServices.map((service) {
                                    return DropdownMenuItem<String>(
                                      value: service.sId,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            service.serviceTitle ?? 'Service',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                              fontFamily: "Pop500",
                                          fontSize: 14,
                                        ),
                                      ),
                                          if (service.categoryName != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              service.categoryName!,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontFamily: "Pop400",
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedServiceId = value;
                                      if (value != null) {
                                        final service = availableServices.firstWhere(
                                          (s) => s.sId == value,
                                        );
                                        selectedServiceName = service.serviceTitle;
                                        selectedServiceCategory = service.categoryName;
                                        selectedServicePrice = service.price;
                                        selectedServiceDuration = service.serviceDuration;
                                        // Update bookingdata for time slots
                                        bookingdata = service;
                                        timeSlot.clear();
                                        if (service.timeSlots != null) {
                                          timeSlot.addAll(service.timeSlots!);
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                          
                          // Package Selection Dropdown
                          if (selectionType == "package" && availablePackages.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedPackageId,
                                  hint: Text(
                                    "Select a package",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontFamily: "Pop400",
                                      fontSize: 14,
                                    ),
                                  ),
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                                  items: availablePackages.map((package) {
                                      return DropdownMenuItem<String>(
                                        value: package['id'],
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            package['name'] ?? 'Package',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                              fontFamily: "Pop500",
                                            fontSize: 14,
                                          ),
                                          ),
                                          if (package['price'] != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              "\$${package['price']}",
                                              style: TextStyle(
                                                color: ColorClass.base_color,
                                                fontFamily: "Pop600",
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ],
                                        ),
                                      );
                                    }).toList(),
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedPackageId = value;
                                      if (value != null) {
                                        final package = availablePackages.firstWhere(
                                          (p) => p['id'] == value,
                                          orElse: () => {},
                                        );
                                        selectedPackageName = package['name'];
                                        selectedPackagePrice = package['price'];
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 20),
                          
                          // Date and Time Selection - Simple design
                          const SizedBox(height: 16),
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
                                          DateFormat('dd-MM-yyyy').format(date);
                                      setState(() {
                                        dateController.text = formattedDate;
                                        dateString =
                                            DateFormat('yyyy-MM-dd').format(date);
                                      });
                                    }, DateTime.now(), DateTime.now(), DateTime(2050));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: Color(0xFF1CB273), size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            dateController.text.isEmpty ? "Select Date" : dateController.text,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: dateController.text.isEmpty ? Colors.grey : Colors.black87,
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
                                      border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time, color: Color(0xFF1CB273), size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            timeController.text.isEmpty ? "Select Time" : timeController.text,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: timeController.text.isEmpty ? Colors.grey : Colors.black87,
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
                          
                          const SizedBox(height: 12),
                          Text(
                            "Estimated time: ${selectionType == "service" ? (selectedServiceDuration ?? bookingdata.serviceDuration ?? "30") : (bookingdata.serviceDuration ?? "30")} minutes",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Note Section - Simple design
                          const Text(
                            "Special Instructions (Optional)",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: TextField(
                              controller: messageController,
                              decoration: const InputDecoration(
                                hintText: "Add any special instructions...",
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
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
          // Simple Continue Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Validate selection (service or package must be selected)
                  if (selectionType == "service" && selectedServiceId == null) {
                    CommonWidget.errorShowSnackBarFor(context, "Please select a service");
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
                  } else if(BaseActivity.checkEmptyField(
                      editingController: timeController,
                      message: "Please Select Time Slot.",
                      context: context))
                    return;
                  else
                    postBookingDetails(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1CB273),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Book Now",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
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
    
    // Parse the response as a list of services (vendor endpoint returns array)
    var jsonData = jsonDecode(response.body);
    
    if (jsonData['status'] == "success" && jsonData['data'] != null) {
        // Get all services from the array
      var servicesList = jsonData['data'] as List;
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
              selectedServiceId = availableServices[0].sId;
              selectedServiceName = availableServices[0].serviceTitle;
              selectedServiceCategory = availableServices[0].categoryName;
              selectedServicePrice = availableServices[0].price;
              selectedServiceDuration = availableServices[0].serviceDuration;
              selectionType = "service";
            }
            
        detailImages.clear();
        timeSlot.clear();
          if (bookingdata.detailImages != null) {
            detailImages.addAll(bookingdata.detailImages!);
          }
          if (bookingdata.timeSlots != null) {
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
                  selectedServiceId = availableServices[0].sId;
                  selectedServiceName = availableServices[0].serviceTitle;
                  selectedServiceCategory = availableServices[0].categoryName;
                  selectedServicePrice = availableServices[0].price;
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
    if (!mounted || !context.mounted) return;
    
    try {
      var response = await dataManager!.postBooking(
          context,
          bookingdata.vendorId?.sId.toString() ?? "",
          bookingdata.sId.toString() ?? "",
          bookingdata.price.toString() ?? "",
          dateString,
          postTime,
          _userTimeZone,
          packageId: selectedPackageId,
          packageName: selectedPackageName,
          packagePrice: selectedPackagePrice);
      
      if (!mounted || !context.mounted) return;
      
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
          CommonWidget.errorShowSnackBarFor(context, "Unable to create booking. Please check your connection and try again.");
        }
        return;
      }
      
      try {
        var data = BookingPostBean.fromJson(jsonDecode(response.body));
        if (data.status == "success") {
          if (mounted && context.mounted) {
            CommonWidget.successShowSnackBarFor(context, data.message ?? "Booking created successfully!");
            CommonWidget.navigateToScreen(context, DashboardActivity(currentIndex: 2,));
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
                            final timeText = CommonWidget.convertToLocalTime(data.slot.toString());
                            final isSelected = selectedTimeSlot == timeText;
                            
                            // Check if time slot is available
                            final isAvailable = _isTimeSlotAvailable(data);
                            final isWithinServiceHours = _isWithinServiceHours(data);
                            final isCapacityAvailable = _isCapacityAvailable(data);
                            final isNotPastSlot = _isNotPastSlot(data);
                            final canBook = isAvailable && isWithinServiceHours && isCapacityAvailable && isNotPastSlot;
                            
                            return GestureDetector(
                              onTap: canBook ? () {
                                setState(() {
                                  selectedTimeSlot = timeText;
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
    if (bookingdata.vendorId?.openTime == null || bookingdata.vendorId?.closeTime == null) {
      return true; // If no service hours defined, allow all slots
    }

    try {
      // Parse the time slot from original format (e.g., "09:00 - 10:00" or "09:00-10:00")
      String slotString = timeSlot.slot ?? "";
      // Handle both " - " and "-" separators
      final slotParts = slotString.contains(" - ") 
          ? slotString.split(" - ") 
          : slotString.split("-");
      
      if (slotParts.length < 2) {
        return true; // Invalid format, allow the slot
      }
      
      // Get start time and parse it
      String startTimeStr = slotParts[0].trim();
      // Remove any AM/PM if present
      startTimeStr = startTimeStr.replaceAll(RegExp(r'[AaPp][Mm]'), '').trim();
      final startTimeParts = startTimeStr.split(':');
      if (startTimeParts.length < 2) {
        return true; // Invalid format, allow the slot
      }
      
      int slotHour = int.parse(startTimeParts[0]);
      int slotMinute = int.parse(startTimeParts[1].split(' ')[0]); // Remove any trailing spaces/AM/PM
      
      // Parse vendor open time (expected format: "09:00" or "09:00:00" or ISO string)
      String openTimeStr = bookingdata.vendorId!.openTime!.trim();
      int openHour, openMinute;
      
      // Check if it's an ISO date string or just time
      if (openTimeStr.contains('T') || openTimeStr.contains('-')) {
        // It's an ISO date string, parse as DateTime
        try {
          final openTime = DateTime.parse(openTimeStr);
          openHour = openTime.hour;
          openMinute = openTime.minute;
        } catch (e) {
          // If parsing fails, try to extract time part
          if (openTimeStr.contains('T')) {
            final timePart = openTimeStr.split('T')[1].split(':');
            openHour = int.parse(timePart[0]);
            openMinute = int.parse(timePart[1]);
          } else {
            return true; // Can't parse, allow the slot
          }
        }
      } else {
        // It's just a time string like "09:00" or "09:00:00"
        final openTimeParts = openTimeStr.split(':');
        if (openTimeParts.length < 2) {
          return true; // Invalid format, allow the slot
        }
        openHour = int.parse(openTimeParts[0]);
        openMinute = int.parse(openTimeParts[1]);
      }
      
      // Parse vendor close time (same logic as open time)
      String closeTimeStr = bookingdata.vendorId!.closeTime!.trim();
      int closeHour, closeMinute;
      
      if (closeTimeStr.contains('T') || closeTimeStr.contains('-')) {
        // It's an ISO date string, parse as DateTime
        try {
          final closeTime = DateTime.parse(closeTimeStr);
          closeHour = closeTime.hour;
          closeMinute = closeTime.minute;
        } catch (e) {
          // If parsing fails, try to extract time part
          if (closeTimeStr.contains('T')) {
            final timePart = closeTimeStr.split('T')[1].split(':');
            closeHour = int.parse(timePart[0]);
            closeMinute = int.parse(timePart[1]);
          } else {
            return true; // Can't parse, allow the slot
          }
        }
      } else {
        // It's just a time string like "21:00" or "21:00:00"
        final closeTimeParts = closeTimeStr.split(':');
        if (closeTimeParts.length < 2) {
          return true; // Invalid format, allow the slot
        }
        closeHour = int.parse(closeTimeParts[0]);
        closeMinute = int.parse(closeTimeParts[1]);
      }
      
      // Convert to minutes for easier comparison
      final slotMinutes = slotHour * 60 + slotMinute;
      final openMinutes = openHour * 60 + openMinute;
      final closeMinutes = closeHour * 60 + closeMinute;
      
      // Check if slot is within service hours
      // Note: If close time is before open time (e.g., 22:00 to 02:00), it means it spans midnight
      if (closeMinutes < openMinutes) {
        // Service hours span midnight (e.g., 22:00 to 02:00)
        return slotMinutes >= openMinutes || slotMinutes < closeMinutes;
      } else {
        // Normal service hours (e.g., 09:00 to 21:00)
        return slotMinutes >= openMinutes && slotMinutes < closeMinutes;
      }
    } catch (e) {
      return true; // If parsing fails, allow the slot to avoid blocking all bookings
    }
  }

  bool _isCapacityAvailable(TimeSlots timeSlot) {
    if (timeSlot.capacity == null || timeSlot.booked == null) {
      return true; // If no capacity info, allow booking
    }
    // Block if booked count is greater than or equal to capacity
    return timeSlot.booked! < timeSlot.capacity!;
  }

  bool _isNotPastSlot(TimeSlots timeSlot) {
    try {
      // If no date is selected, allow the slot (date validation will happen separately)
      if (dateString.isEmpty) {
        return true;
      }

      // Parse the selected date
      final selectedDate = DateFormat('yyyy-MM-dd').parse(dateString);
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

      // If selected date is in the future, allow the slot
      if (selectedDateOnly.isAfter(todayDate)) {
        return true;
      }

      // If selected date is in the past, block all slots
      if (selectedDateOnly.isBefore(todayDate)) {
        return false;
      }

      // If selected date is today, check if the time slot has passed
      if (selectedDateOnly.isAtSameMomentAs(todayDate)) {
        // Parse the time slot to get the start time
        // The slot format from API is typically "HH:mm - HH:mm" in UTC
        String slotString = timeSlot.slot ?? "";
        final slotParts = slotString.contains(" - ") 
            ? slotString.split(" - ") 
            : slotString.split("-");
        
        if (slotParts.isEmpty) {
          return true; // Invalid format, allow the slot
        }

        // Get start time and parse it
        String startTimeStr = slotParts[0].trim();
        // Remove any AM/PM if present
        startTimeStr = startTimeStr.replaceAll(RegExp(r'[AaPp][Mm]'), '').trim();
        final startTimeParts = startTimeStr.split(':');
        
        if (startTimeParts.length < 2) {
          return true; // Invalid format, allow the slot
        }

        int slotHour = int.parse(startTimeParts[0]);
        int slotMinute = int.parse(startTimeParts[1].split(' ')[0]);

        // The slot time from API is in UTC, so we need to convert it to local time for comparison
        // Create UTC DateTime for the slot start time today
        final slotDateTimeUTC = DateTime.utc(
          now.year,
          now.month,
          now.day,
          slotHour,
          slotMinute,
        );
        
        // Convert to local time
        final slotDateTimeLocal = slotDateTimeUTC.toLocal();

        // Check if the slot time has passed (add 10 minutes buffer to account for booking time)
        // This gives users a reasonable window to complete their booking
        final bufferTime = now.add(const Duration(minutes: 10));
        
        // Compare the slot start time (in local time) with current time + buffer
        return slotDateTimeLocal.isAfter(bufferTime);
      }

      return true;
    } catch (e) {
      return true; // If parsing fails, allow the slot
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
