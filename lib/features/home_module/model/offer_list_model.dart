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
        data!.add(OfferListModelData.fromJson(v));
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
  SimpleVendorData? vendorData;

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
        this.distance,
        this.vendorData});

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
        ? Location.fromJson(json['location'])
        : null;
    isCurrentlyActive = json['isCurrentlyActive'];
    validFrom = json['validFrom'];
    validUntil = json['validUntil'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    distance = json['distance']?.toDouble();
    vendorData = json['vendorData'] != null
        ? SimpleVendorData.fromJson(json['vendorData'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['isActive'] = isActive;
    data['isDelete'] = isDelete;
    data['createdBy'] = createdBy;
    data['updatedBy'] = updatedBy;
    data['createdAt'] = createdAt;
    data['title'] = title;
    data['description'] = description;
    data['image'] = image;
    data['discount'] = discount;
    data['vendor'] = vendor;
    data['service'] = service;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['isCurrentlyActive'] = isCurrentlyActive;
    data['validFrom'] = validFrom;
    data['validUntil'] = validUntil;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    data['distance'] = distance;
    if (vendorData != null) {
      data['vendorData'] = vendorData!.toJson();
    }
    return data;
  }
}

class SimpleVendorData {
  String? id;
  String? displayName;

  SimpleVendorData({this.id, this.displayName});

  SimpleVendorData.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    displayName = json['displayName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = id;
    data['displayName'] = displayName;
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
    lat = (json['lat'] as num?)?.toDouble();
    long = (json['long'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lat'] = lat;
    data['long'] = long;
    return data;
  }
}
