class Offer {
  final String type;
  final double value;
  final double? sliceValue;

  Offer({
    required this.type,
    required this.value,
    this.sliceValue,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      type: json['type'],
      value: json['value'].toDouble(),
      sliceValue: json['sliceValue']?.toDouble(),
    );
  }
}
