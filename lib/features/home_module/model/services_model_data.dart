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
    sId = json['_id'];
    serviceTitle = json['serviceTitle'];
    timeSlotCapacity = json['timeSlotCapacity'];
    price = json['price'];
    categoryName = json['categoryName'];
    categoryId = json['categoryId'];
    detailImages = json['detailImages'].cast<String>();
    coverImage = json['coverImage'];
    mobile = json['mobile'];
    location = json['location'] != null
        ? Location.fromJson(json['location'])
        : null;
    createdBy = json['createdBy'];
    vendorId = json['vendorId'];
    promotionPlanPrice = json['promotionPlanPrice'];
    promotionSerialNumber = json['promotionSerialNumber'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    if (json['timeSlots'] != null) {
      timeSlots = <TimeSlots>[];
      json['timeSlots'].forEach((v) {
        timeSlots!.add(TimeSlots.fromJson(v));
      });
    }
    totalReviews = json['total_reviews'];
    averageRating = json['average_rating'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    if (json['category'] != null) {
      category = <Category>[];
      json['category'].forEach((v) {
        category!.add(Category.fromJson(v));
      });
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
    sId = json['_id'];
    categoryTitle = json['categoryTitle'];
    logoImage = json['logoImage'];
    categoryDescription = json['categoryDescription'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
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
