void main() {
  Map<String, dynamic> json = {'distance': 10};
  double? distance = json['distance']?.toDouble();
  print("Distance: $distance");
}
