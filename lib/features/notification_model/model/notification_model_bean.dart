class NotificationModelBean {
  String? status;
  String? message;
  int? statusCode;
  NotificationData? data;

  NotificationModelBean({this.status, this.message, this.statusCode, this.data});

  NotificationModelBean.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    statusCode = json['statusCode'];
    data = json['data'] != null ? NotificationData.fromJson(json['data']) : null;
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

class NotificationData {
  List<NotificationItem>? notifications;
  int? total;
  int? page;
  int? limit;
  int? totalPages;

  NotificationData({this.notifications, this.total, this.page, this.limit, this.totalPages});

  NotificationData.fromJson(Map<String, dynamic> json) {
    if (json['notifications'] != null) {
      notifications = <NotificationItem>[];
      json['notifications'].forEach((v) {
        notifications!.add(NotificationItem.fromJson(v));
      });
    }
    total = json['total'];
    page = json['page'];
    limit = json['limit'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (notifications != null) {
      data['notifications'] = notifications!.map((v) => v.toJson()).toList();
    }
    data['total'] = total;
    data['page'] = page;
    data['limit'] = limit;
    data['totalPages'] = totalPages;
    return data;
  }
}

class NotificationItem {
  String? sId;
  String? userId;
  String? title;
  String? body;
  Map<String, dynamic>? data;
  String? status;
  String? errorMessage;
  List<String>? fcmTokens;
  String? createdAt;
  String? updatedAt;

  NotificationItem({
    this.sId,
    this.userId,
    this.title,
    this.body,
    this.data,
    this.status,
    this.errorMessage,
    this.fcmTokens,
    this.createdAt,
    this.updatedAt,
  });

  NotificationItem.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    userId = json['userId'];
    title = json['title'];
    body = json['body'];
    data = json['data'];
    status = json['status'];
    errorMessage = json['errorMessage'];
    fcmTokens = json['fcmTokens']?.cast<String>();
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['userId'] = userId;
    data['title'] = title;
    data['body'] = body;
    data['data'] = this.data;
    data['status'] = status;
    data['errorMessage'] = errorMessage;
    data['fcmTokens'] = fcmTokens;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}
