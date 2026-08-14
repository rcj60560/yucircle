import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../utils/storage.dart';

class ActivityLobbyPage extends StatefulWidget {
  const ActivityLobbyPage({super.key});

  @override
  State<ActivityLobbyPage> createState() => _ActivityLobbyPageState();
}

class _ActivityLobbyPageState extends State<ActivityLobbyPage>
  with TickerProviderStateMixin {
  late int venueId;
  late int clubId;
  late int activityId;
  late String venueName;
  late String clubName;
  late String activityTitle;
  late String timeSlot;
  String levelRequirement = 'L1-L8';
  String matchType = '双打';

  // 页面状态
  int onlineCount = 0;
  int venueOnlineCount = 0;
  int myUserId = 0;
  int? mySlotId; // 当前用户占的坑位ID
  String mySlotStatus = ''; // reserved, confirmed
  bool _isLoading = true;
  bool _isActionLoading = false;
  String _errorMessage = '';

  // 数据
  late List<CourtData> courts;
  late List<OnlineUser> onlineUsers;
  late List<ChatMessage> chatMessages;
  List<String> broadcasts = [];

  late AnimationController _broadcastController;
  Timer? _snapshotTimer;
  Timer? _pingTimer;

  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _extractArguments();
    _initStateData();
    _setupControllers();
    _bootstrapLobby();
  }

  void _extractArguments() {
    venueId = Get.arguments?['venueId'] ?? 1;
    clubId = Get.arguments?['clubId'] ?? 1;
    activityId = Get.arguments?['activityId'] ?? 0;
    venueName = Get.arguments?['venueName'] ?? '晴天羽毛球馆';
    clubName = Get.arguments?['clubName'] ?? '俱乐部 A';
    activityTitle = Get.arguments?['activityTitle'] ?? '今晚活动';
    timeSlot = Get.arguments?['timeSlot'] ?? '19:30-22:00';
  }

  void _initStateData() {
    courts = [];
    onlineUsers = [];
    chatMessages = [];
  }

  void _setupControllers() {
    _broadcastController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  Future<void> _bootstrapLobby() async {
    final userInfo = await StorageManager.getUserInfo();
    myUserId = int.tryParse(userInfo['userId'] ?? '') ?? 0;

    if (activityId <= 0) {
      final resolved = await _resolveActivityIdFromClub();
      if (!resolved) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = '缺少 activityId，无法进入大厅';
        });
        return;
      }
    }

    await _enterLobby();
    await _refreshLobbySnapshot(showErrorSnackBar: true);
    _startPolling();
  }

  Future<bool> _resolveActivityIdFromClub() async {
    if (clubId <= 0) return false;
    final response = await ApiClient.getClubActivities(clubId);
    if (response['code'] != 200) return false;
    final activities = response['data'] as List? ?? [];
    if (activities.isEmpty) return false;
    final first = activities.first as Map<String, dynamic>;
    final id = first['id'] as int? ?? 0;
    if (id <= 0) return false;
    activityId = id;
    activityTitle = first['title'] as String? ?? activityTitle;
    timeSlot = first['timeSlot'] as String? ?? timeSlot;
    return true;
  }

  void _startPolling() {
    _snapshotTimer?.cancel();
    _pingTimer?.cancel();

    _snapshotTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshLobbySnapshot();
    });

    _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      ApiClient.pingActivityLobby(activityId);
    });
  }

  Future<void> _enterLobby() async {
    final response = await ApiClient.enterActivityLobby(activityId);
    if (response['code'] != 200 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('进入大厅失败：${response['msg'] ?? '未知错误'}')),
      );
    }
  }

  Future<void> _refreshLobbySnapshot({bool showErrorSnackBar = false}) async {
    final response = await ApiClient.getActivityLobbySnapshot(activityId);

    if (!mounted) return;

    if (response['code'] == 200) {
      final data = response['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _isLoading = false;
        _errorMessage = '';
        _applyLobbyData(data);
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = response['msg'] ?? '获取大厅快照失败';
    });

    if (showErrorSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    }
  }

  void _applyLobbyData(Map<String, dynamic> data) {
    onlineCount = data['onlineCount'] as int? ?? 0;
    venueOnlineCount = data['venueOnlineCount'] as int? ?? 0;
    timeSlot = data['timeSlot'] as String? ?? timeSlot;
    activityTitle = data['title'] as String? ?? activityTitle;
    levelRequirement = data['levelRequirement'] as String? ?? levelRequirement;
    matchType = data['matchType'] as String? ?? matchType;

    final broadcast = data['broadcast'] as Map<String, dynamic>?;
    broadcasts = [];
    if (broadcast != null && (broadcast['content'] as String?)?.isNotEmpty == true) {
      broadcasts = [broadcast['content'] as String];
    }

    final courtsData = data['courts'] as List? ?? [];
    courts = courtsData.map((item) {
      final court = item as Map<String, dynamic>;
      final courtNumber = court['courtNumber'] as int? ?? 0;
      final slotsData = court['slots'] as List? ?? [];

      final slots = slotsData.map((slotItem) {
        final slot = slotItem as Map<String, dynamic>;
        final userId = slot['userId'] as int?;
        final status = _toSlotStatus(slot['status'] as String? ?? 'empty');
        final isMine = slot['isMine'] as bool? ?? false;

        if (userId != null && userId == myUserId) {
          mySlotId = courtNumber * 10 + (slot['slotNumber'] as int? ?? 0);
          mySlotStatus = slot['status'] as String? ?? '';
        }

        return SlotData(
          slotId: courtNumber * 10 + (slot['slotNumber'] as int? ?? 0),
          slotNumber: slot['slotNumber'] as int? ?? 0,
          status: status,
          userId: userId,
          userName: slot['nickname'] as String?,
          userAvatar: (slot['avatar'] as String?)?.isNotEmpty == true
              ? slot['avatar'] as String
              : '👤',
          userLevel: slot['level'] as String?,
          isMine: isMine,
        );
      }).toList();

      return CourtData(
        courtNumber: courtNumber,
        levelRequirement: levelRequirement,
        matchType: matchType,
        slots: slots,
      );
    }).toList();

    final observers = data['observers'] as List? ?? [];
    onlineUsers = observers.map((item) {
      final user = item as Map<String, dynamic>;
      return OnlineUser(
        userId: user['userId'] as int? ?? 0,
        userName: user['nickname'] as String? ?? '球友',
        userLevel: user['level'] as String? ?? '',
        userAvatar: (user['avatar'] as String?)?.isNotEmpty == true
            ? user['avatar'] as String
            : '👤',
      );
    }).toList();

    final messages = data['messages'] as List? ?? [];
    chatMessages = messages.map((item) {
      final msg = item as Map<String, dynamic>;
      return ChatMessage(
        userName: msg['nickname'] as String? ?? '球友',
        userLevel: msg['level'] as String? ?? '',
        userAvatar: '👤',
        content: msg['content'] as String? ?? '',
        timestamp: DateTime.now(),
      );
    }).toList();
  }

  SlotStatus _toSlotStatus(String status) {
    switch (status) {
      case 'reserved':
        return SlotStatus.reserved;
      case 'confirmed':
        return SlotStatus.confirmed;
      case 'locked':
        return SlotStatus.locked;
      case 'empty':
      default:
        return SlotStatus.empty;
    }
  }

  Future<void> _onSlotTapped(int courtIndex, int slotIndex) async {
    if (_isActionLoading) return;
    final slot = courts[courtIndex].slots[slotIndex];

    if (slot.status == SlotStatus.empty) {
      // 点击空坑位 - 弹对话框确认
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认占位'),
          content: Text(
            '确认要在 ${courts[courtIndex].courtNumber} 号场 ${slot.slotNumber} 号位占位吗？\n\n占位成功后可随时取消，但请勿频繁变动。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _doReserveSlot(courtIndex, slotIndex);
              },
              child: const Text('确认占位'),
            ),
          ],
        ),
      );
    } else if (slot.isMine) {
      // 点击自己的坑位 - 根据状态显示取消或升级选项
      if (slot.status == SlotStatus.reserved) {
        // 已占坑未确认 - 弹菜单选择确认或取消
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('坑位操作'),
            content: Text(
              '${courts[courtIndex].courtNumber} 号场 ${slot.slotNumber} 号位已占位',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showCancelSlotDialog(courtIndex, slotIndex);
                },
                child: const Text('取消占位', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmSlot(courtIndex, slotIndex);
                },
                child: const Text('确认参加'),
              ),
            ],
          ),
        );
      } else if (slot.status == SlotStatus.confirmed) {
        // 已确认 - 只能取消
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认取消'),
            content: Text(
              '确认要取消 ${courts[courtIndex].courtNumber} 号场的已确认位置吗？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('不取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showCancelSlotDialog(courtIndex, slotIndex);
                },
                child: const Text('确认取消', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _doReserveSlot(int courtIndex, int slotIndex) async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);
    final slot = courts[courtIndex].slots[slotIndex];

    final response = await ApiClient.reserveActivitySlot(
      activityId: activityId,
      courtNumber: courts[courtIndex].courtNumber,
      slotNumber: slot.slotNumber,
    );
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (response['code'] == 200) {
      await _refreshLobbySnapshot();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('占坑成功！')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['msg'] ?? '占坑失败')),
      );
    }
  }

  void _showCancelSlotDialog(int courtIndex, int slotIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认取消占位'),
        content: const Text(
          '一旦取消成功，此位置将释放给其他用户。确认要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('不取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelSlot(courtIndex, slotIndex);
            },
            child: const Text('确认取消', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  Future<void> _confirmSlot(int courtIndex, int slotIndex) async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    final response = await ApiClient.confirmActivitySlot(activityId);
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (response['code'] == 200) {
      await _refreshLobbySnapshot();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已确认参加')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['msg'] ?? '确认参加失败')),
      );
    }
  }

  Future<void> _cancelSlot(int courtIndex, int slotIndex) async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    final response = await ApiClient.cancelActivitySlot(activityId);
    if (!mounted) return;
    setState(() => _isActionLoading = false);

    if (response['code'] == 200) {
      await _refreshLobbySnapshot();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已取消占坑')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['msg'] ?? '取消占坑失败')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final response = await ApiClient.sendActivityMessage(
      activityId: activityId,
      content: content,
    );

    if (!mounted) return;
    if (response['code'] == 200) {
      _messageController.clear();
      await _refreshLobbySnapshot();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('消息已发送')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['msg'] ?? '发送失败')),
      );
    }
  }

  @override
  void dispose() {
    _snapshotTimer?.cancel();
    _pingTimer?.cancel();
    if (activityId > 0) {
      ApiClient.leaveActivityLobby(activityId);
    }
    _broadcastController.dispose();
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
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else if (_errorMessage.isNotEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _refreshLobbySnapshot(showErrorSnackBar: true),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activityTitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          timeSlot,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$matchType · $levelRequirement',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '活动在线 $onlineCount 人',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            '球馆在线 $venueOnlineCount 人',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 内容区
          Expanded(
            child: _buildCourtsTabContent(),
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
                SizedBox(
                  height: 180,
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
            ),
        ],
      ),
    );
  }

  Widget _buildCourtsTabContent() {
    if (courts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_tennis_outlined,
                size: 48,
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              const Text(
                '当前暂无场地信息',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

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
              childAspectRatio: 0.92,
            ),
            itemCount: courts.length,
            itemBuilder: (context, index) {
              return _buildCourtCard(index);
            },
          ),
          const SizedBox(height: 12),
          _buildObserverInlineSection(),
        ],
      ),
    );
  }

  Widget _buildCourtCard(int courtIndex) {
    final court = courts[courtIndex];
    final hasPlayers = court.slots.any((s) => s.userId != null);
    final isLocked = hasPlayers &&
        court.slots.where((s) => s.userId != null).every((s) => s.status == SlotStatus.locked);
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
            itemCount: court.slots.length,
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
      // 空位 - 可点击
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
      if (slot.isMine) {
        // 我的坑位 - 黄色 + 立体阴影
        slotContent = Container(
          decoration: BoxDecoration(
            color: Colors.yellow[100],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.yellow[600]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow[700]!.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
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
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
              ),
              const Text(
                '我的坑位',
                style: TextStyle(fontSize: 7, color: Colors.orange),
              ),
            ],
          ),
        );
      } else {
        // 他人的坑位 - 蓝色，不可交互
        slotContent = Container(
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue[300]!, width: 1),
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
      }
    } else if (slot.status == SlotStatus.confirmed) {
      // 已确认
      if (slot.isMine) {
        // 我的坑位 - 绿色 + 立体阴影 + 锁定标记
        slotContent = Container(
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.green[600]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.green[700]!.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                slot.userAvatar!,
                style: const TextStyle(fontSize: 14),
              ),
              const Icon(Icons.check, size: 12, color: Colors.green),
              const Text(
                '已确认',
                style: TextStyle(fontSize: 7, color: Colors.green),
              ),
            ],
          ),
        );
      } else {
        // 他人的坑位 - 绿色但不可交互
        slotContent = Container(
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.green[300]!, width: 1),
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
      }
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
      onTap: courtLocked
          ? null
          : () => _onSlotTapped(courtIndex, slotIndex),
      child: slotContent,
    );
  }

  Widget _buildObserverInlineSection() {
    if (onlineUsers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: const Text(
          '闲逛中 0 人（暂无观望者）',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '闲逛中 ${onlineUsers.length} 人（球馆边看场地）',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: onlineUsers.map((user) {
                return Container(
                  width: 68,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(color: AppTheme.border, width: 1),
                        ),
                        child: Center(
                          child: Text(user.userAvatar, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
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
  bool isMine; // 标记这是否为用户自己的坑位

  SlotData({
    required this.slotId,
    required this.slotNumber,
    required this.status,
    this.userId,
    this.userName,
    this.userAvatar,
    this.userLevel,
    this.isMine = false,
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

