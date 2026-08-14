import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../models/venue.dart';
import '../../services/api_client.dart';

class VenueListPage extends StatefulWidget {
  const VenueListPage({super.key});

  @override
  State<VenueListPage> createState() => _VenueListPageState();
}

class _VenueListPageState extends State<VenueListPage> {
  late List<Venue> venues;
  String latestBroadcast = '';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  String _safeText(String? value, String fallback) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return fallback;
    if (text.contains('�') || text.contains('???')) return fallback;
    return text;
  }

  Future<void> _loadVenues() async {
    try {
      setState(() => _isLoading = true);
      final response = await ApiClient.getVenues();
      
      if (response['code'] == 200) {
        final data = response['data'] as List?;
        if (data != null) {
          venues = data.map((v) {
            return Venue(
              id: v['id'] ?? 0,
              name: _safeText(v['name'] as String?, '晴天'),
              address: _safeText(v['address'] as String?, '成都市武侯区三利运动中心'),
              city: _safeText(v['city'] as String?, '成都'),
              courtCount: v['courtCount'] ?? 0,
              latitude: v['latitude'] ?? 0.0,
              longitude: v['longitude'] ?? 0.0,
              distance: (v['distance'] as num?)?.toDouble() ?? 0.0,
              onlineCount: v['onlineCount'] ?? 0,
              broadcastMessage: _safeText(v['broadcastMessage'] as String?, ''),
            );
          }).take(1).toList();
          
          // 获取最新的广播信息
          final firstBroadcast = venues.isNotEmpty ? venues.first.broadcastMessage : null;
          if (firstBroadcast != null && firstBroadcast.isNotEmpty) {
            latestBroadcast = firstBroadcast;
          }
          
          setState(() => _isLoading = false);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = '无效的数据格式';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['msg'] ?? '获取场馆列表失败';
        });
      }
    } catch (e) {
      print('❌ 加载场馆列表错误: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = '网络错误: $e';
      });
    }
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
                      color: AppTheme.textSecondary,
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

            // 球馆卡片列表或加载状态
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              )
            else if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVenues,
                        child: const Text('重新加载'),
                      ),
                    ],
                  ),
                ),
              )
            else if (venues.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    '暂无场馆',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              )
            else
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

