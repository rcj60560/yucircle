/// 活动坑位模型
class ActivitySlot {
  final int id;
  final int activityId;
  final int courtNumber; // 1-10
  final int slotNumber; // 1-6
  final int? userId; // null表示空位
  final String slotStatus; // reserved, confirmed, locked
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // 额外信息（用于展示）
  final String? userName;
  final String? userAvatar;
  final String? userLevel;

  ActivitySlot({
    required this.id,
    required this.activityId,
    required this.courtNumber,
    required this.slotNumber,
    required this.userId,
    required this.slotStatus,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatar,
    this.userLevel,
  });

  factory ActivitySlot.fromJson(Map<String, dynamic> json) {
    return ActivitySlot(
      id: json['id'] as int,
      activityId: json['activityId'] as int,
      courtNumber: json['courtNumber'] as int,
      slotNumber: json['slotNumber'] as int,
      userId: json['userId'] as int?,
      slotStatus: json['slotStatus'] as String? ?? 'reserved',
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      userName: json['userName'] as String?,
      userAvatar: json['userAvatar'] as String?,
      userLevel: json['userLevel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityId': activityId,
      'courtNumber': courtNumber,
      'slotNumber': slotNumber,
      'userId': userId,
      'slotStatus': slotStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userName': userName,
      'userAvatar': userAvatar,
      'userLevel': userLevel,
    };
  }
}

