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
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['statusCode'] = this.statusCode;
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
        records!.add(new Records.fromJson(v));
      });
    }
    totalCount = json['totalCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.records != null) {
      data['records'] = this.records!.map((v) => v.toJson()).toList();
    }
    data['totalCount'] = this.totalCount;
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
        this.commentByVendor});

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
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['price'] = this.price;
    data['vendorId'] = this.vendorId;
    data['serviceId'] = this.serviceId;
    data['orderStatus'] = this.orderStatus;
    data['timeSlot'] = this.timeSlot;
    data['date'] = this.date;
    data['commentByUser'] = this.commentByUser;
    data['serviceTitle'] = this.serviceTitle;
    data['serviceAbout'] = this.serviceAbout;
    data['serviceImage'] = this.serviceImage;
    data['serviceCategory'] = this.serviceCategory;
    data['serviceMobile'] = this.serviceMobile;
    data['serviceDuration'] = this.serviceDuration;
    data['vendorDisplayPicture'] = this.vendorDisplayPicture;
    data['vendorMobile'] = this.vendorMobile;
    data['vendorEmail'] = this.vendorEmail;
    data['cancelled_by'] = this.cancelledBy;
    data['commentByVendor'] = this.commentByVendor;
    return data;
  }
}
