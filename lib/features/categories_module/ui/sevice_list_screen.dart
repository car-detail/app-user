import 'package:flutter/material.dart';

import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../home_module/model/services_model_data.dart';
import '../../specialists_module/ui/specialists_activity.dart';

class SeviceListScreen extends StatefulWidget {
  List<dynamic> items; // Can contain both Services and ServicesData
  SeviceListScreen(this.items,{super.key});

  @override
  State<SeviceListScreen> createState() => _SeviceListScreenState();
}

class _SeviceListScreenState extends State<SeviceListScreen> {
  List<dynamic> itemsData = [];
  @override
  void initState() {
    setState(() {
      itemsData = widget.items;
    });
  super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          CommonWidget.gettopbar(
            "Services",
            context,
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: itemsData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.build_circle_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No Services Available",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontFamily: "Pop500",
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Check back later for new services",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              fontFamily: "Pop300",
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: itemsData.length,
                      itemBuilder: (context, index) {
                        return _buildItemCard(context, index);
                      },
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, int index) {
    final item = itemsData[index];
    
    // Check if it's a Service or ServicesData (vendor)
    if (item is Services) {
      return _buildServiceCard(context, item);
    } else if (item is ServicesData) {
      return _buildVendorCard(context, item);
    } else if (item is Map<String, dynamic>) {
      // Handle raw Map data - convert to Services object
      try {
        final service = Services.fromJson(item);
        return _buildServiceCard(context, service);
      } catch (e) {
        return _buildErrorCard("Invalid service data");
      }
    }
    
    // Fallback - show error card
    return _buildErrorCard("Unknown service type: ${item.runtimeType}");
  }
  
  Widget _buildErrorCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[800],
                fontFamily: "Pop400",
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Services service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
                          CommonWidget.navigateToScreen(
                              context,
              SpecialistsActivity(service.sId ?? ''),
            );
                      },
          child: Padding(
            padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                // Service Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: service.coverImage != null && service.coverImage!.isNotEmpty
                        ? Image.network(
                            service.coverImage!,
                            fit: BoxFit.cover,
                            headers: const {
                              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildServiceIcon(service.serviceTitle ?? "");
                            },
                          )
                        : _buildServiceIcon(service.serviceTitle ?? ""),
                  ),
                ),
                const SizedBox(width: 16),
                // Service Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                      // Service Title
                      Text(
                        (service.serviceTitle != null && service.serviceTitle!.isNotEmpty && !service.serviceTitle!.startsWith('{'))
                            ? service.serviceTitle!
                            : (service.categoryName != null && service.categoryName!.isNotEmpty)
                                ? service.categoryName!
                                : "Service",
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: "Pop600",
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Category
                      Text(
                        service.categoryName != null && service.categoryName!.isNotEmpty
                            ? service.categoryName!
                            : "Car Service",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: "Pop400",
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Rating and Price Row
                      Row(
                        children: [
                          // Rating
                          if (service.totalReviews != null && service.totalReviews! > 0) ...[
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "${service.averageRating ?? 0} (${service.totalReviews} reviews)",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: "Pop400",
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Price
                          if (service.price != null && service.price! > 0)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ColorClass.base_color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "\$${service.price}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: "Pop600",
                                    color: ColorClass.base_color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
                                  ],
                                ),
                              ),
        ),
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, ServicesData vendor) {
    // Check if vendor is offline (only for app vendors)
    final isOffline = (vendor.isAppVendor ?? false) && !(vendor.isShopOpen ?? true);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isOffline ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOffline ? Border.all(color: Colors.grey[300]!) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            CommonWidget.navigateToScreen(
              context,
              SpecialistsActivity(vendor.sId ?? ''),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Vendor Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: vendor.displayPicture != null && vendor.displayPicture!.isNotEmpty
                        ? Image.network(
                            vendor.displayPicture!,
                            fit: BoxFit.cover,
                            headers: const {
                              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(ColorClass.base_color),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildVendorIcon();
                            },
                          )
                        : _buildVendorIcon(),
                  ),
                ),
                const SizedBox(width: 16),
                // Vendor Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vendor Name with OFFLINE badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vendor.displayName ?? "",
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: "Pop600",
                                color: isOffline ? Colors.grey[600] : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // OFFLINE badge
                          if (isOffline)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'OFFLINE',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Location
                      Text(
                        vendor.location?.name ?? "Location not available",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: "Pop400",
                          color: isOffline ? Colors.grey[500] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Distance
                      if (vendor.distance != null)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: isOffline ? Colors.grey[500] : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "${(vendor.distance! * 0.000621371).toStringAsFixed(1)} miles away",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: "Pop400",
                                  color: isOffline ? Colors.grey[500] : Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Info Icon
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: ColorClass.base_color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceIcon(String serviceTitle) {
    IconData iconData;
    Color iconColor;
    
    if (serviceTitle.toLowerCase().contains('wash')) {
      iconData = Icons.local_car_wash;
      iconColor = Colors.blue;
    } else if (serviceTitle.toLowerCase().contains('repair')) {
      iconData = Icons.build;
      iconColor = Colors.orange;
    } else if (serviceTitle.toLowerCase().contains('oil')) {
      iconData = Icons.oil_barrel;
      iconColor = Colors.brown;
    } else if (serviceTitle.toLowerCase().contains('brake')) {
      iconData = Icons.disc_full;
      iconColor = Colors.red;
    } else {
      iconData = Icons.directions_car;
      iconColor = ColorClass.base_color;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        size: 40,
        color: iconColor,
      ),
    );
  }

  Widget _buildVendorIcon() {
    return Container(
      decoration: BoxDecoration(
        color: ColorClass.base_color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.local_car_wash,
        size: 40,
        color: ColorClass.base_color,
      ),
    );
  }

  void _showGoogleVendorBottomSheet(BuildContext context, ServicesData vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Vendor Image and Name
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: vendor.displayPicture != null && vendor.displayPicture!.isNotEmpty
                          ? Image.network(
                              vendor.displayPicture!,
                              fit: BoxFit.cover,
                              headers: const {
                                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return _buildVendorIcon();
                              },
                            )
                          : _buildVendorIcon(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.displayName ?? "Unknown Vendor",
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: "Pop600",
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vendor.location?.name ?? "Location not available",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "Pop400",
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (vendor.distance != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${(vendor.distance! * 0.000621371).toStringAsFixed(1)} miles away",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: "Pop400",
                                    color: Colors.grey[600],
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
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to Google Maps
                        _openGoogleMaps(vendor);
                      },
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text(
                        "Navigate",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Pop500",
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorClass.base_color,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Call vendor (if phone number available)
                        _callVendor(vendor);
                      },
                      icon: const Icon(Icons.phone, color: Colors.white),
                      label: const Text(
                        "Call",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Pop500",
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Additional Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "About this location",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "Pop600",
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "This is a Google Places location. You can navigate to this location or call them directly for more information about their services.",
                      style: TextStyle(
                        fontSize: 14,
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
      ),
    );
  }

  void _openGoogleMaps(ServicesData vendor) {
    if (vendor.location?.coordinates != null) {
      final lat = vendor.location!.coordinates!.lat;
      final lng = vendor.location!.coordinates!.long;
      final url = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng";
      // You can use url_launcher here to open the URL
    }
  }

  void _callVendor(ServicesData vendor) {
    // You can implement phone calling functionality here
    // For now, just show a message
  }

  void _showOfflineMessage(BuildContext context) {
    CommonWidget.errorShowSnackBarFor(context, "This vendor is currently offline and not accepting bookings");
  }
}
