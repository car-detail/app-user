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
import '../../log_in/ui/new_login_activity.dart';
import '../../../Common/Constant.dart';
import '../../rating_model/ui/rating_review_screen.dart';
import '../../categories_module/data_manager/categories_list_data_manager.dart';
import '../data_manager/specialists_data_manager.dart';
import '../model/services_details_model_data.dart';
import 'offer_list_widget.dart';
import 'all_packages_screen.dart';
import 'all_offers_screen.dart';
import '../utils/package_mapper.dart';
import '../../../design_system/components/bouncy_tap.dart';

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
  String? _currentServiceId;
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
    _currentServiceId = widget.servicesData;
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
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
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
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
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
                  // Offline Status Banner
                  if (servicesDetailsData.vendorId?.isShopOpen == false) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Vendor is currently Offline",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: "Pop600",
                                    color: Colors.red[700],
                                  ),
                                ),
                                Text(
                                  "You can still book for future dates.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: "Pop400",
                                    color: Colors.red[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Vendor Hero Card -- identity, rating, price and contact in one place
                  _buildVendorHeroCard(context),
                  const SizedBox(height: 16),
                  // Navigation Tabs
                  _buildNavigationTabs(context),
                  const SizedBox(height: 16),
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


  Widget _buildCollapsibleHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.sizeOf(context).height * 0.4,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0D1116),
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
                
                // Add all detail images to the list
                if (servicesDetailsData.detailImages.isNotEmpty) {
                  for (var img in servicesDetailsData.detailImages) {
                    if (!images.contains(img)) images.add(img);
                  }
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


  Widget _buildNavigationTabs(BuildContext context) {
    // Build list of available tabs based on content
    List<Map<String, dynamic>> availableTabs = [
      {"title": "About", "icon": Icons.info_rounded, "key": "About"},
    ];
    
    if (servicesDetailsData.services.isNotEmpty) {
      availableTabs.add({"title": "Services", "icon": Icons.build_circle_rounded, "key": "Services"});
    }
    
    availableTabs.add({"title": "Packages", "icon": Icons.inventory_2_rounded, "key": "Packages"});
    
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
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: availableTabs.map((tab) {
          final isSelected = selectedTab == tab["key"];
          return Expanded(
            child: _buildTabButton(
              tab["title"] as String,
              tab["icon"] as IconData,
              isSelected,
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF0D1116), Color(0xFF192028)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF192028).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[500],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontFamily: isSelected ? "Pop600" : "Pop400",
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    switch (selectedTab) {
      case "About":
        final activeOffers = (servicesDetailsData.offers ?? [])
            .where((offer) => offer.isCurrentlyActive == true)
            .toList();
        return Column(
          children: [
            _buildAboutSection(context),
            const SizedBox(height: 10),
            if (activeOffers.isNotEmpty) ...[
              _buildOffersSection(context),
              const SizedBox(height: 10),
            ],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            "About",
            Icons.description_rounded,
            [ColorClass.base_color, const Color(0xFF0D1116)],
          ),
          const SizedBox(height: 14),
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

  // Shared colorful section header used across tab content (About, Services,
  // Packages, Offers, Gallery, Reviews) so every tab reads consistently
  // instead of each having its own slightly-different flat grey header.
  Widget _buildSectionHeader(String title, IconData icon, List<Color> gradient, {String? badge}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontFamily: "Pop600",
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: gradient.first.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: TextStyle(fontSize: 11, fontFamily: "Pop600", color: gradient.last),
            ),
          ),
        ],
      ],
    );
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

  Widget _buildVendorHeroCard(BuildContext context) {
    final hasRating = servicesDetailsData.averageRating != 0;
    final hasPrice = servicesDetailsData.price != null && servicesDetailsData.price! > 0;
    final hasDuration = servicesDetailsData.serviceDuration != null;

    return Container(
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
            // Gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D1116), Color(0xFF192028)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Text(
                    "Service Provider",
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: "Pop600",
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Vendor Avatar with ring
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF192028), Color(0xFF0D1116)],
                          ),
                        ),
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[100],
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipOval(
                            child: servicesDetailsData.vendorId?.displayPicture != null &&
                                    servicesDetailsData.vendorId!.displayPicture!.isNotEmpty
                                ? Image.network(
                                    servicesDetailsData.vendorId!.displayPicture!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.local_car_wash, color: Colors.grey[500], size: 28);
                                    },
                                  )
                                : Icon(Icons.local_car_wash, color: Colors.grey[500], size: 28),
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
                                fontFamily: "Pop700",
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF192028).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, color: Color(0xFF192028), size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        "Verified Pro",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: "Pop500",
                                          color: Color(0xFF192028),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildCategoriesChips(),
                          ],
                        ),
                      ),
                      // Call button
                      GestureDetector(
                        onTap: () async {
                          // Guest guard
                          final String userId = sharedPreferences?.getString(Constant.id) ?? "";
                          if (userId.isEmpty) {
                            _showLoginRequiredDialog(context, "Sign in to call this vendor.");
                            return;
                          }
                          final raw = servicesDetailsData.vendorId?.mobile?.trim();
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
                            final Uri phoneUri = Uri.parse('tel:$phone');
                            if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
                            } else {
                              if (mounted) CommonWidget.errorShowSnackBarFor(context, 'Cannot open phone dialer');
                            }
                          } catch (e) {
                            if (mounted) CommonWidget.errorShowSnackBarFor(context, 'Could not start call');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF192028), Color(0xFF0D1116)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF192028).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  if (hasRating || hasPrice || hasDuration) ...[
                    const SizedBox(height: 16),
                    Container(height: 1, color: Colors.grey[200]),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (hasRating) ...[
                          Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            servicesDetailsData.averageRating?.toStringAsFixed(1) ?? '0.0',
                            style: const TextStyle(fontSize: 13, fontFamily: "Pop600", color: Colors.black87),
                          ),
                          Text(
                            " (${servicesDetailsData.totalReviews})",
                            style: TextStyle(fontSize: 12, fontFamily: "Pop400", color: Colors.grey[600]),
                          ),
                        ],
                        if (hasRating && (hasPrice || hasDuration)) ...[
                          const SizedBox(width: 12),
                          Container(width: 1, height: 14, color: Colors.grey[300]),
                          const SizedBox(width: 12),
                        ],
                        if (hasPrice) ...[
                          Text(
                            "From \$${servicesDetailsData.price}",
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: "Pop600",
                              color: ColorClass.base_color,
                            ),
                          ),
                        ],
                        if (hasPrice && hasDuration) ...[
                          const SizedBox(width: 12),
                          Container(width: 1, height: 14, color: Colors.grey[300]),
                          const SizedBox(width: 12),
                        ],
                        if (hasDuration) ...[
                          Icon(Icons.access_time_rounded, color: Colors.grey[500], size: 14),
                          const SizedBox(width: 4),
                          Text(
                            servicesDetailsData.serviceDuration ?? "",
                            style: TextStyle(fontSize: 12, fontFamily: "Pop400", color: Colors.grey[700]),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (_hasOperatingHours()) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.schedule_rounded, color: Color(0xFF0EA5E9), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatOperatingHours(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: "Pop600",
                                    color: Colors.black87,
                                  ),
                                ),
                                if (_formatOperatingDays() != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatOperatingDays()!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: "Pop400",
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
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasOperatingHours() {
    final open = servicesDetailsData.vendorId?.openTime;
    final close = servicesDetailsData.vendorId?.closeTime;
    return (open != null && open.isNotEmpty) || (close != null && close.isNotEmpty);
  }

  /// Formats a time value that may be a plain "9:00 AM" string or a full
  /// ISO datetime (backend stores hours as a datetime with a dummy date,
  /// e.g. "2026-07-07T16:00:00.000Z") into a clean "4:00 PM" display.
  /// Reads the UTC-labeled hour/minute directly rather than converting to
  /// the device's local timezone, since the date component is a dummy
  /// placeholder and not a real calendar date to localize against.
  String _formatTimeValue(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final hour24 = parsed.hour;
    final minute = parsed.minute;
    final period = hour24 >= 12 ? "PM" : "AM";
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minuteStr = minute.toString().padLeft(2, '0');
    return "$hour12:$minuteStr $period";
  }

  String _formatOperatingHours() {
    final open = servicesDetailsData.vendorId?.openTime;
    final close = servicesDetailsData.vendorId?.closeTime;
    if (open != null && open.isNotEmpty && close != null && close.isNotEmpty) {
      return "${_formatTimeValue(open)} - ${_formatTimeValue(close)}";
    }
    if (open != null && open.isNotEmpty) return "Opens ${_formatTimeValue(open)}";
    if (close != null && close.isNotEmpty) return "Closes ${_formatTimeValue(close)}";
    return "Hours not available";
  }

  String? _formatOperatingDays() {
    final days = servicesDetailsData.vendorId?.daysAvailable;
    if (days == null || days.isEmpty) return null;

    const order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const abbrev = {
      'Monday': 'Mon', 'Tuesday': 'Tue', 'Wednesday': 'Wed', 'Thursday': 'Thu',
      'Friday': 'Fri', 'Saturday': 'Sat', 'Sunday': 'Sun',
    };
    final sorted = days.toSet().toList()
      ..sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));

    if (sorted.length == 7) return "Open every day";

    // Collapse a consecutive run into "Mon - Fri" style ranges.
    final labels = <String>[];
    int i = 0;
    while (i < sorted.length) {
      int j = i;
      while (j + 1 < sorted.length && order.indexOf(sorted[j + 1]) == order.indexOf(sorted[j]) + 1) {
        j++;
      }
      if (j > i) {
        labels.add("${abbrev[sorted[i]] ?? sorted[i]} - ${abbrev[sorted[j]] ?? sorted[j]}");
      } else {
        labels.add(abbrev[sorted[i]] ?? sorted[i]);
      }
      i = j + 1;
    }
    return labels.join(', ');
  }

  Widget _buildServicesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            "Available Services",
            Icons.build_circle_rounded,
            const [Color(0xFF3B82F6), Color(0xFF2563EB)],
            badge: "${servicesDetailsData.services.length}",
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
            
            bool isSelected = service.sId == _currentServiceId;
            
            return GestureDetector(
              onTap: () => _onServiceSelected(service),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? ColorClass.base_color.withOpacity(0.05) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? ColorClass.base_color : Colors.grey[200]!,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.serviceTitle ?? service.categoryName ?? "Service",
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: "Pop600",
                              color: isSelected ? ColorClass.base_color : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: ColorClass.base_color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "Selected",
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: "Pop600",
                                color: ColorClass.base_color,
                              ),
                            ),
                          ),
                        if (service.price != null && service.price! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? ColorClass.base_color : ColorClass.base_color.withOpacity(0.8),
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
              ),
            );
          }),
          // Service Details Card with Image
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Image with title/category overlaid on a gradient + floating price badge
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildServiceHeroImage(),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.55),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                        if (servicesDetailsData.price != null && servicesDetailsData.price! > 0)
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF192028), Color(0xFF0D1116)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
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
                          ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ColorClass.base_color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  servicesDetailsData.categoryName ?? "Car Wash",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: "Pop500",
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                servicesDetailsData.serviceTitle ?? "Car Service",
                                style: TextStyle(
                                  fontSize: 19,
                                  fontFamily: "Pop600",
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 4,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Service Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Duration / Capacity chips
                      if (servicesDetailsData.serviceDuration != null || servicesDetailsData.timeSlotCapacity != null)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (servicesDetailsData.serviceDuration != null)
                              _buildMetaChip(Icons.access_time_rounded, "${servicesDetailsData.serviceDuration}", const Color(0xFF0EA5E9)),
                            if (servicesDetailsData.timeSlotCapacity != null)
                              _buildMetaChip(Icons.people_rounded, "${servicesDetailsData.timeSlotCapacity} per slot", const Color(0xFFF59E0B)),
                          ],
                        ),
                      if (servicesDetailsData.serviceDuration != null || servicesDetailsData.timeSlotCapacity != null)
                        const SizedBox(height: 12),
                      // Service Description
                      if (servicesDetailsData.about != null && servicesDetailsData.about!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
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
                  color: servicesDetailsData.isActive == true ? ColorClass.base_color : Colors.grey[700]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceHeroImage() {
    final coverImage = servicesDetailsData.coverImage;
    if (coverImage != null && coverImage.isNotEmpty) {
      return Image.network(
        coverImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildServiceHeroImageFallback(),
      );
    }
    final vendorImage = servicesDetailsData.vendorId?.displayPicture;
    if (vendorImage != null && vendorImage.isNotEmpty) {
      return Image.network(
        vendorImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildServiceHeroImageFallback(),
      );
    }
    return _buildServiceHeroImageFallback();
  }

  Widget _buildServiceHeroImageFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorClass.base_color.withOpacity(0.8), ColorClass.base_color.withOpacity(0.6)],
        ),
      ),
      child: const Icon(Icons.local_car_wash_rounded, color: Colors.white, size: 48),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontFamily: "Pop500", color: color),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.10), color.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontFamily: "Pop500",
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: "Pop600",
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            "Service Packages",
            Icons.inventory_2_rounded,
            const [Color(0xFFF59E0B), Color(0xFFD97706)],
            badge: "${servicesDetailsData.packages.length}",
          ),
          const SizedBox(height: 14),
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

    // Price calculations for conditional display
    final double pVal = double.tryParse(price?.toString() ?? '0') ?? 0;
    final double sVal = double.tryParse(smallVehiclePrice?.toString() ?? '0') ?? 0;
    final double lVal = double.tryParse(largeVehiclePrice?.toString() ?? '0') ?? 0;
    final bool hasAnyPrice = pVal > 0 || sVal > 0 || lVal > 0;

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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF59E0B), Color(0xFFDC2626)],
                  ),
                ),
                child: coverImage != null && coverImage.toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Image.network(
                          coverImage.toString(),
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  right: -10,
                                  bottom: -14,
                                  child: Icon(
                                    Icons.card_giftcard_rounded,
                                    color: Colors.white.withOpacity(0.18),
                                    size: 130,
                                  ),
                                ),
                                Icon(Icons.card_giftcard_rounded, color: Colors.white.withOpacity(0.9), size: 48),
                              ],
                            );
                          },
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            right: -10,
                            bottom: -14,
                            child: Icon(
                              Icons.card_giftcard_rounded,
                              color: Colors.white.withOpacity(0.18),
                              size: 130,
                            ),
                          ),
                          Icon(Icons.card_giftcard_rounded, color: Colors.white.withOpacity(0.9), size: 48),
                        ],
                      ),
              ),
              // Gradient Overlay
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.45),
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
                if (hasAnyPrice)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFDC2626)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.attach_money_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (sVal > 0 && lVal > 0) ...[
                                Text(
                                  "Small Vehicle: \$$sVal",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Large Vehicle: \$$lVal",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ] else if (pVal > 0) ...[
                                Text(
                                  "\$$pVal",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: "Pop600",
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Gallery",
          Icons.photo_library_rounded,
          const [Color(0xFFA855F7), Color(0xFF7C3AED)],
          badge: "${detailImages.length} photo${detailImages.length == 1 ? '' : 's'}",
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final tileWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(detailImages.length, (index) {
                return BouncyTap(
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
                    width: tileWidth,
                    height: tileWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.grey[100],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            detailImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image_rounded,
                                color: Colors.grey[400],
                                size: 32,
                              );
                            },
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            "Special Offers",
            Icons.local_offer_rounded,
            const [Color(0xFFEF4444), Color(0xFFDC2626)],
            badge: "${activeOffers.length}",
          ),
          const SizedBox(height: 14),
          // Show only active offers (isCurrentlyActive == true)
          ...activeOffers.map((offer) => _buildOfferPreviewCard(offer)),
        ],
      ),
    );
  }

  Widget _buildOfferDecorativeBackground() {
    return Stack(
      children: [
        Positioned(
          right: -16,
          top: -10,
          child: Icon(Icons.local_offer_rounded, color: Colors.white.withOpacity(0.14), size: 110),
        ),
        Positioned(
          left: 30,
          bottom: -24,
          child: Icon(Icons.local_offer_rounded, color: Colors.white.withOpacity(0.10), size: 70),
        ),
        Center(
          child: Icon(Icons.local_offer_rounded, color: Colors.white.withOpacity(0.9), size: 42),
        ),
      ],
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
    
    // Find the service associated with this offer to get category name
    String? categoryName;
    if (serviceId != null && serviceId.isNotEmpty && servicesDetailsData.services.isNotEmpty) {
      final service = servicesDetailsData.services.firstWhere(
        (s) => s.sId == serviceId,
        orElse: () => servicesDetailsData.services.first,
      );
      categoryName = service.categoryName;
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                height: 170,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF97316), Color(0xFFDC2626)],
                  ),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 170,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildOfferDecorativeBackground(),
                        ),
                      )
                    : _buildOfferDecorativeBackground(),
              ),
              // Gradient Overlay
              Container(
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              // Discount / Offer Badge - Top Left
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        discount != null && discount > 0 ? Icons.percent_rounded : Icons.local_offer_rounded,
                        color: const Color(0xFFDC2626),
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        discount != null && discount > 0 ? "$discount% OFF" : "Limited Offer",
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Pop600",
                          letterSpacing: 0.3,
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offerTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Pop700",
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (categoryName != null && categoryName.isNotEmpty) ...[
                        const SizedBox(height: 8),
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
    final hasReviews = servicesDetailsData.totalReviews != null && servicesDetailsData.totalReviews! > 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            "Customer Reviews",
            Icons.star_rounded,
            const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
            badge: hasReviews ? "${servicesDetailsData.totalReviews}" : null,
          ),
          const SizedBox(height: 14),
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
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          final String userId = sharedPreferences?.getString(Constant.id) ?? "";
          if (userId.isEmpty) {
            _showLoginRequiredDialog(context, "Sign in to book this service.");
            return;
          }
          CommonWidget.navigateToScreen(
            context,
            BookingActivity(servicesDetailsData.vendorId?.sId ?? widget.servicesData),
          );
        },
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF0D1116),
                Color(0xFF192028),
                Color(0xFF2A3542),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF192028).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "Book This Service",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: "Pop600",
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
            ],
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
                _currentServiceId = servicesDetailsData.sId;
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
          
          // Fetch all services for this vendor — await so Services tab shows all before page renders
          if (vendorIdForPackages != null && vendorIdForPackages.isNotEmpty) {
            await _fetchVendorServices(vendorIdForPackages);
          }
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

  Future<void> _fetchVendorServices(String? vendorId) async {
    if (vendorId == null || vendorId.isEmpty || dataManager == null) return;

    try {
      // Use getServiceDetails with vendor ID to get all services
      // This endpoint v1/services/vendor/$id returns all services for a vendor
      var response = await dataManager!.getServiceDetails(context, vendorId);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == "success" && jsonData['data'] != null) {
          var data = jsonData['data'];
          if (data is List) {
            if (mounted) {
              setState(() {
                // Update the list of available services
                servicesDetailsData.services.clear();
                servicesDetailsData.services.addAll(
                    data.map((service) => Services.fromJson(service)).toList());
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching all vendor services: $e");
    }
  }

  Future<void> _onServiceSelected(Services service) async {
    if (service.sId == null || service.sId == _currentServiceId) return;

    // Save current services and packages to avoid losing them
    List<Services> existingServices = List.from(servicesDetailsData.services);
    List<Map<String, dynamic>> existingPackages = List.from(servicesDetailsData.packages);

    setState(() {
      _currentServiceId = service.sId;
      _isLoadingDetails = true;
      // Optimistically update only known fields from the summary object.
      // Do NOT replace servicesDetailsData via fromJson(service.toJson()) — that
      // serialises vendorId as a plain String which crashes VendorId.fromJson and
      // wipes all vendor data. Instead, patch individual fields directly.
      servicesDetailsData.sId = service.sId;
      servicesDetailsData.serviceTitle = service.serviceTitle;
      servicesDetailsData.price = service.price;
      servicesDetailsData.coverImage = service.coverImage;
      servicesDetailsData.detailImages = service.detailImages ?? [];
      servicesDetailsData.categoryName = service.categoryName;
      servicesDetailsData.services = existingServices;
      servicesDetailsData.packages = existingPackages;
      detailImages.clear();
      detailImages.addAll(servicesDetailsData.detailImages ?? []);
    });

    try {
      // Use service-details endpoint directly — we know sId is a service ID, not vendor ID
      var response = await dataManager!.getServiceDetailsById(context, service.sId!);
      
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == "success" && jsonData['data'] != null) {
          var data = jsonData['data'];
          
          if (mounted) {
            setState(() {
              servicesDetailsData = ServicesDetailsData.fromJson(data);
              
              // Restore lists that are managed at vendor level or persisted
              servicesDetailsData.services = existingServices;
              servicesDetailsData.packages = existingPackages;
              
              detailImages.clear();
              detailImages.addAll(servicesDetailsData.detailImages!);
              isBookmarked = servicesDetailsData.isBookmarked ?? false;
              _isLoadingDetails = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoadingDetails = false);
        }
      } else {
        if (mounted) setState(() => _isLoadingDetails = false);
      }
    } catch (e) {
      debugPrint("Error switching service: $e");
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
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
    final String userId = sharedPreferences?.getString(Constant.id) ?? "";
    if (userId.isEmpty) {
      _showLoginRequiredDialog(context, "Sign in to bookmark this service.");
      return;
    }
    try {
      if (isBookmarked) {
        // Remove bookmark
        var response = await bookmarkDataManager!.removeBookmark(context, servicesDetailsData.sId ?? "");
        if (mounted) {
          var data = jsonDecode(response.body);
          if (data['status'] == "success") {
            setState(() {
              isBookmarked = false;
            });
            CommonWidget.successShowSnackBarFor(context, "Removed from bookmarks");
          } else {
            CommonWidget.errorShowSnackBarFor(context, data['message'] ?? "Failed to remove bookmark");
          }
        }
      } else {
        // Add bookmark
        var response = await bookmarkDataManager!.postBookmark(context, servicesDetailsData.sId ?? "");
        if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        CommonWidget.errorShowSnackBarFor(context, "Error updating bookmark");
      }
    }
  }

  void _showLoginRequiredDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            "Login Required",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => CommonWidget.safePop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: ColorClass.base_color,
              ),
              onPressed: () {
                CommonWidget.safePop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewLoginActivity(returnToPrevious: true),
                  ),
                ).then((value) {
                  if (value == true) {
                    // Do nothing, state should refresh if they try the action again
                  }
                });
              },
              child: const Text("Log In"),
            ),
          ],
        );
      },
    );
  }
}
