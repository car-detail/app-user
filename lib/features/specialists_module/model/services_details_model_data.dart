import '../../home_module/model/services_model_data.dart';

class ServicesDetailsModelData {
  String? status;
  String? message;
  int? statusCode;
  ServicesDetailsData? data;

  ServicesDetailsModelData(
      {this.status, this.message, this.statusCode, this.data});

  ServicesDetailsModelData.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    data = json['data'] != null ? ServicesDetailsData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    data['statusCode'] = statusCode;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class ServicesDetailsData {
  String? sId;
  String? serviceTitle;
  String? about;
  String? timeSlotCapacity;
  int? price;
  String? serviceDuration;
  String? categoryName;
  String? categoryId;
  List<String> detailImages = [];
  String? coverImage;
  String? mobile;
  Location? location;
  String? createdBy;
  VendorId? vendorId;
  int? promotionPlanPrice;
  int? promotionSerialNumber;
  bool? isActive;
  bool? isDeleted;
  List<TimeSlots>? timeSlots;
  String? createdAt;
  String? updatedAt;
  int? iV;
  bool? isBookmarked;
  num? averageRating;
  num? totalReviews;
  List<Offers> offers = [];
  List<Services> services = [];
  List<Map<String, dynamic>> packages = []; // Vendor packages
  String? id;

  ServicesDetailsData(
      {this.sId,
        this.serviceTitle,
        this.about,
        this.timeSlotCapacity,
        this.price,
        this.serviceDuration,
        this.categoryName,
        this.categoryId,
        detailImages,
        this.coverImage,
        this.mobile,
        this.location,
        this.createdBy,
        this.vendorId,
        this.promotionPlanPrice,
        this.promotionSerialNumber,
        this.isActive,
        this.isDeleted,
        this.timeSlots,
        this.createdAt,
        this.updatedAt,
        this.iV,
        this.isBookmarked,
        this.averageRating,
        this.totalReviews,
        offers,
        services,
        packages,
        this.id});

  ServicesDetailsData.fromJson(Map<String, dynamic> json) {
    try {
      sId = json['_id']?.toString();
      serviceTitle = json['serviceTitle']?.toString();
      about = json['about']?.toString();
      timeSlotCapacity = json['timeSlotCapacity']?.toString();
      price = json['price'] is int ? json['price'] : int.tryParse(json['price']?.toString() ?? '0');
      serviceDuration = json['serviceDuration']?.toString();
      categoryName = json['categoryName']?.toString();
      categoryId = json['categoryId']?.toString();
      detailImages = json['detailImages']?.cast<String>() ?? [];
      coverImage = json['coverImage']?.toString() ?? json['serviceImage']?.toString();
      mobile = json['mobile']?.toString();
      location = json['location'] != null
          ? Location.fromJson(json['location'])
          : null;
      createdBy = json['createdBy']?.toString();
      vendorId = json['vendorId'] != null
          ? VendorId.fromJson(json['vendorId'])
          : null;
      promotionPlanPrice = json['promotionPlanPrice'] is int ? json['promotionPlanPrice'] : int.tryParse(json['promotionPlanPrice']?.toString() ?? '0');
      promotionSerialNumber = json['promotionSerialNumber'] is int ? json['promotionSerialNumber'] : int.tryParse(json['promotionSerialNumber']?.toString() ?? '0');
      isActive = json['isActive'] is bool ? json['isActive'] : json['isActive']?.toString().toLowerCase() == 'true';
      isDeleted = json['isDeleted'] is bool ? json['isDeleted'] : json['isDeleted']?.toString().toLowerCase() == 'true';
      if (json['timeSlots'] != null) {
        timeSlots = <TimeSlots>[];
        json['timeSlots'].forEach((v) {
          timeSlots!.add(TimeSlots.fromJson(v));
        });
      }
      createdAt = json['createdAt']?.toString();
      updatedAt = json['updatedAt']?.toString();
      iV = json['__v'] is int ? json['__v'] : int.tryParse(json['__v']?.toString() ?? '0');
      isBookmarked = json['isBookmarked'] is bool ? json['isBookmarked'] : json['isBookmarked']?.toString().toLowerCase() == 'true';
      averageRating = json['average_rating'] is num ? json['average_rating'] : num.tryParse(json['average_rating']?.toString() ?? '0');
      totalReviews = json['total_reviews'] is num ? json['total_reviews'] : num.tryParse(json['total_reviews']?.toString() ?? '0');
      if (json['offers'] != null) {
        offers = <Offers>[];
        json['offers'].forEach((v) {
          if (v != null) {
            offers.add(Offers.fromJson(v));
          }
        });
      }
      if (json['services'] != null) {
        services = <Services>[];
        json['services'].forEach((v) {
          if (v != null) {
            services.add(Services.fromJson(v));
          }
        });
      }
      if (json['packages'] != null) {
        packages = <Map<String, dynamic>>[];
        json['packages'].forEach((v) {
          if (v != null) {
            packages.add(Map<String, dynamic>.from(v));
          }
        });
      }
      id = json['id']?.toString();
    } catch (e) {
      print("❌ Error parsing ServicesDetailsData: $e");
      print("❌ JSON data: $json");
      // Set default values to prevent crashes
      sId = json['_id']?.toString();
      serviceTitle = "Service";
      about = "";
      timeSlotCapacity = "1";
      price = 0;
      serviceDuration = "1 hour";
      categoryName = "Car Service";
      categoryId = "";
      detailImages = [];
      coverImage = "";
      mobile = "";
      location = null;
      createdBy = "";
      vendorId = null;
      promotionPlanPrice = 0;
      promotionSerialNumber = 0;
      isActive = true;
      isDeleted = false;
      timeSlots = [];
      createdAt = "";
      updatedAt = "";
      iV = 0;
      isBookmarked = false;
      averageRating = 0;
      totalReviews = 0;
      offers = [];
      services = [];
      id = "";
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['serviceTitle'] = serviceTitle;
    data['about'] = about;
    data['timeSlotCapacity'] = timeSlotCapacity;
    data['price'] = price;
    data['serviceDuration'] = serviceDuration;
    data['categoryName'] = categoryName;
    data['categoryId'] = categoryId;
    data['detailImages'] = detailImages;
    data['coverImage'] = coverImage;
    data['mobile'] = mobile;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['createdBy'] = createdBy;
    if (vendorId != null) {
      data['vendorId'] = vendorId!.toJson();
    }
    data['promotionPlanPrice'] = promotionPlanPrice;
    data['promotionSerialNumber'] = promotionSerialNumber;
    data['isActive'] = isActive;
    data['isDeleted'] = isDeleted;
    if (timeSlots != null) {
      data['timeSlots'] = timeSlots!.map((v) => v.toJson()).toList();
    }
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    data['isBookmarked'] = isBookmarked;
    data['average_rating'] = averageRating;
    data['total_reviews'] = totalReviews;
    if (offers != null) {
      data['offers'] = offers.map((v) => v.toJson()).toList();
    }
    if (services != null) {
      data['services'] = services.map((v) => v.toJson()).toList();
    }
    if (packages != null) {
      data['packages'] = packages;
    }
    data['id'] = id;
    return data;
  }
}

class Location {
  String? name;
  Coordinates? coordinates;

  Location({this.name, this.coordinates});

  Location.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    coordinates = json['coordinates'] != null
        ? Coordinates.fromJson(json['coordinates'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (coordinates != null) {
      data['coordinates'] = coordinates!.toJson();
    }
    return data;
  }
}

class Coordinates {
  double? lat;
  double? long;

  Coordinates({this.lat, this.long});

  Coordinates.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    long = json['long'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lat'] = lat;
    data['long'] = long;
    return data;
  }
}

class VendorId {
  String? sId;
  String? displayName;
  String? mobile;
  String? displayPicture;
  String? openTime;
  String? closeTime;
  bool? isShopOpen;

  VendorId(
      {this.sId,
        this.displayName,
        this.mobile,
        this.displayPicture,
        this.openTime,
        this.closeTime,
        this.isShopOpen});

  VendorId.fromJson(Map<String, dynamic> json) {
    try {
      sId = json['_id']?.toString();
      displayName = json['displayName']?.toString();
      mobile = json['mobile']?.toString();
      displayPicture = json['displayPicture']?.toString();
      openTime = json['openTime']?.toString();
      closeTime = json['closeTime']?.toString();
      isShopOpen = json['isShopOpen'] is bool ? json['isShopOpen'] : json['isShopOpen']?.toString().toLowerCase() == 'true';
    } catch (e) {
      print("❌ Error parsing VendorId: $e");
      print("❌ VendorId JSON data: $json");
      // Set default values to prevent crashes
      sId = json['_id']?.toString();
      displayName = "Vendor";
      mobile = "";
      displayPicture = "";
      openTime = "";
      closeTime = "";
      isShopOpen = false;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['displayName'] = displayName;
    data['mobile'] = mobile;
    data['displayPicture'] = displayPicture;
    data['openTime'] = openTime;
    data['closeTime'] = closeTime;
    data['isShopOpen'] = isShopOpen;
    return data;
  }
}

class TimeSlots {
  String? slot;
  int? capacity;
  int? booked;
  String? sId;
  String? id;

  TimeSlots({this.slot, this.capacity, this.booked, this.sId, this.id});

  TimeSlots.fromJson(Map<String, dynamic> json) {
    try {
      slot = json['slot']?.toString();
      capacity = json['capacity'] is int ? json['capacity'] : int.tryParse(json['capacity']?.toString() ?? '0');
      booked = json['booked'] is int ? json['booked'] : int.tryParse(json['booked']?.toString() ?? '0');
      sId = json['_id']?.toString();
      id = json['id']?.toString();
    } catch (e) {
      print("❌ Error parsing TimeSlots: $e");
      print("❌ TimeSlots JSON data: $json");
      // Set default values to prevent crashes
      slot = "00:00 - 01:00";
      capacity = 1;
      booked = 0;
      sId = "";
      id = "";
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['slot'] = slot;
    data['capacity'] = capacity;
    data['booked'] = booked;
    data['_id'] = sId;
    data['id'] = id;
    return data;
  }
}

class Offers {
  String? sId;
  String? title;
  String? description;
  String? image;
  int? discount;
  String? service;
  String? validUntil;

  Offers(
      {this.sId,
        this.title,
        this.description,
        this.image,
        this.discount,
        this.service,
        this.validUntil});

  Offers.fromJson(Map<String, dynamic> json) {
    try {
      sId = json['_id']?.toString();
      title = json['title']?.toString();
      description = json['description']?.toString();
      image = json['image']?.toString();
      discount = json['discount'] is int ? json['discount'] : int.tryParse(json['discount']?.toString() ?? '0');
      service = json['service']?.toString();
      validUntil = json['validUntil']?.toString();
    } catch (e) {
      print("❌ Error parsing Offers: $e");
      print("❌ Offers JSON data: $json");
      // Set default values to prevent crashes
      sId = "";
      title = "Offer";
      description = "";
      image = "";
      discount = 0;
      service = "";
      validUntil = "";
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['title'] = title;
    data['description'] = description;
    data['image'] = image;
    data['discount'] = discount;
    data['service'] = service;
    data['validUntil'] = validUntil;
    return data;
  }
}
