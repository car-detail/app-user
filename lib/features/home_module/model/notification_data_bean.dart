class Notifications {
  String? title;
  String? body;
  String? createdAt;

  Notifications({this.title, this.body, this.createdAt});

  Notifications.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    body = json['body'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['body'] = body;
    data['createdAt'] = createdAt;
    return data;
  }
}

class NotificationData {
  List<Notifications>? notifications;
  int? total;
  String? page;
  String? limit;
  int? totalPages;

  NotificationData({
    this.notifications,
    this.total,
    this.page,
    this.limit,
    this.totalPages,
  });

  NotificationData.fromJson(Map<String, dynamic> json) {
    if (json['notifications'] != null) {
      notifications = <Notifications>[];
      json['notifications'].forEach((v) {
        notifications!.add(Notifications.fromJson(v));
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

class NotificationDataBean {
  String? status;
  String? message;
  int? statusCode;
  NotificationData? data;

  NotificationDataBean({
    this.status,
    this.message,
    this.statusCode,
    this.data,
  });

  NotificationDataBean.fromJson(Map<String, dynamic> json) {
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
