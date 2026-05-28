class EmergencyLocation {
  final String name;
  final double lat;
  final double lng;
  final String address;
  final String type; // 'hospital' or 'police'
  final String? phoneNumber;
  final double? distance; // Added distance in KM

  EmergencyLocation({
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
    required this.type,
    this.phoneNumber,
    this.distance,
  });
}
