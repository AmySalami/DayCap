import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/clip.dart';
import '../../providers/reel_provider.dart';
import 'trim_screen.dart';

/// จัดการคลิปของวัน: ลากจัดลำดับ, ลบ, แตะเข้าไปตัด
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key, required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(reelProvider).value;
    final clips = week == null ? <Clip>[] : clipsForDay(week, day);

    return Scaffold(
      appBar: AppBar(title: const Text('จัดการคลิป')),
      body: clips.isEmpty
          ? const Center(child: Text('ไม่มีคลิป'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: clips.length,
              onReorder: (oldIndex, newIndex) => ref
                  .read(reelProvider.notifier)
                  .reorderClips(day, oldIndex, newIndex),
              itemBuilder: (context, i) {
                final clip = clips[i];
                return ListTile(
                  key: ValueKey(clip.id),
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(clip.label,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ยาว ${_fmt(clip.trimmedDurationMs)}'
                      '${clip.trimmedDurationMs != clip.durationMs ? ' (ตัดแล้ว)' : ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.content_cut),
                        tooltip: 'ตัด',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TrimScreen(
                                day: day, clipId: clip.id),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'ลบ',
                        onPressed: () => _confirmDelete(context, ref, clip),
                      ),
                      const Icon(Icons.drag_handle),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TrimScreen(day: day, clipId: clip.id),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Clip clip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ลบคลิป ${clip.label}?'),
        content: const Text('ลบแล้วเอาคืนไม่ได้'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ลบ')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(reelProvider.notifier).deleteClip(day, clip.id);
    }
  }

  String _fmt(int ms) {
    final total = (ms / 1000).round();
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
