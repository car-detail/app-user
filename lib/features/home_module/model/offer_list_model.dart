class OfferListModelBean {
  String? status;
  String? message;
  int? statusCode;
  List<OfferListModelData>? data;

  OfferListModelBean({this.status, this.message, this.statusCode, this.data});

  OfferListModelBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    if (json['data'] != null) {
      data = <OfferListModelData>[];
      json['data'].forEach((v) {
        data!.add(new OfferListModelData.fromJson(v));
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

class OfferListModelData {
  String? sId;
  bool? isActive;
  bool? isDelete;
  String? createdBy;
  String? updatedBy;
  String? createdAt;
  String? title;
  String? description;
  String? image;
  int? discount;
  String? vendor;
  String? service;
  Location? location;
  bool? isCurrentlyActive;
  String? validFrom;
  String? validUntil;
  String? updatedAt;
  int? iV;
  double? distance;

  OfferListModelData(
      {this.sId,
        this.isActive,
        this.isDelete,
        this.createdBy,
        this.updatedBy,
        this.createdAt,
        this.title,
        this.description,
        this.image,
        this.discount,
        this.vendor,
        this.service,
        this.location,
        this.isCurrentlyActive,
        this.validFrom,
        this.validUntil,
        this.updatedAt,
        this.iV,
        this.distance});

  OfferListModelData.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    isActive = json['isActive'];
    isDelete = json['isDelete'];
    createdBy = json['createdBy'];
    updatedBy = json['updatedBy'];
    createdAt = json['createdAt'];
    title = json['title'];
    description = json['description'];
    image = json['image'];
    discount = json['discount'];
    vendor = json['vendor'];
    service = json['service'];
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    isCurrentlyActive = json['isCurrentlyActive'];
    validFrom = json['validFrom'];
    validUntil = json['validUntil'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    distance = json['distance'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['isActive'] = this.isActive;
    data['isDelete'] = this.isDelete;
    data['createdBy'] = this.createdBy;
    data['updatedBy'] = this.updatedBy;
    data['createdAt'] = this.createdAt;
    data['title'] = this.title;
    data['description'] = this.description;
    data['image'] = this.image;
    data['discount'] = this.discount;
    data['vendor'] = this.vendor;
    data['service'] = this.service;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    data['isCurrentlyActive'] = this.isCurrentlyActive;
    data['validFrom'] = this.validFrom;
    data['validUntil'] = this.validUntil;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    data['distance'] = this.distance;
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
  double? lat;
  double? long;

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
