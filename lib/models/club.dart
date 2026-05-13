/// 俱乐部模型
class Club {
  final int id;
  final int venueId;
  final String name;
  final String description;
  final int creatorId;
  final String status; // pending, active, frozen, deleted
  final int broadcastCredits; // 广播次数
  final DateTime createdAt;
  final int todayActivityCount; // 今日活动数
  final int onlineCount; // 当前在线人数
  final bool hasActiveBoradcast; // 是否有活跃广播

  Club({
    required this.id,
    required this.venueId,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.status,
    required this.broadcastCredits,
    required this.createdAt,
    this.todayActivityCount = 0,
    this.onlineCount = 0,
    this.hasActiveBoradcast = false,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] as int,
      venueId: json['venueId'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      creatorId: json['creatorId'] as int,
      status: json['status'] as String? ?? 'active',
      broadcastCredits: json['broadcastCredits'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      todayActivityCount: json['todayActivityCount'] as int? ?? 0,
      onlineCount: json['onlineCount'] as int? ?? 0,
      hasActiveBoradcast: json['hasActiveBoradcast'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venueId': venueId,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'status': status,
      'broadcastCredits': broadcastCredits,
      'createdAt': createdAt.toIso8601String(),
      'todayActivityCount': todayActivityCount,
      'onlineCount': onlineCount,
      'hasActiveBoradcast': hasActiveBoradcast,
    };
  }
}

