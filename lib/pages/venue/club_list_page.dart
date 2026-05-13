import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../models/club.dart';

class ClubListPage extends StatefulWidget {
  const ClubListPage({super.key});

  @override
  State<ClubListPage> createState() => _ClubListPageState();
}

class _ClubListPageState extends State<ClubListPage> {
  late List<Club> clubs;
  late int venueId;
  late String venueName;

  @override
  void initState() {
    super.initState();
    _extractArguments();
    _loadMockData();
  }

  void _extractArguments() {
    venueId = Get.arguments?['venueId'] ?? 1;
    venueName = Get.arguments?['venueName'] ?? '晴天羽毛球馆';
  }

  void _loadMockData() {
    // Mock 数据：3个俱乐部
    clubs = [
      Club(
        id: 1,
        venueId: venueId,
        name: '俱乐部 A',
        description: '羽毛球爱好者聚集地',
        creatorId: 1,
        status: 'active',
        broadcastCredits: 5,
        createdAt: DateTime.now(),
        todayActivityCount: 2,
        onlineCount: 8,
        hasActiveBoradcast: true,
      ),
      Club(
        id: 2,
        venueId: venueId,
        name: '俱乐部 B',
        description: '高手对决的地方',
        creatorId: 2,
        status: 'active',
        broadcastCredits: 3,
        createdAt: DateTime.now(),
        todayActivityCount: 1,
        onlineCount: 5,
        hasActiveBoradcast: false,
      ),
      Club(
        id: 3,
        venueId: venueId,
        name: '俱乐部 C',
        description: '新手友好型俱乐部',
        creatorId: 3,
        status: 'active',
        broadcastCredits: 2,
        createdAt: DateTime.now(),
        todayActivityCount: 3,
        onlineCount: 12,
        hasActiveBoradcast: true,
      ),
    ];
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              '选择俱乐部进入活动大厅',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 俱乐部列表
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: clubs.length,
                itemBuilder: (context, index) {
                  final club = clubs[index];
                  return _buildClubCard(club);
                },
              ),
            ),

            // 个人发起活动入口
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '个人发起活动',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            '不加入俱乐部也能组局',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubCard(Club club) {
    return GestureDetector(
      onTap: () {
        // 跳转到活动大厅页，传递俱乐部ID和球馆ID
        Get.toNamed(
          '/activity-lobby',
          arguments: {
            'venueId': venueId,
            'venueName': venueName,
            'clubId': club.id,
            'clubName': club.name,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 俱乐部名称和广播标志
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    club.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (club.hasActiveBoradcast)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA500).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications, size: 12, color: Color(0xFFFFA500)),
                        SizedBox(width: 4),
                        Text(
                          '有广播',
                          style: TextStyle(fontSize: 10, color: Color(0xFFFFA500)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // 简介
            Text(
              club.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),

            // 统计信息行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildClubInfoItem('📅', '今日${club.todayActivityCount}个活动'),
                _buildClubInfoItem('👥', '在线${club.onlineCount}人'),
              ],
            ),

            const SizedBox(height: 12),

            // 进入按钮
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '进入大厅',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubInfoItem(String icon, String text) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

