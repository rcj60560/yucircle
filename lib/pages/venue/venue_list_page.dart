import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../models/venue.dart';

class VenueListPage extends StatefulWidget {
  const VenueListPage({super.key});

  @override
  State<VenueListPage> createState() => _VenueListPageState();
}

class _VenueListPageState extends State<VenueListPage> {
  late List<Venue> venues;
  String latestBroadcast = '1号场高质量缺人，L4 以上速来';

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    // Mock 数据：只有晴天羽毛球馆
    venues = [
      Venue(
        id: 1,
        name: '晴天羽毛球馆',
        address: '成都市武侯区一环路南三段1号',
        city: '成都',
        courtCount: 10,
        latitude: 30.5528,
        longitude: 104.0666,
        distance: 3.2,
        onlineCount: 23,
        broadcastMessage: latestBroadcast,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部标题区
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '附近球馆',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '今晚去哪打？',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // 广播跑马灯
            if (latestBroadcast.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA500).withValues(alpha: 0.1),
                  border: Border.all(color: const Color(0xFFFFA500), width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: Color(0xFFFFA500), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        latestBroadcast,
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

            // 球馆卡片列表
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: venues.length,
                itemBuilder: (context, index) {
                  final venue = venues[index];
                  return _buildVenueCard(venue);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueCard(Venue venue) {
    return GestureDetector(
      onTap: () {
        // 跳转到俱乐部列表页，传递球馆ID
        Get.toNamed(
          '/club-list',
          arguments: {'venueId': venue.id, 'venueName': venue.name},
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
            // 球馆名称
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    venue.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primary),
              ],
            ),
            const SizedBox(height: 8),

            // 地址
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    venue.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 统计信息行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 场地数
                _buildInfoItem('🏸', '${venue.courtCount}片场', Colors.grey[700]!),
                // 距离
                _buildInfoItem('📍', '距你${venue.distance}km', Colors.grey[700]!),
                // 在线人数
                _buildInfoItem('👥', '在线${venue.onlineCount}人', AppTheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String icon, String text, Color color) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

