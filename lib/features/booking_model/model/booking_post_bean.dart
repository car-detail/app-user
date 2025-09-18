class BookingPostBean {
  String? status;
  String? message;
  int? statusCode;
  BookingPostData? data;

  BookingPostBean({this.status, this.message, this.statusCode, this.data});

  BookingPostBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    data = json['data'] != null ? BookingPostData.fromJson(json['data']) : null;
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

class BookingPostData {
  int? price;
  String? createdBy;
  String? vendorId;
  String? serviceId;
  String? orderStatus;
  String? timeSlot;
  String? date;
  bool? notificationSent;
  bool? isActive;
  bool? isDeleted;
  String? sId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  BookingPostData(
      {this.price,
        this.createdBy,
        this.vendorId,
        this.serviceId,
        this.orderStatus,
        this.timeSlot,
        this.date,
        this.notificationSent,
        this.isActive,
        this.isDeleted,
        this.sId,
        this.createdAt,
        this.updatedAt,
        this.iV});

  BookingPostData.fromJson(Map<String, dynamic> json) {
    price = json['price'];
    createdBy = json['createdBy'];
    vendorId = json['vendorId'];
    serviceId = json['serviceId'];
    orderStatus = json['orderStatus'];
    timeSlot = json['timeSlot'];
    date = json['date'];
    notificationSent = json['notificationSent'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    sId = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['price'] = price;
    data['createdBy'] = createdBy;
    data['vendorId'] = vendorId;
    data['serviceId'] = serviceId;
    data['orderStatus'] = orderStatus;
    data['timeSlot'] = timeSlot;
    data['date'] = date;
    data['notificationSent'] = notificationSent;
    data['isActive'] = isActive;
    data['isDeleted'] = isDeleted;
    data['_id'] = sId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['__v'] = iV;
    return data;
  }
}
