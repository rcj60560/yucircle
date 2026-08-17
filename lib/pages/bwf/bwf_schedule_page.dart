import 'package:flutter/material.dart';
import '../../models/bwf_schedule.dart';

class BwfSchedulePage extends StatelessWidget {
  final ScheduleData data;
  const BwfSchedulePage({super.key, required this.data});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('赛程页（Task 8 实现）'));
}
