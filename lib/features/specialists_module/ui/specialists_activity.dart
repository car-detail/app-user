import 'dart:convert';

import 'package:car_app/Common/Color.dart';
import 'package:car_app/features/home_module/model/services_model_data.dart';
import 'package:flutter/material.dart';
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
  String? _packagesError;
  String? _lastFetchedVendorId;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    start();
  }

  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataManager = SpecialistsDataManager(sharedPreferences!);
    bookmarkDataManager = CategoriesListDataManager(sharedPreferences!);
    getServicesDetails(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Collapsible Header with Image
          _buildCollapsibleHeader(context),
          // Content
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Info Card
                  _buildServiceInfoCard(context),
                  const SizedBox(height: 16),
                  // Quick Info Cards
                  _buildQuickInfoCards(context),
                  const SizedBox(height: 16),
                  // Navigation Tabs
                  _buildNavigationTabs(context),
                  const SizedBox(height: 16),
                  // About Section
                  _buildAboutSection(context),
                  const SizedBox(height: 16),
                  // Vendor Info Card
                  _buildVendorInfoCard(context),
                  const SizedBox(height: 16),
                  // Services Section
                  _buildServicesSection(context),
                  const SizedBox(height: 16),
                  // Packages Section - only show if vendor has packages
                  _buildPackagesSection(context),
                  if (_hasVendorPackages()) const SizedBox(height: 16),
                  // Gallery Section
                  if (detailImages.isNotEmpty) _buildGallerySection(context),
                  const SizedBox(height: 16),
                  // Offers Section
                  if ((servicesDetailsData.offers ?? []).isNotEmpty) _buildOffersSection(context),
                  const SizedBox(height: 16),
                  // Reviews Section
                  _buildReviewsSection(context),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      // Enhanced Book Now Button
      bottomNavigationBar: _buildBookNowButton(context),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.4,
      child: Stack(
        children: [
          // Cover Image
          if (servicesDetailsData.coverImage != "" && servicesDetailsData.coverImage != null)
            GestureDetector(
              onTap: () {
                CommonWidget.navigateToScreen(
                  context,
                  ZoomableImageList(imageUrls: [servicesDetailsData.coverImage ?? ""])
                );
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: Image.network(
                  servicesDetailsData.coverImage ?? "",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultCoverImage();
                  },
                ),
              ),
            )
          else
            _buildDefaultCoverImage(),
          
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
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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
                    servicesDetailsData.categoryName ?? "Car Service",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: "Pop500",
                    ),
                  ),
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
                        offset: Offset(0, 1),
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
                      Icon(Icons.location_on, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          servicesDetailsData.location?.name ?? "",
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
              ],
            ),
          ),
        ],
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

  Widget _buildCollapsibleHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.sizeOf(context).height * 0.4,
      floating: false,
      pinned: true,
      backgroundColor: ColorClass.base_color,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Cover Image
            if (servicesDetailsData.coverImage != "" && servicesDetailsData.coverImage != null)
              GestureDetector(
                onTap: () {
                  CommonWidget.navigateToScreen(
                    context,
                    ZoomableImageList(imageUrls: [servicesDetailsData.coverImage ?? ""])
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Image.network(
                    servicesDetailsData.coverImage ?? "",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultCoverImage();
                    },
                  ),
                ),
              )
            else
              _buildDefaultCoverImage(),
            
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
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ColorClass.base_color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      servicesDetailsData.categoryName ?? "Car Service",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: "Pop500",
                      ),
                    ),
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
                          offset: Offset(0, 1),
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
                        Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            servicesDetailsData.location?.name ?? "",
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
                ],
              ),
            ),
          ],
        ),
      ),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
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
          Row(
            children: [
              Icon(Icons.info_outline, color: ColorClass.base_color, size: 20),
              const SizedBox(width: 8),
              Text(
                "Service Details",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (servicesDetailsData.averageRating != 0) ...[
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${servicesDetailsData.averageRating.toString()} Rating",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Pop500",
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${servicesDetailsData.totalReviews.toString()} Reviews",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Pop500",
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (servicesDetailsData.price != null && servicesDetailsData.price! > 0) ...[
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Starting from \$${servicesDetailsData.price}",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Pop500",
                      color: Colors.green[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (servicesDetailsData.serviceDuration != null) ...[
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  "Duration: ${servicesDetailsData.serviceDuration}",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: "Pop500",
                    color: Colors.blue[600],
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
            icon: Icons.verified,
            title: "Verified",
            subtitle: "Trusted Service",
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.schedule,
            title: "Available",
            subtitle: "Book Now",
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.location_on,
            title: "Nearby",
            subtitle: "Quick Access",
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontFamily: "Pop600",
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontFamily: "Pop400",
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTabs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton("About", Icons.info_outline, true),
          ),
          Expanded(
            child: _buildTabButton("Gallery", Icons.photo_library, false),
          ),
          if (servicesDetailsData.offers.isNotEmpty)
            Expanded(
              child: _buildTabButton("Offers", Icons.local_offer, false),
            ),
          Expanded(
            child: _buildTabButton("Reviews", Icons.star, false),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // Handle tab selection
        if (title == "Gallery") {
          CommonWidget.navigateToScreen(
            context,
            ZoomableImageList(imageUrls: detailImages, currentIndex: 0)
          );
        } else if (title == "Offers") {
          CommonWidget.navigateToScreen(
            context,
            OfferListWidget(servicesDetailsData.offers ?? [])
          );
        } else if (title == "Reviews") {
          CommonWidget.navigateToScreen(
            context,
            RatingReviewScreen(servicesDetailsData)
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? ColorClass.base_color : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontFamily: "Pop500",
                color: isSelected ? ColorClass.base_color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Icon(Icons.description, color: ColorClass.base_color, size: 20),
              const SizedBox(width: 8),
              Text(
                "About This Service",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            servicesDetailsData.about ?? "No description available for this service.",
            style: TextStyle(
              fontSize: 16,
              fontFamily: "Pop400",
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorInfoCard(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Icon(Icons.business, color: ColorClass.base_color, size: 20),
              const SizedBox(width: 8),
              Text(
                "Service Provider",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                              color: ColorClass.base_color,
                              size: 30,
                            );
                          },
                        )
                      : Icon(
                          Icons.local_car_wash,
                          color: ColorClass.base_color,
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
                      style: TextStyle(
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
                        print(e);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.phone,
                        color: Colors.green[600],
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
          Row(
            children: [
              Icon(Icons.build_circle, color: ColorClass.base_color, size: 20),
              const SizedBox(width: 8),
              Text(
                "Available Services",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Service Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorClass.base_color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorClass.base_color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_car_wash, color: ColorClass.base_color, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            servicesDetailsData.serviceTitle ?? "Car Service",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: "Pop600",
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            servicesDetailsData.categoryName ?? "Car Wash",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: "Pop400",
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (servicesDetailsData.price != null && servicesDetailsData.price! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "\$${servicesDetailsData.price}",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Pop600",
                            color: Colors.green[600],
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
                      Icon(Icons.access_time, color: Colors.blue[600], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Duration: ${servicesDetailsData.serviceDuration}",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: "Pop400",
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                // Time Slot Capacity
                if (servicesDetailsData.timeSlotCapacity != null) ...[
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.orange[600], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Capacity: ${servicesDetailsData.timeSlotCapacity} customers per slot",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Pop400",
                            color: Colors.orange[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                // Service Description
                if (servicesDetailsData.about != null && servicesDetailsData.about!.isNotEmpty) ...[
                  const SizedBox(height: 8),
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
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Additional Services Info
          Row(
            children: [
              Expanded(
                child: _buildServiceInfoItem(
                  icon: Icons.star,
                  title: "Rating",
                  value: servicesDetailsData.averageRating != 0 
                      ? "${servicesDetailsData.averageRating.toString()} ⭐"
                      : "No ratings yet",
                  color: Colors.amber[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildServiceInfoItem(
                  icon: Icons.people,
                  title: "Reviews",
                  value: "${servicesDetailsData.totalReviews ?? 0} reviews",
                  color: Colors.blue[600]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildServiceInfoItem(
                  icon: Icons.location_on,
                  title: "Location",
                  value: servicesDetailsData.location?.name ?? "Location not available",
                  color: Colors.green[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildServiceInfoItem(
                  icon: Icons.verified,
                  title: "Status",
                  value: servicesDetailsData.isActive == true ? "Active" : "Inactive",
                  color: servicesDetailsData.isActive == true ? Colors.green[600]! : Colors.red[600]!,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontFamily: "Pop500",
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontFamily: "Pop400",
              color: color,
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
    if (_isLoadingPackages && servicesDetailsData.packages.isEmpty) {
      return Container(
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
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_packagesError != null && servicesDetailsData.packages.isEmpty) {
      return Container(
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
            Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.purple[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  "Service Packages",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: "Pop600",
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _packagesError ?? "Unable to load packages",
              style: TextStyle(
                fontSize: 14,
                fontFamily: "Pop400",
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Pull to refresh or try again later.",
              style: TextStyle(
                fontSize: 12,
                fontFamily: "Pop400",
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    bool hasPackages = _hasVendorPackages();

    if (!hasPackages) {
      return const SizedBox.shrink();
    }

    return Container(
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
          Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.purple[600], size: 20),
              const SizedBox(width: 8),
              Text(
                "Service Packages",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Available",
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: "Pop500",
                    color: Colors.purple[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...servicesDetailsData.packages.map((package) => _buildVendorPackageCard(package)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              CommonWidget.navigateToScreen(
                context,
                AllPackagesScreen(
                  vendorId: servicesDetailsData.vendorId?.sId ?? '',
                  vendorName: servicesDetailsData.vendorId?.displayName ?? 'Vendor',
                  initialPackages: List<Map<String, dynamic>>.from(servicesDetailsData.packages),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, color: Colors.purple[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "View All Packages",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Pop500",
                      color: Colors.purple[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios, color: Colors.purple[600], size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorPackageCard(Map<String, dynamic> package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.2),
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2, color: Colors.purple[600], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package['title'] ?? 'Service Package',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "Pop600",
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      package['description'] ?? 'Package description',
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
                    package['price'] != null ? "₹${package['price']}" : "Price TBD",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: "Pop600",
                      color: Colors.purple[600],
                    ),
                  ),
                  Text(
                    package['duration'] ?? "Duration TBD",
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
          if (package['features'] != null && package['features'] is List) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: (package['features'] as List).map((feature) => _buildFeatureChip(feature.toString(), Colors.purple[600]!)).toList(),
            ),
          ],
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
                      style: TextStyle(
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
            children: features.map((feature) => _buildFeatureChip(feature, color)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String feature, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        feature,
        style: TextStyle(
          fontSize: 12,
          fontFamily: "Pop400",
          color: color,
        ),
      ),
    );
  }

  Widget _buildGallerySection(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Icon(Icons.photo_library, color: ColorClass.base_color, size: 20),
              const SizedBox(width: 8),
              Text(
                "Gallery",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
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
                    margin: const EdgeInsets.only(right: 12),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        detailImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image,
                            color: Colors.grey[400],
                            size: 40,
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
    return Container(
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
          Row(
            children: [
              Icon(Icons.local_offer, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Text(
                "Special Offers & Deals",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${servicesDetailsData.offers.length} offers",
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: "Pop500",
                    color: Colors.orange[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if ((servicesDetailsData.offers ?? []).isNotEmpty) ...[
            // Show first few offers as preview
            ...(servicesDetailsData.offers ?? []).where((offer) => offer != null).take(2).map((offer) => _buildOfferPreviewCard(offer)),
            if ((servicesDetailsData.offers ?? []).length > 2) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  CommonWidget.navigateToScreen(
                    context,
                    AllOffersScreen(
                      vendorId: servicesDetailsData.vendorId?.sId ?? '',
                      vendorName: servicesDetailsData.vendorId?.displayName ?? 'Vendor',
                      offers: (servicesDetailsData.offers ?? []).cast<Map<String, dynamic>>(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "View All ${servicesDetailsData.offers.length} Offers",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: "Pop500",
                          color: Colors.orange[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, color: Colors.orange[600], size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            // No offers available
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.local_offer_outlined, color: Colors.grey[400], size: 48),
                  const SizedBox(height: 12),
                  Text(
                    "No Special Offers Available",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Pop500",
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Check back later for exciting deals!",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: "Pop400",
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfferPreviewCard(Offers offer) {
    // Add null safety check
    if (offer == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.local_offer, color: Colors.orange[600], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title ?? "Special Offer",
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: "Pop600",
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offer.description ?? "Limited time offer",
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: "Pop400",
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (offer.discount != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${offer.discount ?? 0}% OFF",
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: "Pop600",
                  color: Colors.red[600],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber[600], size: 20),
              const SizedBox(width: 8),
              Text(
                "Customer Reviews",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "Pop600",
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              CommonWidget.navigateToScreen(
                context,
                RatingReviewScreen(servicesDetailsData),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Read Customer Reviews",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: "Pop500",
                            color: Colors.amber[600],
                          ),
                        ),
                        if (servicesDetailsData.totalReviews != null && servicesDetailsData.totalReviews! > 0)
                          Text(
                            "${servicesDetailsData.totalReviews} reviews available",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: "Pop400",
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.amber[600], size: 16),
                ],
              ),
            ),
          ),
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
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorClass.base_color, ColorClass.base_color.withOpacity(0.8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ColorClass.base_color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Book This Service",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: "Pop600",
                    ),
                  ),
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
      print("🔍 Getting service details for ID: ${widget.servicesData}");
      
      var response = await dataManager!
          .getServiceDetails(context, widget.servicesData);
      
      print("🔍 Service Details API Response: ${response.statusCode} - ${response.body}");
      
      // Check if response is valid
      if (response.statusCode != 200) {
        print("❌ API returned error status: ${response.statusCode}");
        CommonWidget.errorShowSnackBarFor(context, "API returned error status: ${response.statusCode}");
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
            
            setState(() {
              servicesDetailsData = ServicesDetailsData.fromJson(firstService);
              servicesDetailsData.services.clear();
              servicesDetailsData.services.addAll(data.map((service) => Services.fromJson(service)).toList());
              detailImages.clear();
              if (servicesDetailsData.detailImages != null) {
                detailImages.addAll(servicesDetailsData.detailImages!);
              }
              isBookmarked = servicesDetailsData.isBookmarked ?? false;
            });

            vendorIdForPackages = firstService['vendorId'] is Map
                ? firstService['vendorId']['_id']?.toString()
                : firstService['vendorId']?.toString();
            
            print("✅ Vendor services loaded successfully (${data.length} services)");
          } else {
            CommonWidget.errorShowSnackBarFor(context, "No services found for this vendor");
            return;
          }
        } else {
          // This is a single service details response
          setState(() {
            servicesDetailsData = ServicesDetailsData.fromJson(data);
            servicesDetailsData.services.clear();
            servicesDetailsData.services.add(Services.fromJson(data));
            detailImages.clear();
            if (servicesDetailsData.detailImages != null) {
              detailImages.addAll(servicesDetailsData.detailImages!);
            }
            isBookmarked = servicesDetailsData.isBookmarked ?? false;
          });

          vendorIdForPackages = data['vendorId'] is Map
              ? data['vendorId']['_id']?.toString()
              : data['vendorId']?.toString();
          
          print("✅ Service details loaded successfully");
        }
        
        print("🔍 Service Title: ${servicesDetailsData.serviceTitle}");
        print("🔍 Category Name: ${servicesDetailsData.categoryName}");
        print("🔍 Price: ${servicesDetailsData.price}");
        print("🔍 Rating: ${servicesDetailsData.averageRating}");
        print("🔍 Reviews: ${servicesDetailsData.totalReviews}");

        _fetchVendorPackages(vendorIdForPackages);
      } else {
        print("❌ API returned error: ${jsonData['message']}");
        CommonWidget.errorShowSnackBarFor(context, jsonData['message'] ?? "Failed to load service details");
        _fetchVendorPackages(null);
      }
    } catch (e) {
      print("❌ Error in getServicesDetails: $e");
      CommonWidget.errorShowSnackBarFor(context, "Error loading service details: ${e.toString()}");
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
      print("❌ Error loading packages: $e");
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
      print('Error toggling bookmark: $e');
      CommonWidget.errorShowSnackBarFor(context, "Error updating bookmark");
    }
  }
}
