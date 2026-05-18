class Offer {
  double? distance;
  Offer.fromJson(Map<String, dynamic> json) {
    distance = json['distance']?.toDouble();
  }
}
void main() {
  try {
    Map<String, dynamic> json = {'distance': 10};
    Offer offer = Offer.fromJson(json);
    print("Distance: ${offer.distance}");
  } catch (e, st) {
    print("Error: $e\n$st");
  }
}
