import '../../home_module/model/services_model_data.dart';

class BookmarkModelBean {
  String? status;
  String? message;
  int? statusCode;
  List<BookmarkModelData>? data;

  BookmarkModelBean({this.status, this.message, this.statusCode, this.data});

  BookmarkModelBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    if (json['data'] != null) {
      data = <BookmarkModelData>[];
      json['data'].forEach((v) {
        data!.add(new BookmarkModelData.fromJson(v));
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

class BookmarkModelData {
  String? sId;
  String? userId;
  ServicesData? serviceId;
  bool? isActive;
  bool? isDeleted;
  String? createdAt;
  String? updatedAt;
  int? iV;

  BookmarkModelData(
      {this.sId,
        this.userId,
        this.serviceId,
        this.isActive,
        this.isDeleted,
        this.createdAt,
        this.updatedAt,
        this.iV});

  BookmarkModelData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    serviceId = json['serviceId'] != null
        ? new ServicesData.fromJson(json['serviceId'])
        : null;
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['userId'] = this.userId;
    if (this.serviceId != null) {
      data['serviceId'] = this.serviceId!.toJson();
    }
    data['isActive'] = this.isActive;
    data['isDeleted'] = this.isDeleted;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class ServiceId {
  String? sId;
  String? serviceTitle;
  String? about;
  int? price;
  String? serviceDuration;
  String? categoryName;
  String? categoryId;
  List<String>? detailImages;
  String? coverImage;
  String? mobile;
  Location? location;
  List<TimeSlots>? timeSlots;

  ServiceId(
      {this.sId,
        this.serviceTitle,
        this.about,
        this.price,
        this.serviceDuration,
        this.categoryName,
        this.categoryId,
        this.detailImages,
        this.coverImage,
        this.mobile,
        this.location,
        this.timeSlots});

  ServiceId.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    serviceTitle = json['serviceTitle'];
    about = json['about'];
    price = json['price'];
    serviceDuration = json['serviceDuration'];
    categoryName = json['categoryName'];
    categoryId = json['categoryId'];
    detailImages = json['detailImages'].cast<String>();
    coverImage = json['coverImage'];
    mobile = json['mobile'];
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    if (json['timeSlots'] != null) {
      timeSlots = <TimeSlots>[];
      json['timeSlots'].forEach((v) {
        timeSlots!.add(new TimeSlots.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['serviceTitle'] = this.serviceTitle;
    data['about'] = this.about;
    data['price'] = this.price;
    data['serviceDuration'] = this.serviceDuration;
    data['categoryName'] = this.categoryName;
    data['categoryId'] = this.categoryId;
    data['detailImages'] = this.detailImages;
    data['coverImage'] = this.coverImage;
    data['mobile'] = this.mobile;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    if (this.timeSlots != null) {
      data['timeSlots'] = this.timeSlots!.map((v) => v.toJson()).toList();
    }
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
        ? new Coordinates.fromJson(json['coordinates'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    if (this.coordinates != null) {
      data['coordinates'] = this.coordinates!.toJson();
    }
    return data;
  }
}

class Coordinates {
  String? lat;
  String? long;

  Coordinates({this.lat, this.long});

  Coordinates.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    long = json['long'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['long'] = this.long;
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
