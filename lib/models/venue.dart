/// 球馆模型
class Venue {
  final int id;
  final String name;
  final String address;
  final String city;
  final int courtCount;
  final double? latitude;
  final double? longitude;
  final double? distance; // 距离，单位km
  final int onlineCount; // 当前在线人数
  final String? broadcastMessage; // 最新广播消息

  Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.courtCount,
    this.latitude,
    this.longitude,
    this.distance,
    this.onlineCount = 0,
    this.broadcastMessage,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      courtCount: json['courtCount'] as int,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      onlineCount: json['onlineCount'] as int? ?? 0,
      broadcastMessage: json['broadcastMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'courtCount': courtCount,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'onlineCount': onlineCount,
      'broadcastMessage': broadcastMessage,
    };
  }
}

