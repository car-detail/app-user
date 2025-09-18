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
