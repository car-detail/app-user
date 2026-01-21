import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class GooglePlacesService {
  static const String _apiKey = "AIzaSyBFtrosISezP-8z2NwTWKhD_5pNHoi0wRw";
  static const String _baseUrl = "https://maps.googleapis.com/maps/api/place";

  /// Search for nearby car service businesses using Google Places API
  static Future<List<GooglePlaceVendor>> searchNearbyCarServices({
    required double latitude,
    required double longitude,
    int radius = 5000, // 5km radius
    String type = "car_repair",
  }) async {
    try {
      final url = "$_baseUrl/nearbysearch/json?location=$latitude,$longitude&radius=$radius&type=$type&key=$_apiKey";
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        
        return results.map((place) => GooglePlaceVendor.fromJson(place)).toList();
      } else {
        throw Exception('Failed to fetch places: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get detailed information about a specific place
  static Future<GooglePlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = "$_baseUrl/details/json?place_id=$placeId&fields=name,formatted_address,formatted_phone_number,website,rating,user_ratings_total,photos,opening_hours&key=$_apiKey";
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          return GooglePlaceDetails.fromJson(data['result']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Search for places by text query
  static Future<List<GooglePlaceVendor>> searchPlacesByText({
    required String query,
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = "$_baseUrl/textsearch/json?query=$encodedQuery&location=$latitude,$longitude&radius=$radius&key=$_apiKey";
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        
        return results.map((place) => GooglePlaceVendor.fromJson(place)).toList();
      } else {
        throw Exception('Failed to search places: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }
}

class GooglePlaceVendor {
  final String placeId;
  final String name;
  final String? address;
  final double? rating;
  final int? userRatingsTotal;
  final double latitude;
  final double longitude;
  final String? photoReference;
  final List<String> types;
  final bool isOpen;
  final String? businessStatus;

  GooglePlaceVendor({
    required this.placeId,
    required this.name,
    this.address,
    this.rating,
    this.userRatingsTotal,
    required this.latitude,
    required this.longitude,
    this.photoReference,
    required this.types,
    required this.isOpen,
    this.businessStatus,
  });

  factory GooglePlaceVendor.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final location = geometry['location'] as Map<String, dynamic>;
    
    return GooglePlaceVendor(
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      address: json['vicinity'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      latitude: (location['lat'] as num).toDouble(),
      longitude: (location['lng'] as num).toDouble(),
      photoReference: json['photos'] != null && (json['photos'] as List).isNotEmpty
          ? (json['photos'][0] as Map<String, dynamic>)['photo_reference'] as String?
          : null,
      types: List<String>.from(json['types'] as List),
      isOpen: json['opening_hours']?['open_now'] as bool? ?? false,
      businessStatus: json['business_status'] as String?,
    );
  }

  /// Get photo URL if photo reference is available
  String? get photoUrl {
    if (photoReference != null) {
      return "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoReference&key=${GooglePlacesService._apiKey}";
    }
    return null;
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
}

class GooglePlaceDetails {
  final String name;
  final String? formattedAddress;
  final String? formattedPhoneNumber;
  final String? website;
  final double? rating;
  final int? userRatingsTotal;
  final List<String>? photoReferences;
  final Map<String, List<String>>? openingHours;

  GooglePlaceDetails({
    required this.name,
    this.formattedAddress,
    this.formattedPhoneNumber,
    this.website,
    this.rating,
    this.userRatingsTotal,
    this.photoReferences,
    this.openingHours,
  });

  factory GooglePlaceDetails.fromJson(Map<String, dynamic> json) {
    List<String>? photoRefs;
    if (json['photos'] != null) {
      photoRefs = (json['photos'] as List)
          .map((photo) => (photo as Map<String, dynamic>)['photo_reference'] as String)
          .toList();
    }

    Map<String, List<String>>? hours;
    if (json['opening_hours'] != null) {
      final openingHours = json['opening_hours'] as Map<String, dynamic>;
      if (openingHours['weekday_text'] != null) {
        hours = {};
        final weekdayText = openingHours['weekday_text'] as List;
        for (int i = 0; i < weekdayText.length; i++) {
          final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
          if (i < dayNames.length) {
            hours[dayNames[i]] = [weekdayText[i] as String];
          }
        }
      }
    }

    return GooglePlaceDetails(
      name: json['name'] as String,
      formattedAddress: json['formatted_address'] as String?,
      formattedPhoneNumber: json['formatted_phone_number'] as String?,
      website: json['website'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      photoReferences: photoRefs,
      openingHours: hours,
    );
  }

  /// Get photo URLs
  List<String> get photoUrls {
    if (photoReferences != null) {
      return photoReferences!.map((ref) => 
        "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$ref&key=${GooglePlacesService._apiKey}"
      ).toList();
    }
    return [];
  }
}
