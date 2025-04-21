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
        data!.add(new ServicesData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['statusCode'] = this.statusCode;
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
  int? distance;
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
        ? new Location.fromJson(json['location'])
        : null;
    isShopOpen = json['isShopOpen'];
    distance = json['distance'];
    if (json['services'] != null) {
      services = <Services>[];
      json['services'].forEach((v) {
        services!.add(new Services.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['displayName'] = this.displayName;
    data['officialEmail'] = this.officialEmail;
    data['mobile'] = this.mobile;
    data['displayPicture'] = this.displayPicture;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['isShopOpen'] = this.isShopOpen;
    data['distance'] = this.distance;
    if (this.services != null) {
      data['services'] = this.services!.map((v) => v.toJson()).toList();
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
        ? new Coordinates.fromJson(json['coordinates'])
        : null;
    lat = json['lat'];
    lng = json['lng'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    if (this.coordinates != null) {
      data['coordinates'] = this.coordinates!.toJson();
    }
    data['lat'] = this.lat;
    data['lng'] = this.lng;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lng'] = this.long;
    data['lat'] = this.lat;
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
        ? new Location.fromJson(json['location'])
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
        timeSlots!.add(new TimeSlots.fromJson(v));
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
        category!.add(new Category.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['serviceTitle'] = this.serviceTitle;
    data['timeSlotCapacity'] = this.timeSlotCapacity;
    data['price'] = this.price;
    data['categoryName'] = this.categoryName;
    data['categoryId'] = this.categoryId;
    data['detailImages'] = this.detailImages;
    data['coverImage'] = this.coverImage;
    data['mobile'] = this.mobile;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['createdBy'] = this.createdBy;
    data['vendorId'] = this.vendorId;
    data['promotionPlanPrice'] = this.promotionPlanPrice;
    data['promotionSerialNumber'] = this.promotionSerialNumber;
    data['isActive'] = this.isActive;
    data['isDeleted'] = this.isDeleted;
    if (this.timeSlots != null) {
      data['timeSlots'] = this.timeSlots!.map((v) => v.toJson()).toList();
    }
    data['total_reviews'] = this.totalReviews;
    data['average_rating'] = this.averageRating;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    if (this.category != null) {
      data['category'] = this.category!.map((v) => v.toJson()).toList();
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['slot'] = this.slot;
    data['capacity'] = this.capacity;
    data['booked'] = this.booked;
    data['_id'] = this.sId;
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['categoryTitle'] = this.categoryTitle;
    data['logoImage'] = this.logoImage;
    data['categoryDescription'] = this.categoryDescription;
    data['isActive'] = this.isActive;
    data['isDeleted'] = this.isDeleted;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}
