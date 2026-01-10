import 'dart:convert';

import 'package:car_app/Common/BaseActivity.dart';
import 'package:car_app/features/booking_model/model/booking_model_data.dart';
import 'package:car_app/features/dashboard_module/ui/dashboard_activity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../Common/Color.dart';
import '../../../Common/CommonPopUp.dart';
import '../../../Common/CommonWidget.dart';
import '../data_model/booking_data_manager.dart';
import '../model/booking_post_bean.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Modern Header with Image
          Container(
            height: 280,
            child: Stack(
              children: [
                // Service Image with fallback
                Container(
                  height: 280,
                  width: double.infinity,
                  child: bookingdata.coverImage != null && bookingdata.coverImage!.isNotEmpty
                      ? Image.network(
                          bookingdata.coverImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultCoverImage();
                          },
                        )
                      : _buildDefaultCoverImage(),
                ),
                
                // Gradient overlay
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                
                // Header buttons
                Positioned(
                  top: 45,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => CommonWidget.safePop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleBookmark,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            isBookmarked ? Icons.bookmark : Icons.bookmark_border, 
                            color: isBookmarked ? ColorClass.base_color : Colors.black87, 
                            size: 20
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Service Title Overlay
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ColorClass.base_color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bookingdata.categoryName ?? "Car Service",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: "Pop500",
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bookingdata.serviceTitle ?? "Service",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: "Pop600",
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                      if (bookingdata.location?.name != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                bookingdata.location?.name ?? "",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: "Pop400",
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[600], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "4.8 (568 views)",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: "Pop500",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Modern Content Section
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Details Card
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
                            "Service Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: "Pop600",
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (bookingdata.about != null && bookingdata.about!.isNotEmpty) ...[
                            Text(
                              "About",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: "Pop500",
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bookingdata.about!,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: "Pop400",
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              Icon(Icons.access_time, color: ColorClass.base_color, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "Duration: ${bookingdata.serviceDuration ?? "30"} minutes",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: "Pop500",
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.attach_money, color: ColorClass.base_color, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "Price: \$${selectedPackagePrice ?? bookingdata.price ?? "0"}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Pop600",
                                  color: ColorClass.base_color,
                                ),
                              ),
                            ],
                          ),
                          if (selectedPackageName != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.inventory_2, color: ColorClass.base_color, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Package: $selectedPackageName",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: "Pop500",
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                          
                          // Package Selection (only if packages are available)
                          if (availablePackages.isNotEmpty) ...[
                            Text(
                              "Select Package (Optional)",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: "Pop500",
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedPackageId,
                                  hint: Text(
                                    "Choose a package",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontFamily: "Pop400",
                                      fontSize: 14,
                                    ),
                                  ),
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        "No Package (Individual Service)",
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontFamily: "Pop400",
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    ...availablePackages.map((package) {
                                      return DropdownMenuItem<String>(
                                        value: package['id'],
                                        child: Text(
                                          "${package['name']} - \$${package['price']}",
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontFamily: "Pop400",
                                            fontSize: 14,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
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
                                      } else {
                                        selectedPackageName = null;
                                        selectedPackagePrice = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          // Date and Time Selection
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Date",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: "Pop500",
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
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
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                dateController.text.isEmpty ? "Select Date" : dateController.text,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontFamily: "Pop400",
                                                  color: dateController.text.isEmpty ? Colors.grey[500] : Colors.black87,
                                                ),
                                              ),
                                            ),
                                            Icon(Icons.calendar_today, color: ColorClass.base_color, size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Time",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: "Pop500",
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        showDetailPopUp(context);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                timeController.text.isEmpty ? "Select Time" : timeController.text,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontFamily: "Pop400",
                                                  color: timeController.text.isEmpty ? Colors.grey[500] : Colors.black87,
                                                ),
                                              ),
                                            ),
                                            Icon(Icons.access_time, color: ColorClass.base_color, size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          Text(
                            "Estimate service time will be ${bookingdata.serviceDuration ?? "30"} minutes",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: "Pop400",
                              color: Colors.grey[600],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Note Section
                          Text(
                            "Note for Service Provider",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: "Pop500",
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
                            ),
                            child: TextField(
                              controller: messageController,
                              decoration: InputDecoration(
                                hintText: "Enter the instructions",
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontFamily: "Pop400",
                                ),
                                border: InputBorder.none,
                              ),
                              maxLines: 3,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: "Pop400",
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
          ),
          
          // Modern Continue Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
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
                  backgroundColor: ColorClass.base_color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: "Pop600",
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  getServicesDetails(BuildContext context) async {
    var response = await dataManager!
        .getServiceDetails(context, widget.servicesData);
    
    // Parse the response as a list of services (vendor endpoint returns array)
    var jsonData = jsonDecode(response.body);
    
    if (jsonData['status'] == "success" && jsonData['data'] != null) {
      // Get the first service from the array
      var servicesList = jsonData['data'] as List;
      if (servicesList.isNotEmpty) {
        var firstService = servicesList[0];
        
      setState(() {
          // Create BookingModelData from the first service
          bookingdata = BookingModelData.fromJson(firstService);
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

  Widget _buildDefaultCoverImage() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorClass.base_color.withOpacity(0.8),
            ColorClass.base_color.withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_car_wash,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              "Car Service",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
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
      print('Error toggling bookmark: $e');
      CommonWidget.errorShowSnackBarFor(context, "Error updating bookmark");
    }
  }

  // Method to fetch packages for the vendor
  Future<void> fetchVendorPackages() async {
    try {
      // For now, we'll return an empty list by default
      // In a real implementation, this would call an API to get packages for the vendor
      // Example: if packages are available, uncomment the code below
      setState(() {
        availablePackages = [];
        
        // Uncomment this section if packages are available for this vendor
        /*
        availablePackages = [
          {
            'id': 'package_1',
            'name': 'Basic Wash Package',
            'price': 299,
            'description': 'Exterior wash, tire cleaning, dashboard cleaning'
          },
          {
            'id': 'package_2', 
            'name': 'Premium Wash Package',
            'price': 499,
            'description': 'Basic wash + interior vacuum, seat cleaning, air freshener'
          },
          {
            'id': 'package_3',
            'name': 'Complete Care Package', 
            'price': 799,
            'description': 'Premium wash + waxing, engine cleaning, leather treatment'
          },
        ];
        */
      });
    } catch (e) {
      print('Error fetching packages: $e');
      setState(() {
        availablePackages = [];
      });
    }
  }

  postBookingDetails(BuildContext context) async {
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
    var data = BookingPostBean.fromJson(jsonDecode(response.body));
    if (data.status == "success") {
      CommonWidget.successShowSnackBarFor(context, data.message ?? "");
      CommonWidget.navigateToScreen(context, DashboardActivity(currentIndex: 2,));
    } else {
      CommonWidget.errorShowSnackBarFor(context, data.message ?? "");
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
                    Expanded(
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
                            style: TextStyle(
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
      print("❌ Error parsing service hours: $e");
      print("❌ Slot: ${timeSlot.slot}, OpenTime: ${bookingdata.vendorId?.openTime}, CloseTime: ${bookingdata.vendorId?.closeTime}");
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
      print("❌ Error checking if slot is past: $e");
      print("❌ Slot: ${timeSlot.slot}, Selected Date: $dateString");
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
      print("❌ Error in _getUnavailableReasonText: $e");
      return "Unavailable";
    }
  }

  String _getUnavailableReason(TimeSlots timeSlot, bool isWithinServiceHours, bool isCapacityAvailable, bool isNotPastSlot) {
    return _getUnavailableReasonText(timeSlot, isWithinServiceHours, isCapacityAvailable, isNotPastSlot);
  }
}
