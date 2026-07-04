import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time_utils.dart';
import '../../providers/reel_provider.dart';
import '../player/player_screen.dart';
import '../wipe/countdown_banner.dart';

/// ปฏิทิน 1 สัปดาห์ (อาทิตย์→เสาร์) — กดวันที่มีคลิปเพื่อเล่นย้อนหลัง
class WeekCalendarScreen extends ConsumerWidget {
  const WeekCalendarScreen({super.key});

  static const _dowTh = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(reelProvider).value;
    final now = DateTime.now();
    final days = weekDays(now);
    final today = startOfDay(now);

    return Scaffold(
      appBar: AppBar(title: const Text('สัปดาห์นี้')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: CountdownBanner(),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final day = days[i];
                final count = week == null ? 0 : clipsForDay(week, day).length;
                final hasClips = count > 0;
                final isToday = day == today;
                final isFuture = day.isAfter(today);

                return Card(
                  elevation: hasClips ? 2 : 0,
                  color: isToday
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(child: Text(_dowTh[i])),
                    title: Text(
                      '${_dowTh[i]} ${day.day}/${day.month}',
                      style: TextStyle(
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      isFuture
                          ? 'ยังมาไม่ถึง'
                          : hasClips
                          ? '$count คลิป'
                          : 'ไม่มีคลิป',
                    ),
                    trailing: hasClips
                        ? const Icon(Icons.play_circle_fill)
                        : null,
                    enabled: hasClips,
                    onTap: hasClips
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(day: day),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
