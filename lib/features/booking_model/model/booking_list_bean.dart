class BookingListBean {
  String? status;
  String? message;
  int? statusCode;
  Data? data;

  BookingListBean({this.status, this.message, this.statusCode, this.data});

  BookingListBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
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

class Data {
  List<Records>? records;
  int? totalCount;

  Data({this.records, this.totalCount});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['records'] != null) {
      records = <Records>[];
      json['records'].forEach((v) {
        records!.add(Records.fromJson(v));
      });
    }
    totalCount = json['totalCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (records != null) {
      data['records'] = records!.map((v) => v.toJson()).toList();
    }
    data['totalCount'] = totalCount;
    return data;
  }
}

class Records {
  String? sId;
  int? price;
  String? vendorId;
  String? serviceId;
  String? orderStatus;
  String? timeSlot;
  String? date;
  String? commentByUser;
  String? serviceTitle;
  String? serviceAbout;
  String? serviceImage;
  String? serviceCategory;
  String? serviceMobile;
  String? serviceDuration;
  String? vendorDisplayPicture;
  String? vendorMobile;
  String? vendorEmail;
  String? cancelledBy;
  String? commentByVendor;
  String? packageName;
  String? packageId;

  Records(
      {this.sId,
        this.price,
        this.vendorId,
        this.serviceId,
        this.orderStatus,
        this.timeSlot,
        this.date,
        this.commentByUser,
        this.serviceTitle,
        this.serviceAbout,
        this.serviceImage,
        this.serviceCategory,
        this.serviceMobile,
        this.serviceDuration,
        this.vendorDisplayPicture,
        this.vendorMobile,
        this.vendorEmail,
        this.cancelledBy,
        this.commentByVendor,
        this.packageName,
        this.packageId});

  Records.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    price = json['price'];
    vendorId = json['vendorId'];
    serviceId = json['serviceId'];
    orderStatus = json['orderStatus'];
    timeSlot = json['timeSlot'];
    date = json['date'];
    commentByUser = json['commentByUser'];
    serviceTitle = json['serviceTitle'];
    serviceAbout = json['serviceAbout'];
    serviceImage = json['serviceImage'];
    serviceCategory = json['serviceCategory'];
    serviceMobile = json['serviceMobile'];
    serviceDuration = json['serviceDuration'];
    vendorDisplayPicture = json['vendorDisplayPicture'];
    vendorMobile = json['vendorMobile'];
    vendorEmail = json['vendorEmail'];
    cancelledBy = json['cancelled_by'];
    commentByVendor = json['commentByVendor'];
    packageName = json['packageName'];
    packageId = json['packageId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['price'] = price;
    data['vendorId'] = vendorId;
    data['serviceId'] = serviceId;
    data['orderStatus'] = orderStatus;
    data['timeSlot'] = timeSlot;
    data['date'] = date;
    data['commentByUser'] = commentByUser;
    data['serviceTitle'] = serviceTitle;
    data['serviceAbout'] = serviceAbout;
    data['serviceImage'] = serviceImage;
    data['serviceCategory'] = serviceCategory;
    data['serviceMobile'] = serviceMobile;
    data['serviceDuration'] = serviceDuration;
    data['vendorDisplayPicture'] = vendorDisplayPicture;
    data['vendorMobile'] = vendorMobile;
    data['vendorEmail'] = vendorEmail;
    data['cancelled_by'] = cancelledBy;
    data['commentByVendor'] = commentByVendor;
    data['packageName'] = packageName;
    data['packageId'] = packageId;
    return data;
  }
}
