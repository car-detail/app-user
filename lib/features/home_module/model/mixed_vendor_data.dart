import 'dart:math';

/// Mixed vendor data that combines app vendors and Google Places vendors
class MixedVendorData {
  final String id;
  final String name;
  final String? address;
  final double? rating;
  final int? reviewCount;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? phone;
  final String? website;
  final bool isOpen;
  double distance;
  final bool isAppVendor;
  final List<String> services;
  final String? category;
  bool isBookmarked;

  MixedVendorData({
    required this.id,
    required this.name,
    this.address,
    this.rating,
    this.reviewCount,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.phone,
    this.website,
    required this.isOpen,
    required this.distance,
    required this.isAppVendor,
    this.services = const [],
    this.category,
    this.isBookmarked = false,
  });

  factory MixedVendorData.fromAppVendor(Map<String, dynamic> vendor) {
    // Extract coordinates from location object or direct lat/lng fields
    double lat = 0;
    double lng = 0;
    
    if (vendor['location'] != null && vendor['location'] is Map) {
      final location = vendor['location'] as Map<String, dynamic>;
      if (location['coordinates'] != null && location['coordinates'] is Map) {
        final coords = location['coordinates'] as Map<String, dynamic>;
        lat = double.tryParse(coords['lat']?.toString() ?? "0") ?? 0;
        lng = double.tryParse(coords['long']?.toString() ?? "0") ?? 0;
      }
    } else {
      lat = double.tryParse(vendor['lat']?.toString() ?? "0") ?? 0;
      lng = double.tryParse(vendor['long']?.toString() ?? "0") ?? 0;
    }
    
    // Extract vendor name - check both vendorId and direct fields
    String vendorName = 'Unknown';
    if (vendor['vendorId'] != null && vendor['vendorId'] is Map) {
      final vendorId = vendor['vendorId'] as Map<String, dynamic>;
      vendorName = vendorId['displayName']?.toString() ?? vendor['serviceTitle']?.toString() ?? 'Unknown';
    } else {
      vendorName = vendor['displayName']?.toString() ?? vendor['serviceTitle']?.toString() ?? 'Unknown';
    }
    
    // Extract address
    String? address;
    if (vendor['location'] != null && vendor['location'] is Map) {
      final location = vendor['location'] as Map<String, dynamic>;
      address = location['name']?.toString();
    }
    address ??= vendor['address']?.toString();
    
    return MixedVendorData(
      id: vendor['_id']?.toString() ?? vendor['sId']?.toString() ?? '',
      name: vendorName,
      address: address,
      rating: double.tryParse(vendor['averageRating']?.toString() ?? "0"),
      reviewCount: int.tryParse(vendor['totalReviews']?.toString() ?? "0"),
      latitude: lat,
      longitude: lng,
      imageUrl: vendor['displayPicture']?.toString() ?? vendor['coverImage']?.toString(),
      phone: vendor['mobile']?.toString(),
      isOpen: (vendor['isActive'] ?? true) && (vendor['isShopOpen'] ?? true),
      distance: 0, // Will be calculated later
      isAppVendor: true,
      services: _extractServices(vendor['services']),
      category: vendor['categoryName']?.toString(),
      isBookmarked: vendor['isBookmarked'] ?? false,
    );
  }

  factory MixedVendorData.fromBackendGoogleVendor(Map<String, dynamic> vendor) {
    print('Google vendor data: $vendor'); // Debug log
    
    // Convert Google Places types to service names
    List<String> services = [];
    if (vendor['services'] != null && vendor['services'] is List) {
      services = (vendor['services'] as List).map((e) => e.toString()).toList();
    }
    
    // If no services from types, use default car services
    if (services.isEmpty) {
      services = ['car_wash', 'car_repair'];
    }
    
    return MixedVendorData(
      id: vendor['_id']?.toString() ?? '',
      name: vendor['displayName']?.toString() ?? '',
      address: vendor['location']?['name']?.toString() ?? '',
      rating: 4.5, // Default rating for Google Places
      reviewCount: 0, // Google Places doesn't provide review count in this format
      latitude: double.tryParse(vendor['location']?['coordinates']?['lat']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(vendor['location']?['coordinates']?['lng']?.toString() ?? '0') ?? 0.0,
      imageUrl: vendor['displayPicture']?.toString(),
      phone: null,
      website: null,
      isOpen: vendor['isShopOpen'] ?? true,
      distance: double.tryParse(vendor['distance']?.toString() ?? '0') ?? 0.0,
      isAppVendor: false,
      services: services,
      category: 'Google Places',
      isBookmarked: vendor['isBookmarked'] ?? false,
    );
  }

  static String _getCategoryFromTypes(List<String> types) {
    if (types.contains('car_wash')) return 'Car Wash';
    if (types.contains('car_repair')) return 'Car Repair';
    if (types.contains('gas_station')) return 'Fuel Station';
    if (types.contains('tire_shop')) return 'Tire Service';
    return 'Car Service';
  }

  /// Calculate distance from user location
  double calculateDistance(double userLat, double userLng) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double lat1Rad = userLat * (3.14159265359 / 180);
    final double lat2Rad = latitude * (3.14159265359 / 180);
    final double deltaLatRad = (latitude - userLat) * (3.14159265359 / 180);
    final double deltaLngRad = (longitude - userLng) * (3.14159265359 / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  /// Static method to calculate distance between two coordinates
  static double calculateDistanceBetween(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double lat1Rad = lat1 * (3.14159265359 / 180);
    final double lat2Rad = lat2 * (3.14159265359 / 180);
    final double deltaLatRad = (lat2 - lat1) * (3.14159265359 / 180);
    final double deltaLngRad = (lng2 - lng1) * (3.14159265359 / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  /// Safely extract services from vendor data
  static List<String> _extractServices(dynamic servicesData) {
    if (servicesData == null) return [];
    
    try {
      if (servicesData is List) {
        return servicesData.map((e) {
          // If it's a Map (service object), extract serviceTitle
          if (e is Map<String, dynamic>) {
            return e['serviceTitle']?.toString() ?? 
                   e['categoryName']?.toString() ?? 
                   e['_id']?.toString() ?? 
                   'Service';
          }
          // If it's already a String, use it
          if (e is String) {
            // Check if it looks like raw data (starts with {)
            if (e.startsWith('{')) {
              return 'Service';
            }
            return e;
          }
          // Otherwise convert to string, but check if it looks like raw data
          final str = e.toString();
          if (str.startsWith('{')) {
            return 'Service';
          }
          return str;
        }).toList();
      } else if (servicesData is Map) {
        // If services is a map, extract the keys or values
        return servicesData.keys.map((e) => e.toString()).toList();
      } else {
        final str = servicesData.toString();
        if (str.startsWith('{')) {
          return ['Service'];
        }
        return [str];
      }
    } catch (e) {
      print('Error extracting services: $e');
      return [];
    }
  }
}
