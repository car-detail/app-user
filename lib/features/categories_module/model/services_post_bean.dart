class ServicesPostBean {
  String? status;
  String? message;
  int? statusCode;
  ServicesPostData? data;

  ServicesPostBean({this.status, this.message, this.statusCode, this.data});

  ServicesPostBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    data = json['data'] != null ? new ServicesPostData.fromJson(json['data']) : null;
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

class ServicesPostData {
  String? userId;
  String? serviceId;
  bool? isActive;
  bool? isDeleted;
  String? sId;
  String? createdAt;
  String? updatedAt;
  int? iV;

  ServicesPostData(
      {this.userId,
        this.serviceId,
        this.isActive,
        this.isDeleted,
        this.sId,
        this.createdAt,
        this.updatedAt,
        this.iV});

  ServicesPostData.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    serviceId = json['serviceId'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    sId = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userId'] = this.userId;
    data['serviceId'] = this.serviceId;
    data['isActive'] = this.isActive;
    data['isDeleted'] = this.isDeleted;
    data['_id'] = this.sId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}
