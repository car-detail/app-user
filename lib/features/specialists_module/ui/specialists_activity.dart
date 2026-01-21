import 'dart:async';
import 'dart:convert';

import 'package:car_app/Common/Color.dart';
import 'package:car_app/features/home_module/model/services_model_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Common/CommonWidget.dart';
import '../../../ZoomImageList.dart';
import '../../booking_model/ui/booking_activity.dart';
import '../../rating_model/ui/rating_review_screen.dart';
import '../../categories_module/data_manager/categories_list_data_manager.dart';
import '../data_manager/specialists_data_manager.dart';
import '../model/services_details_model_data.dart';
import 'offer_list_widget.dart';
import 'all_packages_screen.dart';
import 'all_offers_screen.dart';
import '../utils/package_mapper.dart';

class SpecialistsActivity extends StatefulWidget {
  String servicesData;

  SpecialistsActivity(this.servicesData, {super.key});

  @override
  State<SpecialistsActivity> createState() => _SpecialistsActivityState();
}

class _SpecialistsActivityState extends State<SpecialistsActivity> {
  SpecialistsDataManager? dataManager;
  CategoriesListDataManager? bookmarkDataManager;
  SharedPreferences? sharedPreferences;
  ServicesDetailsData servicesDetailsData =
      ServicesDetailsData(detailImages: []);
  List<String> detailImages = [];
  bool isBookmarked = false;
  bool _isLoadingPackages = false;
  bool _isLoadingDetails = true;
  String? _packagesError;
  String? _lastFetchedVendorId;
  String selectedTab = "About";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    // Validate vendor ID before proceeding
    if (widget.servicesData.isEmpty || widget.servicesData.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            CommonWidget.errorShowSnackBarFor(context, "Invalid vendor ID. Cannot load details.");
            Navigator.pop(context);
          }
        });
      }
      return;
    }
    
    // Initialize data managers asynchronously without blocking
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = SpecialistsDataManager(sharedPreferences!);
    bookmarkDataManager = CategoriesListDataManager(sharedPreferences!);
    
    // Check if widget is still mounted before using context
    if (!mounted) return;
    
    // Use a post-frame callback with a small delay to ensure UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a small delay to ensure navigation animation completes
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          getServicesDetails(context);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching initial data
    if (_isLoadingDetails && servicesDetailsData.serviceTitle == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: ColorClass.base_color,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: ColorClass.base_color,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
              ),
              const SizedBox(height: 16),
              Text(
                "Loading vendor details...",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: "Pop400",
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          ),
        ),
      );
    }
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: ColorClass.base_color,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: ColorClass.base_color,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
      backgroundColor: Colors.grey[50],
        body: RefreshIndicator(
        onRefresh: () async {
          if (mounted && context.mounted) {
            await getServicesDetails(context);
          }
        },
        child: CustomScrollView(
        slivers: [
          // Collapsible Header with Image
          _buildCollapsibleHeader(context),
          // Content
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Info Card
                  _buildServiceInfoCard(context),
                  const SizedBox(height: 12),
                  // Separator
                  Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                  const SizedBox(height: 12),
                  // Quick Info Cards
                  _buildQuickInfoCards(context),
                  const SizedBox(height: 12),
                  // Separator
                  Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                  const SizedBox(height: 12),
                  // Navigation Tabs
                  _buildNavigationTabs(context),
                  const SizedBox(height: 12),
                  // Separator
                  Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                  const SizedBox(height: 12),
                  // Vendor Info Card
                  _buildVendorInfoCard(context),
                  const SizedBox(height: 10),
                  // Tab Content - show content based on selected tab
                  _buildTabContent(context),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
        ),
      ),
      // Enhanced Book Now Button
      bottomNavigationBar: _buildBookNowButton(context),
      ),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.4,
      child: Stack(
        children: [
          // Cover Image - Use service image, fallback to vendor image, then default
          GestureDetector(
            onTap: () {
              List<String> images = [];
              if (servicesDetailsData.coverImage != null && servicesDetailsData.coverImage!.isNotEmpty) {
                images.add(servicesDetailsData.coverImage!);
              } else if (servicesDetailsData.vendorId?.displayPicture != null && 
                         servicesDetailsData.vendorId!.displayPicture!.isNotEmpty) {
                images.add(servicesDetailsData.vendorId!.displayPicture!);
              }
              if (images.isNotEmpty) {
                CommonWidget.navigateToScreen(
                  context,
                  ZoomableImageList(imageUrls: images)
                );
              }
            },
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: (servicesDetailsData.coverImage != null && servicesDetailsData.coverImage!.isNotEmpty)
                  ? Image.network(
                      servicesDetailsData.coverImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to vendor image
                        return _buildCoverImageWithVendorFallback();
                      },
                    )
                  : _buildCoverImageWithVendorFallback(),
            ),
          ),
          
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          
          // Top Navigation
          Positioned(
            top: 45,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CommonWidget.buildBackButton(
                  context,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  iconColor: Colors.black87,
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
                // All Category Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _getVendorCategories().map((category) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ColorClass.base_color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: "Pop500",
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  servicesDetailsData.serviceTitle ?? "Service",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: "Pop600",
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
                if (servicesDetailsData.location?.name != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          servicesDetailsData.location?.name ?? "",
                          style: const TextStyle(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImageWithVendorFallback() {
    // Priority 1: Try service cover image first
    String? coverImage = servicesDetailsData.coverImage;
    if (coverImage != null && coverImage.trim().isNotEmpty) {
      return Image.network(
        coverImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // If cover image fails to load, fallback to vendor image
          return _buildHeaderImageWithVendorFallback();
        },
      );
    }
    // Priority 2: If no cover image, use vendor image
    return _buildHeaderImageWithVendorFallback();
  }

  Widget _buildHeaderImageWithVendorFallback() {
    // Priority 2: Try vendor display picture
    String? vendorImage = servicesDetailsData.vendorId?.displayPicture;
    if (vendorImage != null && vendorImage.trim().isNotEmpty) {
      return Image.network(
        vendorImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultCoverImage();
        },
      );
    }
    // Priority 3: If no vendor image, show default
    return _buildDefaultCoverImage();
  }

  Widget _buildCollapsibleHeaderImageWithVendorFallback() {
    // Priority 1: Try service cover image first
    String? coverImage = servicesDetailsData.coverImage;
    if (coverImage != null && coverImage.trim().isNotEmpty) {
      return Image.network(
        coverImage,
        height: MediaQuery.of(context).size.height * 0.4,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // If cover image fails to load, fallback to vendor image
          return _buildHeaderImageWithVendorFallbackForHeader();
        },
      );
    }
    // Priority 2: If no cover image, use vendor image
    return _buildHeaderImageWithVendorFallbackForHeader();
  }

  Widget _buildHeaderImageWithVendorFallbackForHeader() {
    // Priority 2: Try vendor display picture
    String? vendorImage = servicesDetailsData.vendorId?.displayPicture;
    if (vendorImage != null && vendorImage.trim().isNotEmpty) {
      return Image.network(
        vendorImage,
        height: MediaQuery.of(context).size.height * 0.4,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultCollapsibleHeaderImage();
        },
      );
    }
    // Priority 3: If no vendor image, show default
    return _buildDefaultCollapsibleHeaderImage();
  }

  Widget _buildDefaultCollapsibleHeaderImage() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorClass.base_color, ColorClass.base_color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.local_car_wash,
          color: Colors.white,
          size: 80,
        ),
      ),
    );
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
            ColorClass.base_color.withOpacity(0.8),
            ColorClass.base_color.withOpacity(0.6),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_car_wash,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 16),
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

  Widget _buildCollapsibleHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.sizeOf(context).height * 0.4,
      floating: false,
      pinned: true,
      backgroundColor: ColorClass.base_color,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Cover Image - Use service image, fallback to vendor image, then default
            GestureDetector(
              onTap: () {
                List<String> images = [];
                if (servicesDetailsData.coverImage != null && servicesDetailsData.coverImage!.isNotEmpty) {
                  images.add(servicesDetailsData.coverImage!);
                } else if (servicesDetailsData.vendorId?.displayPicture != null && 
                           servicesDetailsData.vendorId!.displayPicture!.isNotEmpty) {
                  images.add(servicesDetailsData.vendorId!.displayPicture!);
                }
                if (images.isNotEmpty) {
                  CommonWidget.navigateToScreen(
                    context,
                    ZoomableImageList(imageUrls: images)
                  );
                }
              },
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: _buildCollapsibleHeaderImageWithVendorFallback(),
              ),
            ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Service Info
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // All Category Badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _getVendorCategories().map((category) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ColorClass.base_color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: "Pop500",
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    servicesDetailsData.serviceTitle ?? "Service",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: "Pop600",
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                  if (servicesDetailsData.location?.name != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            servicesDetailsData.location?.name ?? "",
                            style: const TextStyle(
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
                ],
              ),
            ),
          ],
        ),
      ),
      leading: GestureDetector(
        onTap: () => CommonWidget.safePop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _toggleBookmark,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? Colors.orange : Colors.black87,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with light grey background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
            children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorClass.base_color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_rounded, color: ColorClass.base_color, size: 18),
                ),
                const SizedBox(width: 10),
              const Text(
                "Service Details",
                style: TextStyle(
                    fontSize: 16,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                    fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ),
          const SizedBox(height: 12),
          if (servicesDetailsData.averageRating != 0) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${servicesDetailsData.averageRating?.toStringAsFixed(1) ?? '0.0'} Rating",
                    style: const TextStyle(
                      fontSize: 16,
                          fontFamily: "Pop600",
                      color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Based on reviews",
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: "Pop400",
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.people_rounded, color: Colors.blue.shade700, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        servicesDetailsData.totalReviews.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                          fontFamily: "Pop600",
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Reviews",
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
            const SizedBox(height: 20),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey[300]!,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (servicesDetailsData.price != null && servicesDetailsData.price! > 0) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorClass.base_color,
                        ColorClass.base_color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: ColorClass.base_color.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.attach_money_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Starting from",
                    style: TextStyle(
                          fontSize: 12,
                          fontFamily: "Pop400",
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "\$${servicesDetailsData.price}",
                        style: TextStyle(
                          fontSize: 22,
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
            const SizedBox(height: 20),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey[300]!,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (servicesDetailsData.serviceDuration != null) ...[
            Row(
              children: [
                      Icon(Icons.access_time_rounded, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 6),
                Text(
                        "Duration: ${servicesDetailsData.serviceDuration ?? "N/A"}",
                  style: TextStyle(
                          fontSize: 13,
                          fontFamily: "Pop400",
                          color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickInfoCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.verified_user_rounded,
            title: "Verified",
            subtitle: "Trusted",
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.access_time_filled_rounded,
            title: "Available",
            subtitle: "Book Now",
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.location_on_rounded,
            title: "Nearby",
            subtitle: "Quick",
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
          ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ColorClass.base_color, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: "Pop600",
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontFamily: "Pop400",
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTabs(BuildContext context) {
    // Build list of available tabs based on content
    List<Map<String, dynamic>> availableTabs = [
      {"title": "About", "icon": Icons.info_rounded, "key": "About"},
    ];
    
    if (servicesDetailsData.services.isNotEmpty) {
      availableTabs.add({"title": "Services", "icon": Icons.build_circle_rounded, "key": "Services"});
    }
    
    // Always show Packages tab (like Reviews tab)
    availableTabs.add({"title": "Packages", "icon": Icons.inventory_2_rounded, "key": "Packages"});
    
    // Only show Offers tab if there are active offers
    final activeOffers = (servicesDetailsData.offers ?? [])
        .where((offer) => offer.isCurrentlyActive == true)
        .toList();
    if (activeOffers.isNotEmpty) {
      availableTabs.add({"title": "Offers", "icon": Icons.local_offer_rounded, "key": "Offers"});
    }
    
    if (detailImages.isNotEmpty) {
      availableTabs.add({"title": "Gallery", "icon": Icons.photo_library_rounded, "key": "Gallery"});
    }
    
    availableTabs.add({"title": "Reviews", "icon": Icons.star_rounded, "key": "Reviews"});
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[100]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: availableTabs.map((tab) {
          return Flexible(
            child: _buildTabButton(
              tab["title"] as String,
              tab["icon"] as IconData,
              selectedTab == tab["key"],
              tab["key"] as String,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, bool isSelected, String tabKey) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = tabKey;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? ColorClass.base_color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorClass.base_color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  icon,
                  key: ValueKey(isSelected),
                  color: isSelected
                      ? Colors.white
                      : Colors.grey[500],
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              style: TextStyle(
                fontSize: isSelected ? 12 : 11,
                fontFamily: isSelected ? "Pop600" : "Pop500",
                color: isSelected
                    ? Colors.white
                    : Colors.grey[600],
                letterSpacing: 0.2,
                height: 1.2,
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    switch (selectedTab) {
      case "About":
        return Column(
          children: [
            _buildAboutSection(context),
            const SizedBox(height: 10),
          ],
        );
      case "Services":
        return servicesDetailsData.services.isNotEmpty
            ? Column(
                children: [
                  _buildServicesSection(context),
                  const SizedBox(height: 10),
                ],
              )
            : _buildEmptyTabState("No services available", Icons.build_circle_outlined);
      case "Packages":
        return _hasVendorPackages()
            ? Column(
                children: [
                  _buildPackagesSection(context),
                  const SizedBox(height: 10),
                ],
              )
            : _buildEmptyTabState("No packages available", Icons.inventory_2_outlined);
      case "Offers":
        final activeOffers = (servicesDetailsData.offers ?? [])
            .where((offer) => offer.isCurrentlyActive == true)
            .toList();
        return activeOffers.isNotEmpty
            ? Column(
                children: [
                  _buildOffersSection(context),
                  const SizedBox(height: 10),
                ],
              )
            : _buildEmptyTabState("No offers available", Icons.local_offer_outlined);
      case "Gallery":
        return detailImages.isNotEmpty
            ? Column(
                children: [
                  _buildGallerySection(context),
                  const SizedBox(height: 10),
                ],
              )
            : _buildEmptyTabState("No gallery images available", Icons.photo_library_outlined);
      case "Reviews":
        return Column(
          children: [
            _buildReviewsSection(context),
            const SizedBox(height: 10),
          ],
        );
      default:
        return _buildAboutSection(context);
    }
  }

  Widget _buildEmptyTabState(String message, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Pop500",
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
          ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with light grey background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
            children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ColorClass.base_color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.description, color: ColorClass.base_color, size: 16),
                ),
              const SizedBox(width: 8),
              const Text(
                  "About",
                style: TextStyle(
                    fontSize: 15,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                    fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ),
          const SizedBox(height: 10),
          Text(
            servicesDetailsData.about ?? "No description available for this service.",
            style: TextStyle(
              fontSize: 13,
              fontFamily: "Pop400",
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Get unique categories from services
  List<String> _getVendorCategories() {
    Set<String> categories = {};
    // Add main service category
    if (servicesDetailsData.categoryName != null && servicesDetailsData.categoryName!.isNotEmpty) {
      categories.add(servicesDetailsData.categoryName!);
    }
    // Add categories from all services (both from category list and categoryName)
    for (var service in servicesDetailsData.services) {
      // First, check if service has a category list
      if (service.category != null && service.category!.isNotEmpty) {
        for (var cat in service.category!) {
          if (cat.categoryTitle != null && cat.categoryTitle!.isNotEmpty) {
            categories.add(cat.categoryTitle!);
          }
        }
      }
      // Also check categoryName as fallback
      if (service.categoryName != null && service.categoryName!.isNotEmpty) {
        categories.add(service.categoryName!);
      }
    }
    return categories.toList();
  }

  // Build categories chips
  Widget _buildCategoriesChips() {
    final categories = _getVendorCategories();
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: categories.map((category) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: ColorClass.base_color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ColorClass.base_color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            category,
            style: TextStyle(
              fontSize: 12,
              fontFamily: "Pop500",
              color: ColorClass.base_color,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVendorInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
          ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ColorClass.base_color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.business, color: ColorClass.base_color, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                "Service Provider",
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Vendor Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: servicesDetailsData.vendorId?.displayPicture != null &&
                          servicesDetailsData.vendorId!.displayPicture!.isNotEmpty
                      ? Image.network(
                          servicesDetailsData.vendorId!.displayPicture!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.local_car_wash,
                            color: Colors.grey[600],
                              size: 30,
                            );
                          },
                        )
                      : Icon(
                          Icons.local_car_wash,
                            color: Colors.grey[600],
                          size: 30,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Vendor Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servicesDetailsData.vendorId?.displayName ?? "Service Provider",
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: "Pop600",
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Professional Car Service",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "Pop400",
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Categories
                    _buildCategoriesChips(),
                  ],
                ),
              ),
              // Action Buttons
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      try {
                        final Uri phoneUri = Uri(
                          scheme: 'tel',
                          path: servicesDetailsData.vendorId?.mobile,
                        );
                        launchUrl(phoneUri);
                      } catch (e) {
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.phone,
                        color: Colors.grey[700],
                        size: 20,
                      ),
                    ),
                  ),
                  // Removed message/chat icon per requirement
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
          ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ColorClass.base_color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.build_circle_rounded, color: ColorClass.base_color, size: 16),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                "Available Services",
                style: TextStyle(
                    fontSize: 15,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Show all services directly
          ...servicesDetailsData.services.map((service) {
            // Get all categories for this service
            List<String> categories = [];
            if (service.category != null && service.category!.isNotEmpty) {
              categories = service.category!
                  .where((cat) => cat.categoryTitle != null && cat.categoryTitle!.isNotEmpty)
                  .map((cat) => cat.categoryTitle!)
                  .toList();
            }
            if (categories.isEmpty && service.categoryName != null && service.categoryName!.isNotEmpty) {
              categories.add(service.categoryName!);
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          categories.isNotEmpty 
                              ? categories.first 
                              : service.categoryName ?? service.serviceTitle ?? "Service",
                          style: const TextStyle(
                            fontSize: 15,
                            fontFamily: "Pop600",
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (service.price != null && service.price! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ColorClass.base_color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "\$${service.price}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: "Pop600",
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Show additional categories if there are multiple
                  if (categories.length > 1) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: categories.skip(1).map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ColorClass.base_color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ColorClass.base_color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: "Pop500",
                              color: ColorClass.base_color,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            );
          }),
          // Service Details Card with Image
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Image
                if (servicesDetailsData.coverImage != null && servicesDetailsData.coverImage!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.network(
                        servicesDetailsData.coverImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            color: Colors.grey[100],
                            child: Icon(Icons.local_car_wash_rounded, color: Colors.grey[400], size: 48),
                          );
                        },
                      ),
                    ),
                  )
                else if (servicesDetailsData.vendorId?.displayPicture != null && 
                         servicesDetailsData.vendorId!.displayPicture!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.network(
                        servicesDetailsData.vendorId!.displayPicture!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            color: Colors.grey[100],
                            child: Icon(Icons.local_car_wash_rounded, color: Colors.grey[400], size: 48),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Icon(Icons.local_car_wash_rounded, color: Colors.grey[400], size: 48),
                  ),
                // Service Content
                Padding(
                  padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            servicesDetailsData.serviceTitle ?? "Car Service",
                            style: const TextStyle(
                                    fontSize: 18,
                              fontFamily: "Pop600",
                              color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                            ),
                          ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                            servicesDetailsData.categoryName ?? "Car Wash",
                            style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: "Pop500",
                                      color: Colors.grey[700],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (servicesDetailsData.price != null && servicesDetailsData.price! > 0)
                      Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "\$${servicesDetailsData.price}",
                          style: const TextStyle(
                                  fontSize: 16,
                            fontFamily: "Pop600",
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Service Duration
                if (servicesDetailsData.serviceDuration != null) ...[
                  Row(
                    children: [
                            Icon(Icons.access_time_rounded, color: Colors.grey[600], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Duration: ${servicesDetailsData.serviceDuration}",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: "Pop400",
                                color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                        const SizedBox(height: 12),
                ],
                // Time Slot Capacity
                if (servicesDetailsData.timeSlotCapacity != null) ...[
                  Row(
                    children: [
                            Icon(Icons.people_rounded, color: Colors.grey[600], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Capacity: ${servicesDetailsData.timeSlotCapacity} customers per slot",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Pop400",
                                  color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                        const SizedBox(height: 12),
                ],
                // Service Description
                if (servicesDetailsData.about != null && servicesDetailsData.about!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      servicesDetailsData.about!,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "Pop400",
                        color: Colors.grey[700],
                              height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Additional Services Info
          Row(
            children: [
              Expanded(
                child: _buildServiceInfoItem(
                  icon: Icons.star_rounded,
                  title: "Rating",
                  value: servicesDetailsData.averageRating != 0 
                      ? "${servicesDetailsData.averageRating?.toStringAsFixed(1) ?? '0.0'} ⭐"
                      : "No ratings yet",
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildServiceInfoItem(
                  icon: Icons.people_rounded,
                  title: "Reviews",
                  value: "${servicesDetailsData.totalReviews ?? 0} reviews",
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildServiceInfoItem(
                  icon: Icons.location_on_rounded,
                  title: "Location",
                  value: servicesDetailsData.location?.name ?? "Location not available",
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildServiceInfoItem(
                  icon: Icons.verified_user_rounded,
                  title: "Status",
                  value: servicesDetailsData.isActive == true ? "Active" : "Inactive",
                  color: servicesDetailsData.isActive == true ? Colors.green.shade700 : Colors.grey[700]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontFamily: "Pop500",
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: "Pop600",
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper method to check if vendor has packages
  bool _hasVendorPackages() {
    // Check if the vendor has created any packages
    return servicesDetailsData.packages.isNotEmpty;
  }

  Widget _buildPackagesSection(BuildContext context) {
    bool hasPackages = _hasVendorPackages();
    
    if (!hasPackages) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
          ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ColorClass.base_color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.inventory_2_rounded, color: ColorClass.base_color, size: 16),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                "Service Packages",
                style: TextStyle(
                    fontSize: 15,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                    fontWeight: FontWeight.bold,
                ),
              ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${servicesDetailsData.packages.length}",
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: "Pop600",
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Show all packages directly
          ...servicesDetailsData.packages.map((package) => _buildVendorPackageCard(package)),
        ],
      ),
    );
  }

  Widget _buildVendorPackageCard(Map<String, dynamic> package) {
    final rawPackage = package['raw'] ?? package;
    final packageName = package['title'] ?? package['packageName'] ?? 'Service Package';
    final description = package['description'] ?? '';
    final price = package['price'];
    final smallVehiclePrice = rawPackage['smallVehiclePrice'];
    final largeVehiclePrice = rawPackage['largeVehiclePrice'];
    final duration = package['duration'] ?? "TBD";
    final servicesIncluded = package['servicesIncluded'] as List<dynamic>? ?? [];
    final features = package['features'] as List<dynamic>? ?? [];
    final packageTier = rawPackage['packageTier']?.toString() ?? '';
    final isBestSeller = rawPackage['isBestSeller'] == true;
    final coverImage = package['coverImage'] ?? rawPackage['coverImage'];
    
    // Extract category names from services included
    List<String> categoryTags = [];
    if (servicesIncluded.isNotEmpty) {
      for (var service in servicesIncluded) {
        if (service is Map<String, dynamic>) {
          final rawService = service['raw'] ?? service;
          final categoryName = rawService['categoryName']?.toString() ?? 
                              service['title']?.toString();
          if (categoryName != null && categoryName.isNotEmpty && !categoryTags.contains(categoryName)) {
            categoryTags.add(categoryName);
          }
        }
      }
    }
    
    // Combine features and category tags
    final allTags = <String>[];
    if (features.isNotEmpty) {
      allTags.addAll(features.map((f) => f.toString()));
    }
    if (categoryTags.isNotEmpty) {
      allTags.addAll(categoryTags);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Image/Gradient
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorClass.base_color,
                      ColorClass.base_color.withOpacity(0.7),
                    ],
                  ),
                ),
                child: coverImage != null && coverImage.toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          coverImage.toString(),
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: ColorClass.base_color,
                              child: Icon(
                                Icons.card_giftcard,
                                color: Colors.white.withOpacity(0.3),
                                size: 48,
                              ),
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.card_giftcard,
                        color: Colors.white.withOpacity(0.3),
                        size: 48,
                      ),
              ),
              // Gradient Overlay
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
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
              // Badges
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isBestSeller)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              "Best Seller",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (packageTier.isNotEmpty && packageTier != 'BASIC')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          packageTier,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package Name
                Text(
                  packageName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: "Pop600",
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Description
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 16),
                // Price Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorClass.base_color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_money, color: ColorClass.base_color, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (smallVehiclePrice != null && largeVehiclePrice != null) ...[
                              Text(
                                "Small Vehicle: \$$smallVehiclePrice",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ColorClass.base_color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Large Vehicle: \$$largeVehiclePrice",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ColorClass.base_color,
                                ),
                              ),
                            ] else if (price != null) ...[
                              Text(
                                "\$$price",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ColorClass.base_color,
                                  fontFamily: "Pop600",
                                ),
                              ),
                            ] else ...[
                              Text(
                                "Price TBD",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Info Row
                Row(
                  children: [
                    // Duration
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                duration,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Number of Services
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.build_circle, size: 16, color: Colors.purple[700]),
                          const SizedBox(width: 6),
                          Text(
                            "${servicesIncluded.length} ${servicesIncluded.length == 1 ? 'Service' : 'Services'}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.purple[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Tags Section
                if (allTags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Includes:",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allTags.map((tag) => _buildServiceTagChip(tag)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ColorClass.base_color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ColorClass.base_color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: ColorClass.base_color, size: 14),
          const SizedBox(width: 6),
          Text(
            tag,
            style: TextStyle(
              fontSize: 12,
              fontFamily: "Pop500",
              color: ColorClass.base_color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard({
    required String title,
    required String description,
    required String price,
    required String duration,
    required List<String> features,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: "Pop600",
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "Pop400",
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: "Pop600",
                      color: color,
                    ),
                  ),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: "Pop400",
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Features List
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: features.map((feature) => _buildFeatureChip(feature)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String feature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.grey[600], size: 14),
          const SizedBox(width: 4),
          Text(
        feature,
        style: TextStyle(
              fontSize: 11,
          fontFamily: "Pop400",
              color: Colors.grey[700],
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
          ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ColorClass.base_color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.photo_library, color: ColorClass.base_color, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                "Gallery",
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: detailImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    CommonWidget.navigateToScreen(
                      context,
                      ZoomableImageList(
                        imageUrls: detailImages,
                        currentIndex: index,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        detailImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image,
                            color: Colors.grey[400],
                            size: 32,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersSection(BuildContext context) {
    // Filter only active offers (isCurrentlyActive == true)
    final activeOffers = (servicesDetailsData.offers ?? [])
        .where((offer) => offer.isCurrentlyActive == true)
        .toList();
    
    if (activeOffers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
          ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with light grey background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
            children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ColorClass.base_color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.local_offer_rounded, color: ColorClass.base_color, size: 16),
                ),
              const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Special Offers",
                style: TextStyle(
                      fontSize: 15,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${activeOffers.length}",
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: "Pop600",
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
                ),
              ),
          const SizedBox(height: 12),
          // Show only active offers (isCurrentlyActive == true)
          ...activeOffers.map((offer) => _buildOfferPreviewCard(offer)),
        ],
      ),
    );
  }

  Widget _buildOfferPreviewCard(Offers offer) {
    // Add null safety check
    final offerTitle = offer.title ?? "Special Offer";
    final description = offer.description ?? '';
    final imageUrl = offer.image;
    final discount = offer.discount;
    final validUntil = offer.validUntil;
    final serviceId = offer.service;
    
    // Find the service associated with this offer to get category name and price
    String? categoryName;
    int? servicePrice;
    if (serviceId != null && serviceId.isNotEmpty && servicesDetailsData.services.isNotEmpty) {
      final service = servicesDetailsData.services.firstWhere(
        (s) => s.sId == serviceId,
        orElse: () => servicesDetailsData.services.first,
      );
      categoryName = service.categoryName;
      servicePrice = service.price;
    }
    
    // Format valid until date
    String? formattedValidUntil;
    if (validUntil != null && validUntil.isNotEmpty) {
      try {
        final date = DateTime.parse(validUntil);
        formattedValidUntil = "${date.day}/${date.month}/${date.year}";
      } catch (e) {
        formattedValidUntil = validUntil;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Image/Gradient
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange[400]!,
                      Colors.red[400]!,
                    ],
                  ),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.orange[400],
                              child: Icon(
                                Icons.local_offer_rounded,
                                color: Colors.white.withOpacity(0.3),
                                size: 48,
                              ),
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.local_offer_rounded,
                        color: Colors.white.withOpacity(0.3),
                        size: 48,
                      ),
              ),
              // Gradient Overlay
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // Discount Badge - Top Left (only if discount exists and > 0)
              if (discount != null && discount > 0)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red[700],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.percent, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "$discount% OFF",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Pop600",
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Title and Category - Bottom Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offerTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Pop600",
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (categoryName != null && categoryName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            categoryName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: "Pop500",
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 16),
                // Price Section (only if service price exists)
                if (servicePrice != null && servicePrice > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.green[700], size: 24),
                        const SizedBox(width: 8),
                        // Show discounted price if discount exists, otherwise show original price
                        if (discount != null && discount > 0) ...[
                          // Original price with strikethrough
                          Text(
                            "\$$servicePrice",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                              fontFamily: "Pop500",
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Discounted price
                          Text(
                            "\$${(servicePrice * (1 - discount / 100)).toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                              fontFamily: "Pop600",
                            ),
                          ),
                        ] else ...[
                          // Just show original price
                          Text(
                            "Service Price: \$$servicePrice",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                              fontFamily: "Pop600",
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Info Row
                Row(
                  children: [
                    // Valid Until
                    if (formattedValidUntil != null) ...[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.orange[700]),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  "Valid until: $formattedValidUntil",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
          ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with light grey background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
            children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ColorClass.base_color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.star_rounded, color: ColorClass.base_color, size: 16),
                ),
              const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                "Customer Reviews",
                style: TextStyle(
                      fontSize: 15,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                ),
              ),
            ],
          ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (servicesDetailsData.totalReviews != null && servicesDetailsData.totalReviews! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${servicesDetailsData.totalReviews}",
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: "Pop600",
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (servicesDetailsData.totalReviews != null && servicesDetailsData.totalReviews! > 0) ...[
            GestureDetector(
              onTap: () {
                CommonWidget.navigateToScreen(
                  context,
                  RatingReviewScreen(servicesDetailsData),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ColorClass.base_color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.star, color: ColorClass.base_color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Read Reviews",
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: "Pop500",
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${servicesDetailsData.totalReviews} reviews",
                              style: TextStyle(
                              fontSize: 11,
                                fontFamily: "Pop400",
                                color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 14),
                  ],
                ),
              ),
            ),
          ] else ...[
            // No reviews available - show empty state
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    color: Colors.grey[400],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No reviews available at the moment.",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Pop500",
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookNowButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            CommonWidget.navigateToScreen(
              context,
              BookingActivity(widget.servicesData),
            );
          },
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorClass.base_color,
                  ColorClass.base_color.withOpacity(0.9),
                  ColorClass.base_color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: ColorClass.base_color.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Book This Service",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: "Pop600",
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  getServicesDetails(BuildContext context) async {
    try {
      // Set loading state
      if (mounted) {
        setState(() {
          _isLoadingDetails = true;
        });
      }
      
      
      // Add timeout to prevent hanging - reduced to 15 seconds
      var response = await dataManager!
          .getServiceDetails(context, widget.servicesData)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException("API call timed out", const Duration(seconds: 15));
            },
          );
      
      // Check if widget is still mounted before proceeding
      if (!mounted) {
        return;
      }
      
      
      // Check if response is valid
      if (response.statusCode != 200) {
        if (mounted) {
          String errorMessage = "Failed to load vendor details";
          if (response.statusCode == 400) {
            errorMessage = "Invalid vendor ID. Please try again.";
          } else if (response.statusCode == 404) {
            errorMessage = "Vendor not found. Please try again.";
          } else if (response.statusCode == 500) {
            errorMessage = "Server error. Please try again later.";
          } else {
            errorMessage = "Unable to load vendor details. Please try again.";
          }
          CommonWidget.errorShowSnackBarFor(context, errorMessage);
        }
        return;
      }
      
      var jsonData = jsonDecode(response.body);
      
      if (jsonData['status'] == "success" && jsonData['data'] != null) {
        var data = jsonData['data'];
        String? vendorIdForPackages;
        
        // Check if data is a list (vendor services) or single object (service details)
        if (data is List) {
          // This is a vendor services response (array of services)
          if (data.isNotEmpty) {
            // Use the first service for display, but store all services
            var firstService = data[0];
            
            if (mounted) {
              setState(() {
                servicesDetailsData = ServicesDetailsData.fromJson(firstService);
                servicesDetailsData.services.clear();
                servicesDetailsData.services.addAll(data.map((service) => Services.fromJson(service)).toList());
                detailImages.clear();
                detailImages.addAll(servicesDetailsData.detailImages!);
                              isBookmarked = servicesDetailsData.isBookmarked ?? false;
              });
            }

            vendorIdForPackages = firstService['vendorId'] is Map
                ? firstService['vendorId']['_id']?.toString()
                : firstService['vendorId']?.toString();
            
          } else {
            if (mounted) {
              CommonWidget.errorShowSnackBarFor(context, "No services found for this vendor");
            }
            return;
          }
        } else {
          // This is a single service details response
          if (mounted) {
            setState(() {
              servicesDetailsData = ServicesDetailsData.fromJson(data);
              servicesDetailsData.services.clear();
              servicesDetailsData.services.add(Services.fromJson(data));
              detailImages.clear();
              detailImages.addAll(servicesDetailsData.detailImages!);
                          isBookmarked = servicesDetailsData.isBookmarked ?? false;
            });
          }

          vendorIdForPackages = data['vendorId'] is Map
              ? data['vendorId']['_id']?.toString()
              : data['vendorId']?.toString();
          
        }
        

        if (mounted) {
          _fetchVendorPackages(vendorIdForPackages);
        }
      } else {
        if (mounted) {
          CommonWidget.errorShowSnackBarFor(context, jsonData['message'] ?? "Failed to load service details");
          _fetchVendorPackages(null);
        }
      }
      
      // Clear loading state
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
        if (e is TimeoutException) {
          CommonWidget.errorShowSnackBarFor(context, "Request timed out. Please check your connection and try again.");
        } else {
          CommonWidget.errorShowSnackBarFor(context, "Error loading service details: ${e.toString()}");
        }
      }
    }
  }

  Future<void> _fetchVendorPackages(String? vendorId) async {
    if (vendorId == null || vendorId.isEmpty) {
      setState(() {
        servicesDetailsData.packages.clear();
        _packagesError = null;
        _lastFetchedVendorId = null;
        _isLoadingPackages = false;
      });
      return;
    }

    if (dataManager == null) return;
    if (_isLoadingPackages && vendorId == _lastFetchedVendorId) {
      return;
    }

    setState(() {
      _isLoadingPackages = true;
      _packagesError = null;
      _lastFetchedVendorId = vendorId;
    });

    try {
      final response = await dataManager!.getVendorPackages(context, vendorId);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == "success") {
          final packages = mapPackagesForDisplay(jsonData['data']);
          if (!mounted) return;
          setState(() {
            servicesDetailsData.packages
              ..clear()
              ..addAll(packages);
            _isLoadingPackages = false;
            _packagesError = null;
          });
        } else {
          if (!mounted) return;
          setState(() {
            servicesDetailsData.packages.clear();
            _isLoadingPackages = false;
            _packagesError = jsonData['message']?.toString() ?? "Failed to load packages";
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          servicesDetailsData.packages.clear();
          _isLoadingPackages = false;
          _packagesError = "Server responded with ${response.statusCode}";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        servicesDetailsData.packages.clear();
        _isLoadingPackages = false;
        _packagesError = e.toString();
      });
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      if (isBookmarked) {
        // Remove bookmark
        var response = await bookmarkDataManager!.removeBookmark(context, servicesDetailsData.sId ?? "");
        var data = jsonDecode(response.body);
        if (data['status'] == "success") {
          setState(() {
            isBookmarked = false;
          });
          CommonWidget.successShowSnackBarFor(context, "Removed from bookmarks");
        } else {
          CommonWidget.errorShowSnackBarFor(context, data['message'] ?? "Failed to remove bookmark");
        }
      } else {
        // Add bookmark
        var response = await bookmarkDataManager!.postBookmark(context, servicesDetailsData.sId ?? "");
        var data = jsonDecode(response.body);
        if (data['status'] == "success") {
          setState(() {
            isBookmarked = true;
          });
          CommonWidget.successShowSnackBarFor(context, "Added to bookmarks");
        } else {
          CommonWidget.errorShowSnackBarFor(context, data['message'] ?? "Failed to add bookmark");
        }
      }
    } catch (e) {
      CommonWidget.errorShowSnackBarFor(context, "Error updating bookmark");
    }
  }
}
