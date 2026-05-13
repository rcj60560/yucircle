/// 活动大厅快照（包含全部信息）
class ActivityLobbySnapshot {
  final dynamic activity; // Activity
  final List<dynamic> slots; // List<ActivitySlot>
  final List<dynamic> onlineUsers; // List<ActivityPresence>
  final List<dynamic> messages; // List<ActivityMessage>
  final List<dynamic> broadcasts; // List<Broadcast>

  ActivityLobbySnapshot({
    required this.activity,
    required this.slots,
    required this.onlineUsers,
    required this.messages,
    required this.broadcasts,
  });

  factory ActivityLobbySnapshot.fromJson(Map<String, dynamic> json) {
    return ActivityLobbySnapshot(
      activity: json['activity'],
      slots: json['slots'] as List<dynamic>? ?? [],
      onlineUsers: json['onlineUsers'] as List<dynamic>? ?? [],
      messages: json['messages'] as List<dynamic>? ?? [],
      broadcasts: json['broadcasts'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity': activity,
      'slots': slots,
      'onlineUsers': onlineUsers,
      'messages': messages,
      'broadcasts': broadcasts,
    };
  }
}

/// 在线心跳记录
class ActivityPresence {
  final int id;
  final int activityId;
  final int userId;
  final String userName;
  final String userAvatar;
  final String userLevel;
  final DateTime lastPingAt;
  final DateTime createdAt;

  ActivityPresence({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userLevel,
    required this.lastPingAt,
    required this.createdAt,
  });

  factory ActivityPresence.fromJson(Map<String, dynamic> json) {
    return ActivityPresence(
      id: json['id'] as int,
      activityId: json['activityId'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String,
      userLevel: json['userLevel'] as String,
      lastPingAt: DateTime.parse(json['lastPingAt'] as String? ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityId': activityId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'userLevel': userLevel,
      'lastPingAt': lastPingAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// 大厅聊天消息
class ActivityMessage {
  final int id;
  final int activityId;
  final int userId;
  final String userName;
  final String userAvatar;
  final String userLevel;
  final String content;
  final DateTime createdAt;

  ActivityMessage({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userLevel,
    required this.content,
    required this.createdAt,
  });

  factory ActivityMessage.fromJson(Map<String, dynamic> json) {
    return ActivityMessage(
      id: json['id'] as int,
      activityId: json['activityId'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String,
      userLevel: json['userLevel'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityId': activityId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'userLevel': userLevel,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// 俱乐部广播
class Broadcast {
  final int id;
  final int clubId;
  final int senderId;
  final String senderName;
  final String content;
  final DateTime expiresAt;
  final DateTime createdAt;

  Broadcast({
    required this.id,
    required this.clubId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Broadcast.fromJson(Map<String, dynamic> json) {
    return Broadcast(
      id: json['id'] as int,
      clubId: json['clubId'] as int,
      senderId: json['senderId'] as int,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String? ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clubId': clubId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

