import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';

class ActivityLobbyPage extends StatefulWidget {
  const ActivityLobbyPage({super.key});

  @override
  State<ActivityLobbyPage> createState() => _ActivityLobbyPageState();
}

class _ActivityLobbyPageState extends State<ActivityLobbyPage>
    with TickerProviderStateMixin {
  late int venueId;
  late int clubId;
  late String venueName;
  late String clubName;

  // 页面状态
  int onlineCount = 23;
  int myUserId = 1; // 当前用户ID（模拟）
  int? mySlotId; // 当前用户占的坑位ID
  String mySlotStatus = ''; // reserved, confirmed

  // 数据
  late List<CourtData> courts;
  late List<OnlineUser> onlineUsers;
  late List<ChatMessage> chatMessages;
  List<String> broadcasts = [
    '1号场高质量缺人，L4 以上速来',
    '2号场差一位，双打局',
  ];

  late AnimationController _broadcastController;
  late TabController _tabController;

  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _extractArguments();
    _loadMockData();
    _setupControllers();
  }

  void _extractArguments() {
    venueId = Get.arguments?['venueId'] ?? 1;
    clubId = Get.arguments?['clubId'] ?? 1;
    venueName = Get.arguments?['venueName'] ?? '晴天羽毛球馆';
    clubName = Get.arguments?['clubName'] ?? '俱乐部 A';
  }

  void _setupControllers() {
    _broadcastController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _tabController = TabController(length: 2, vsync: this);
  }

  void _loadMockData() {
    // 初始化10个场地，每个6个坑位
    courts = List.generate(10, (courtIndex) {
      return CourtData(
        courtNumber: courtIndex + 1,
        levelRequirement: 'L3+',
        matchType: '双打',
        slots: List.generate(6, (slotIndex) {
          return SlotData(
            slotId: courtIndex * 6 + slotIndex + 1,
            slotNumber: slotIndex + 1,
            status: SlotStatus.empty,
          );
        }),
      );
    });

    // 添加一些Mock用户占坑
    courts[0].slots[0] = SlotData(
      slotId: 1,
      slotNumber: 1,
      status: SlotStatus.confirmed,
      userName: '张三',
      userAvatar: '👨',
      userLevel: 'L4',
      userId: 10,
    );

    courts[0].slots[1] = SlotData(
      slotId: 2,
      slotNumber: 2,
      status: SlotStatus.reserved,
      userName: '李四',
      userAvatar: '👨',
      userLevel: 'L3',
      userId: 11,
    );

    courts[1].slots[0] = SlotData(
      slotId: 7,
      slotNumber: 1,
      status: SlotStatus.confirmed,
      userName: '王五',
      userAvatar: '👩',
      userLevel: 'L3.5',
      userId: 12,
    );

    // 在线用户（观望中）
    onlineUsers = [
      OnlineUser(
        userId: 20,
        userName: '观望者A',
        userLevel: 'L2',
        userAvatar: '👨',
      ),
      OnlineUser(
        userId: 21,
        userName: '观望者B',
        userLevel: 'L3',
        userAvatar: '👩',
      ),
      OnlineUser(
        userId: 22,
        userName: '观望者C',
        userLevel: 'L4',
        userAvatar: '👨',
      ),
    ];

    // 聊天消息
    chatMessages = [
      ChatMessage(
        userName: '张三',
        userLevel: 'L4',
        userAvatar: '👨',
        content: '1号场差一个人，来不？',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        userName: '李四',
        userLevel: 'L3',
        userAvatar: '👨',
        content: '我可以，但需要15分钟',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      ChatMessage(
        userName: '王五',
        userLevel: 'L3.5',
        userAvatar: '👩',
        content: '2号场缺人吗？',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];
  }

  void _onSlotTapped(int courtIndex, int slotIndex) {
    final slot = courts[courtIndex].slots[slotIndex];

    if (slot.status == SlotStatus.empty) {
      // 占坑
      setState(() {
        slot.status = SlotStatus.reserved;
        slot.userId = myUserId;
        slot.userName = '我';
        slot.userLevel = 'L3.5';
        slot.userAvatar = '👤';
        mySlotId = slot.slotId;
        mySlotStatus = 'reserved';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('占坑成功！请点击"确认参加"按钮')),
      );
    } else if (slot.userId == myUserId) {
      // 已占坑，显示取消选项
      _showSlotOptionsMenu(courtIndex, slotIndex);
    }
  }

  void _showSlotOptionsMenu(int courtIndex, int slotIndex) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '坑位操作',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (courts[courtIndex].slots[slotIndex].status == SlotStatus.reserved)
              GestureDetector(
                onTap: () {
                  Get.back();
                  _confirmSlot(courtIndex, slotIndex);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '确认参加',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Get.back();
                _cancelSlot(courtIndex, slotIndex);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '取消占坑',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSlot(int courtIndex, int slotIndex) {
    setState(() {
      courts[courtIndex].slots[slotIndex].status = SlotStatus.confirmed;
      mySlotStatus = 'confirmed';

      // 检查该场地是否所有坑位都已确认
      final court = courts[courtIndex];
      bool allConfirmed = court.slots.every(
        (s) => s.userId == null || s.status == SlotStatus.confirmed || s.status == SlotStatus.locked,
      );

      if (allConfirmed && court.slots.where((s) => s.userId != null).length == 6) {
        // 成局！
        for (var slot in court.slots) {
          if (slot.userId != null) {
            slot.status = SlotStatus.locked;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 该场地已成局！'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已确认参加')),
    );
  }

  void _cancelSlot(int courtIndex, int slotIndex) {
    setState(() {
      final slot = courts[courtIndex].slots[slotIndex];
      slot.status = SlotStatus.empty;
      slot.userId = null;
      slot.userName = null;
      slot.userLevel = null;
      slot.userAvatar = null;
      mySlotId = null;
      mySlotStatus = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已取消占坑')),
    );
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    setState(() {
      chatMessages.add(
        ChatMessage(
          userName: '我',
          userLevel: 'L3.5',
          userAvatar: '👤',
          content: _messageController.text,
          timestamp: DateTime.now(),
        ),
      );
    });

    _messageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('消息已发送 (60秒限频中)')),
    );
  }

  @override
  void dispose() {
    _broadcastController.dispose();
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              venueName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Text(
              clubName,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 顶部信息区
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppTheme.border, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 时间段和在线人数
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '今晚 19:30 - 22:00',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '在线 $onlineCount 人',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab：场地 / 观望
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primary,
              tabs: const [
                Tab(text: '场地'),
                Tab(text: '观望区'),
              ],
            ),
          ),

          // 内容区
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: 场地区
                _buildCourtsTabContent(),
                // Tab 2: 观望区
                _buildPresenceTabContent(),
              ],
            ),
          ),

          // 底部聊天区
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.border, width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 广播条（如果有）
                if (broadcasts.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA500).withValues(alpha: 0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFFFFA500).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications, color: Color(0xFFFFA500), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            broadcasts[0],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFFA500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 聊天消息列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = chatMessages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg.userAvatar, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${msg.userName} ${msg.userLevel}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    msg.content,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 输入框
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: '说点什么...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.border, width: 1),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '发送',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtsTabContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: courts.length,
            itemBuilder: (context, index) {
              return _buildCourtCard(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCourtCard(int courtIndex) {
    final court = courts[courtIndex];
    final isLocked = court.slots.every((s) => s.userId == null || s.status == SlotStatus.locked);
    final confirmedCount = court.slots.where((s) => s.status == SlotStatus.confirmed || s.status == SlotStatus.locked).length;

    return Container(
      decoration: BoxDecoration(
        color: isLocked ? AppTheme.primary.withValues(alpha: 0.1) : Colors.white,
        border: Border.all(
          color: isLocked ? AppTheme.primary : AppTheme.border,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 场地号和状态
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${court.courtNumber}号场',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '已成局',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Text(
                  '$confirmedCount/6 已确认',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // 坑位网格（3行2列或2行3列）
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 6,
            itemBuilder: (context, slotIndex) {
              return _buildSlotWidget(courtIndex, slotIndex, isLocked);
            },
          ),

          const SizedBox(height: 6),

          // 场地信息
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                court.levelRequirement,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              Text(
                court.matchType,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlotWidget(int courtIndex, int slotIndex, bool courtLocked) {
    final slot = courts[courtIndex].slots[slotIndex];

    Widget slotContent;

    if (slot.status == SlotStatus.empty) {
      // 空位
      slotContent = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[400] ?? Colors.grey,
            width: 1,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: Text('+', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    } else if (slot.status == SlotStatus.reserved) {
      // 已占坑未确认
      slotContent = Container(
        decoration: BoxDecoration(
          color: Colors.yellow[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.yellow[600]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot.userAvatar!,
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              slot.userLevel ?? '',
              style: const TextStyle(fontSize: 8),
            ),
          ],
        ),
      );
    } else if (slot.status == SlotStatus.confirmed) {
      // 已确认
      slotContent = Container(
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green[600]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot.userAvatar!,
              style: const TextStyle(fontSize: 14),
            ),
            const Icon(Icons.check, size: 10, color: Colors.green),
          ],
        ),
      );
    } else {
      // 已锁定
      slotContent = Container(
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.primary, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot.userAvatar!,
              style: const TextStyle(fontSize: 14),
            ),
            const Icon(Icons.lock, size: 10, color: AppTheme.primary),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: courtLocked ? null : () => _onSlotTapped(courtIndex, slotIndex),
      child: slotContent,
    );
  }

  Widget _buildPresenceTabContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '观望中的用户',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: onlineUsers.map((user) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border, width: 1),
                    ),
                    child: Center(
                      child: Text(user.userAvatar, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Text(
                      user.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Text(
                    user.userLevel,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// 数据类
class CourtData {
  final int courtNumber;
  final String levelRequirement;
  final String matchType;
  List<SlotData> slots;

  CourtData({
    required this.courtNumber,
    required this.levelRequirement,
    required this.matchType,
    required this.slots,
  });
}

class SlotData {
  final int slotId;
  final int slotNumber;
  SlotStatus status;
  int? userId;
  String? userName;
  String? userAvatar;
  String? userLevel;

  SlotData({
    required this.slotId,
    required this.slotNumber,
    required this.status,
    this.userId,
    this.userName,
    this.userAvatar,
    this.userLevel,
  });
}

class OnlineUser {
  final int userId;
  final String userName;
  final String userLevel;
  final String userAvatar;

  OnlineUser({
    required this.userId,
    required this.userName,
    required this.userLevel,
    required this.userAvatar,
  });
}

class ChatMessage {
  final String userName;
  final String userLevel;
  final String userAvatar;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.userName,
    required this.userLevel,
    required this.userAvatar,
    required this.content,
    required this.timestamp,
  });
}

enum SlotStatus { empty, reserved, confirmed, locked }

