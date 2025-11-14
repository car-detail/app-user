class ServicesModelData {
  String? status;
  String? message;
  int? statusCode;
  List<ServicesData>? data;

  ServicesModelData({this.status, this.message, this.statusCode, this.data});

  ServicesModelData.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    if (json['data'] != null) {
      data = <ServicesData>[];
      json['data'].forEach((v) {
        data!.add(ServicesData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    data['statusCode'] = statusCode;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ServicesData {
  String? sId;
  String? displayName;
  String? officialEmail;
  String? mobile;
  String? displayPicture;
  Location? location;
  bool? isShopOpen;
  double? distance;
  String? category;
  bool? isAppVendor;
  List<Services> services = [];

  ServicesData(
      {this.sId,
        this.displayName,
        this.officialEmail,
        this.mobile,
        this.displayPicture,
        this.location,
        this.isShopOpen,
        this.distance,
        this.category,
        this.isAppVendor,
        services});

  ServicesData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    displayName = json['displayName'];
    officialEmail = json['officialEmail'];
    mobile = json['mobile'];
    displayPicture = json['displayPicture'];
    location = json['location'] != null
        ? Location.fromJson(json['location'])
        : null;
    isShopOpen = json['isShopOpen'];
    distance = json['distance']?.toDouble();
    category = json['category'];
    isAppVendor = json['isAppVendor'];
    if (json['services'] != null) {
      services = <Services>[];
      json['services'].forEach((v) {
        if (v is Map<String, dynamic>) {
          // Handle app services (array of objects)
          services.add(Services.fromJson(v));
        }
        // Skip Google Places types (strings) as they are not actual services
        // Google Places vendors should have empty services array
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['displayName'] = displayName;
    data['officialEmail'] = officialEmail;
    data['mobile'] = mobile;
    data['displayPicture'] = displayPicture;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['isShopOpen'] = isShopOpen;
    data['distance'] = distance;
    data['category'] = category;
    data['isAppVendor'] = isAppVendor;
    if (services != null) {
      data['services'] = services.map((v) => v.toJson()).toList();
    }
    return data;
  }

}

class Location {
  String? name;
  Coordinates? coordinates;
  double? lat;
  double? lng;

  Location({this.name, this.coordinates, this.lat, this.lng});

  Location.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    coordinates = json['coordinates'] != null
        ? Coordinates.fromJson(json['coordinates'])
        : null;
    lat = json['lat'];
    lng = json['lng'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (coordinates != null) {
      data['coordinates'] = coordinates!.toJson();
    }
    data['lat'] = lat;
    data['lng'] = lng;
    return data;
  }
}

class Coordinates {
  double? long;
  double? lat;

  Coordinates({this.long, this.lat});

  Coordinates.fromJson(Map<String, dynamic> json) {
    long = json['lng'];
    lat = json['lat'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lng'] = long;
    data['lat'] = lat;
    return data;
  }
}

class Services {
  String? sId;
  String? serviceTitle;
  String? timeSlotCapacity;
  int? price;
  String? categoryName;
  String? categoryId;
  List<String>? detailImages;
  String? coverImage;
  String? mobile;
  Location? location;
  String? createdBy;
  String? vendorId;
  int? promotionPlanPrice;
  int? promotionSerialNumber;
  bool? isActive;
  bool? isDeleted;
  List<TimeSlots>? timeSlots;
  int? totalReviews;
  int? averageRating;
  String? createdAt;
  String? updatedAt;
  int? iV;
  List<Category>? category;

  Services(
      {this.sId,
        this.serviceTitle,
        this.timeSlotCapacity,
        this.price,
        this.categoryName,
        this.categoryId,
        this.detailImages,
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
        this.totalReviews,
        this.averageRating,
        this.createdAt,
        this.updatedAt,
        this.iV,
        this.category});

  Services.fromJson(Map<String, dynamic> json) {
    try {
      sId = json['_id']?.toString();
      serviceTitle = json['serviceTitle']?.toString();
      timeSlotCapacity = json['timeSlotCapacity']?.toString();
      price = json['price'] is int ? json['price'] : int.tryParse(json['price']?.toString() ?? '0');
      categoryName = json['categoryName']?.toString();
      categoryId = json['categoryId']?.toString();
      detailImages = json['detailImages']?.cast<String>() ?? [];
      coverImage = json['coverImage']?.toString();
      mobile = json['mobile']?.toString();
      location = json['location'] != null
          ? Location.fromJson(json['location'])
          : null;
      createdBy = json['createdBy']?.toString();
      vendorId = json['vendorId']?.toString();
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
      totalReviews = json['total_reviews'] is int ? json['total_reviews'] : int.tryParse(json['total_reviews']?.toString() ?? '0');
      averageRating = json['average_rating'] is int ? json['average_rating'] : int.tryParse(json['average_rating']?.toString() ?? '0');
      createdAt = json['createdAt']?.toString();
      updatedAt = json['updatedAt']?.toString();
      iV = json['__v'] is int ? json['__v'] : int.tryParse(json['__v']?.toString() ?? '0');
      if (json['category'] != null) {
        category = <Category>[];
        json['category'].forEach((v) {
          category!.add(Category.fromJson(v));
        });
      }
    } catch (e) {
      print("❌ Error parsing Services: $e");
      print("❌ Services JSON data: $json");
      // Set default values to prevent crashes
      sId = json['_id']?.toString();
      serviceTitle = "Service";
      timeSlotCapacity = "1";
      price = 0;
      categoryName = "Car Service";
      categoryId = "";
      detailImages = [];
      coverImage = "";
      mobile = "";
      location = null;
      createdBy = "";
      vendorId = "";
      promotionPlanPrice = 0;
      promotionSerialNumber = 0;
      isActive = true;
      isDeleted = false;
      timeSlots = [];
      totalReviews = 0;
      averageRating = 0;
      createdAt = "";
      updatedAt = "";
      iV = 0;
      category = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['serviceTitle'] = serviceTitle;
    data['timeSlotCapacity'] = timeSlotCapacity;
    data['price'] = price;
    data['categoryName'] = categoryName;
    data['categoryId'] = categoryId;
    data['detailImages'] = detailImages;
    data['coverImage'] = coverImage;
    data['mobile'] = mobile;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['createdBy'] = createdBy;
    data['vendorId'] = vendorId;
    data['promotionPlanPrice'] = promotionPlanPrice;
    data['promotionSerialNumber'] = promotionSerialNumber;
    data['isActive'] = isActive;
    data['isDeleted'] = isDeleted;
    if (timeSlots != null) {
      data['timeSlots'] = timeSlots!.map((v) => v.toJson()).toList();
    }
    data['total_reviews'] = totalReviews;
    data['average_rating'] = averageRating;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    if (category != null) {
      data['category'] = category!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}



class TimeSlots {
  String? slot;
  int? capacity;
  int? booked;
  String? sId;

  TimeSlots({this.slot, this.capacity, this.booked, this.sId});

  TimeSlots.fromJson(Map<String, dynamic> json) {
    slot = json['slot'];
    capacity = json['capacity'];
    booked = json['booked'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['slot'] = slot;
    data['capacity'] = capacity;
    data['booked'] = booked;
    data['_id'] = sId;
    return data;
  }
}

class Category {
  String? sId;
  String? categoryTitle;
  String? logoImage;
  String? categoryDescription;
  bool? isActive;
  bool? isDeleted;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Category(
      {this.sId,
        this.categoryTitle,
        this.logoImage,
        this.categoryDescription,
        this.isActive,
        this.isDeleted,
        this.createdAt,
        this.updatedAt,
        this.iV});

  Category.fromJson(Map<String, dynamic> json) {
    try {
      sId = json['_id']?.toString();
      categoryTitle = json['categoryTitle']?.toString();
      logoImage = json['logoImage']?.toString();
      categoryDescription = json['categoryDescription']?.toString();
      isActive = json['isActive'] is bool ? json['isActive'] : json['isActive']?.toString().toLowerCase() == 'true';
      isDeleted = json['isDeleted'] is bool ? json['isDeleted'] : json['isDeleted']?.toString().toLowerCase() == 'true';
      createdAt = json['createdAt']?.toString();
      updatedAt = json['updatedAt']?.toString();
      iV = json['__v'] is int ? json['__v'] : int.tryParse(json['__v']?.toString() ?? '0');
    } catch (e) {
      print("❌ Error parsing Category: $e");
      print("❌ Category JSON data: $json");
      // Set default values to prevent crashes
      sId = json['_id']?.toString();
      categoryTitle = "Category";
      logoImage = "";
      categoryDescription = "";
      isActive = true;
      isDeleted = false;
      createdAt = "";
      updatedAt = "";
      iV = 0;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['categoryTitle'] = categoryTitle;
    data['logoImage'] = logoImage;
    data['categoryDescription'] = categoryDescription;
    data['isActive'] = isActive;
    data['isDeleted'] = isDeleted;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}
