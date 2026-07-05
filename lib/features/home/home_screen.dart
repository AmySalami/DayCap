import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/time_utils.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/time_badge.dart';
import '../../models/clip.dart';
import '../../models/week_log.dart';
import '../../providers/reel_provider.dart';
import '../../services/export_service.dart';
import '../edit/edit_widgets.dart';
import '../wipe/countdown_banner.dart';
import 'widgets/story_progress_bar.dart';
import 'widgets/week_calendar_strip.dart';

/// หน้า Home (หน้าขวาของ shell): วิดีโอเล่นในกรอบมน (ขนาดเท่าหน้ากล้อง)
/// + ปฏิทินใต้กรอบ + Edit mode inline (morph) — ไม่มี background blur แล้ว
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onCamera, this.editProgress});

  /// เรียกเมื่อจะไปหน้ากล้อง (ปัดขวาบนปฏิทิน) — shell เลื่อนไป Camera
  final VoidCallback? onCamera;

  /// ส่งค่าความคืบหน้า edit mode (0..1) ให้ shell เลื่อน tab ลงตาม
  final ValueNotifier<double>? editProgress;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDay = startOfDay(DateTime.now());
  VideoPlayerController? _controller;
  List<Clip> _clips = const [];
  int _index = 0;
  double _progress = 0;
  bool _initialLoaded = false;

  // ---- Edit mode ----
  late final AnimationController _edit;
  bool _editing = false;
  final Map<String, int> _startDraft = {};
  final Map<String, int> _endDraft = {};
  final Map<String, int> _durDraft = {};
  bool _dragging = false;
  int _playheadMs = 0;

  // ---- Share ----
  final ValueNotifier<ExportProgress?> _shareProgress = ValueNotifier(null);
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _edit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        widget.editProgress?.value = _edit.value;
        setState(() {});
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDay());
  }

  int _effStart(Clip c) => _editing ? _startDraft[c.id]! : c.trimStartMs;
  int _effEnd(Clip c) => _editing ? _endDraft[c.id]! : c.trimEndMs;

  Future<void> _loadDay() async {
    final week = ref.read(reelProvider).value;
    if (week != null) _initialLoaded = true;
    _clips = week == null ? const [] : clipsForDay(week, _selectedDay);
    _index = 0;
    _progress = 0;
    if (_clips.isEmpty) {
      await _controller?.dispose();
      if (mounted) setState(() => _controller = null);
      return;
    }
    await _playAt(0);
  }

  Future<void> _playAt(int index) async {
    if (_clips.isEmpty) {
      _controller?.removeListener(_watch);
      await _controller?.dispose();
      if (mounted) setState(() => _controller = null);
      return;
    }

    final i = index % _clips.length;
    final clip = _clips[i];
    final path = await ref.read(storageProvider).absolutePath(clip.fileName);

    final next = VideoPlayerController.file(File(path));
    try {
      await next.initialize();
    } catch (_) {
      await next.dispose();
      return;
    }
    _durDraft[clip.id] = next.value.duration.inMilliseconds;
    if (_editing) {
      _endDraft[clip.id] =
          (_endDraft[clip.id] ?? _durDraft[clip.id]!).clamp(0, _durDraft[clip.id]!);
    }
    await next.seekTo(Duration(milliseconds: _effStart(clip)));
    await next.play();

    if (!mounted) {
      await next.dispose();
      return;
    }
    final old = _controller;
    next.addListener(_watch);
    setState(() {
      _controller = next;
      _index = i;
      _progress = 0;
    });
    old?.removeListener(_watch);
    await old?.dispose();
  }

  void _watch() {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _clips.isEmpty) return;
    final clip = _clips[_index];
    final pos = c.value.position.inMilliseconds;

    if (_editing) {
      if (pos >= _effEnd(clip)) {
        c.seekTo(Duration(milliseconds: _effStart(clip)));
        setState(() => _playheadMs = _effStart(clip));
      } else if (pos != _playheadMs) {
        setState(() => _playheadMs = pos);
      }
      return;
    }

    final span = (clip.trimEndMs - clip.trimStartMs).clamp(1, 1 << 31);
    final frac = ((pos - clip.trimStartMs) / span).clamp(0.0, 1.0);
    if (frac != _progress) setState(() => _progress = frac);

    final ended = pos >= clip.trimEndMs ||
        (c.value.position >= c.value.duration &&
            !c.value.isPlaying &&
            c.value.duration > Duration.zero);
    if (ended) {
      c.removeListener(_watch);
      _playAt(_index + 1);
    }
  }

  // ---- day navigation ----
  void _selectDay(DateTime day) {
    if (day == _selectedDay) return;
    setState(() => _selectedDay = startOfDay(day));
    _loadDay();
  }

  void _changeDayBy(int delta) {
    final target = stepDay(_selectedDay, delta);
    if (target != _selectedDay) _selectDay(target);
  }

  void _onDaySwipe(DragEndDetails d) {
    if (_editing) return;
    final v = d.primaryVelocity ?? 0;
    if (v < -60) {
      _changeDayBy(1);
    } else if (v > 60) {
      _changeDayBy(-1);
    }
  }

  // ---- edit mode ----
  void _enterEdit() {
    if (_clips.isEmpty || _editing) return;
    for (final c in _clips) {
      _startDraft[c.id] = c.trimStartMs;
      _endDraft[c.id] = c.trimEndMs;
      _durDraft[c.id] = c.durationMs;
    }
    setState(() => _editing = true);
    _edit.forward();
    _controller?.seekTo(Duration(milliseconds: _clips[_index].trimStartMs));
    _controller?.play();
  }

  Future<void> _closeEdit() async {
    _dragging = false;
    setState(() => _editing = false);
    await _edit.reverse();
    await _playAt(0);
  }

  Future<void> _saveEdit() async {
    final notifier = ref.read(reelProvider.notifier);
    for (final c in _clips) {
      if (_startDraft[c.id] != c.trimStartMs ||
          _endDraft[c.id] != c.trimEndMs) {
        await notifier.updateTrim(_selectedDay, c.id,
            trimStartMs: _startDraft[c.id]!, trimEndMs: _endDraft[c.id]!);
      }
    }
    await _closeEdit();
  }

  void _onTrimHandles(int start, int end) {
    final clip = _clips[_index];
    final movedStart = start != _startDraft[clip.id];
    setState(() {
      _startDraft[clip.id] = start;
      _endDraft[clip.id] = end;
    });
    _controller?.pause();
    final seekMs = movedStart ? start : end;
    _controller?.seekTo(Duration(milliseconds: seekMs));
    setState(() => _playheadMs = seekMs);
  }

  Future<void> _deleteClip(Clip clip) async {
    _dragging = false;
    await ref.read(reelProvider.notifier).deleteClip(_selectedDay, clip.id);
    _startDraft.remove(clip.id);
    _endDraft.remove(clip.id);
    _durDraft.remove(clip.id);
    final week = ref.read(reelProvider).value;
    _clips = week == null ? const [] : clipsForDay(week, _selectedDay);
    if (_clips.isEmpty) {
      await _closeEdit();
      return;
    }
    await _playAt(_index.clamp(0, _clips.length - 1));
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() => c.value.isPlaying ? c.pause() : c.play());
  }

  // ---- share ----
  Future<void> _shareDay() async {
    if (_sharing) return;
    final week = ref.read(reelProvider).value;
    final day = week?.dayOrNull(_selectedDay);
    if (day == null || day.isEmpty) return;

    _controller?.pause();
    setState(() => _sharing = true);
    _shareProgress.value = const ExportProgress(0, 1, 'กำลังเริ่ม…');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: ValueListenableBuilder<ExportProgress?>(
          valueListenable: _shareProgress,
          builder: (_, p, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: p?.fraction),
              const SizedBox(height: 16),
              Text(p?.message ?? 'กำลังประมวลผล…'),
            ],
          ),
        ),
      ),
    );

    try {
      final path = await ref
          .read(exportServiceProvider)
          .exportDay(day, onProgress: (p) => _shareProgress.value = p);
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      await ref.read(shareServiceProvider).shareVideo(path);
    } on ExportException catch (_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รวมวิดีโอไม่สำเร็จ')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
        // resume เล่นวิดีโอต่อ (กันค้างหลังปิด share sheet โดยไม่แชร์)
        if (!_editing) _controller?.play();
      }
    }
  }

  @override
  void dispose() {
    _edit.dispose();
    _shareProgress.dispose();
    _controller?.removeListener(_watch);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // โหลด/รีโหลดเมื่อ provider เปลี่ยน (ครั้งแรก + มีคลิปใหม่จากกล้อง)
    ref.listen<AsyncValue<WeekLog>>(reelProvider, (prev, next) {
      final w = next.value;
      if (w == null) return;
      if (!_initialLoaded) {
        _loadDay();
        return;
      }
      if (_editing) return;
      final now = clipsForDay(w, _selectedDay);
      final changed = now.length != _clips.length ||
          (now.isNotEmpty &&
              _clips.isNotEmpty &&
              now.last.id != _clips.last.id);
      if (changed) _loadDay();
    });

    final week = ref.watch(reelProvider).value;
    final daysWithClips = <DateTime>{
      if (week != null)
        for (final d in week.days.entries)
          if (d.value.clips.isNotEmpty) d.key,
    };
    final c = _controller;
    final t = _edit.value; // 0=home, 1=edit
    final showEdit = t > 0.001;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppToken.videoBackdrop,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // กรอบวิดีโอมน (ขนาดเท่าหน้ากล้อง)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragEnd: _onDaySwipe,
                        onTap: _editing ? _togglePlay : null,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (c != null && c.value.isInitialized)
                              FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: c.value.size.width,
                                  height: c.value.size.height,
                                  child: VideoPlayer(c),
                                ),
                              )
                            else if (_clips.isEmpty)
                              _EmptyDay(day: _selectedDay)
                            else
                              const ColoredBox(color: AppToken.videoBackdrop),

                            // overlay ในกรอบ (จางเมื่อ edit)
                            IgnorePointer(
                              ignoring: _editing,
                              child: Opacity(
                                opacity: (1 - t).clamp(0, 1),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      right: 12,
                                      child: StoryProgressBar(
                                        count: _clips.length,
                                        currentIndex: _index,
                                        progress: _progress,
                                      ),
                                    ),
                                    if (_clips.isNotEmpty &&
                                        _index < _clips.length)
                                      Positioned(
                                        top: 30,
                                        left: 12,
                                        child: TimeBadge(
                                            label: _clips[_index].label),
                                      ),
                                    Positioned(
                                      top: 64,
                                      left: 12,
                                      right: 12,
                                      child: const Align(
                                        alignment: Alignment.topCenter,
                                        child: CountdownBanner(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // ขอบ stroke primary ตอน edit mode
                            if (t > 0.001)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Opacity(
                                    opacity: t.clamp(0, 1),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(28),
                                        border: Border.all(
                                            color: DsColor.accent, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ปฏิทินใต้กรอบ (เลื่อนลง+จางเมื่อ edit) + เว้นที่ให้ tab ของ shell
                IgnorePointer(
                  ignoring: _editing,
                  child: Opacity(
                    opacity: (1 - t).clamp(0, 1),
                    child: FractionalTranslation(
                      translation: Offset(0, t * 1.6),
                      child: _calendarZone(daysWithClips),
                    ),
                  ),
                ),
                SizedBox(height: bottomPad + 60), // ที่ว่างสำหรับ tab
              ],
            ),
          ),

          // ปุ่ม share (ล่างซ้าย) + edit (ล่างขวา) — เลื่อนลง+จางเมื่อเข้า edit (เหมือน tab)
          if (_clips.isNotEmpty)
            Positioned(
              left: 24,
              bottom: bottomPad - 2,
              child: IgnorePointer(
                ignoring: _editing,
                child: Opacity(
                  opacity: (1 - t).clamp(0, 1),
                  child: FractionalTranslation(
                    translation: Offset(0, t * 2.2),
                    child: GlassCircle(
                      onTap: _sharing ? null : _shareDay,
                      child: const Icon(Icons.ios_share,
                          color: DsColor.white, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          if (_clips.isNotEmpty)
            Positioned(
              right: 24,
              bottom: bottomPad - 2,
              child: IgnorePointer(
                ignoring: _editing,
                child: Opacity(
                  opacity: (1 - t).clamp(0, 1),
                  child: FractionalTranslation(
                    translation: Offset(0, t * 2.2),
                    child: GlassCircle(
                      onTap: _enterEdit,
                      child: const Icon(Icons.tune,
                          color: DsColor.white, size: 22),
                    ),
                  ),
                ),
              ),
            ),

          // Edit header — เลื่อนลงจากบน
          if (showEdit)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FractionalTranslation(
                translation: Offset(0, t - 1),
                child: _editHeader(topPad),
              ),
            ),

          // Edit panel (trim) — เลื่อนขึ้นมาแทนที่ตำแหน่งเครื่องมือเดิม (ไม่มี bg)
          if (showEdit && _clips.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPad + 2,
              child: FractionalTranslation(
                translation: Offset(0, 1 - t),
                child: _editPanel(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _calendarZone(Set<DateTime> daysWithClips) {
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 150) widget.onCamera?.call();
      },
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 150) _enterEdit();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: WeekCalendarStrip(
          selectedDay: _selectedDay,
          daysWithClips: daysWithClips,
          onSelect: _selectDay,
        ),
      ),
    );
  }

  Widget _editHeader(double topPad) {
    return Padding(
      // เว้น 12px จากขอบกรอบวิดีโอเท่ากันทุกด้าน (กรอบ margin ซ้ายขวา 10 / บน 6)
      padding:
          EdgeInsets.only(top: topPad + 18, bottom: 10, left: 22, right: 22),
      child: Row(
        children: [
          GlassCircle(
            onTap: _closeEdit,
            child: const Icon(Icons.close, color: DsColor.white, size: 24),
          ),
          Expanded(
            child: Center(
              child: Text('แก้ไข',
                  style:
                      DsText.body(color: DsColor.white, weight: DsType.bold)),
            ),
          ),
          // ปุ่มบันทึก = primary (amber) ไอคอน check
          GestureDetector(
            onTap: _saveEdit,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: DsColor.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check,
                  color: DsColor.secondary, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Timeline(
          clips: _clips,
          selected: _index,
          startOf: (id) => _startDraft[id] ?? 0,
          endOf: (id) => _endDraft[id] ?? 0,
          durOf: (id) => _durDraft[id] ?? 1,
          playheadMs: _playheadMs,
          onSelect: _playAt,
          onChanged: _onTrimHandles,
          onDragStarted: () => setState(() => _dragging = true),
          onDragEnd: () => setState(() => _dragging = false),
        ),
        if (_dragging) TrashDropZone(onDelete: _deleteClip),
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.day});
  final DateTime day;

  static const _dowTh = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

  @override
  Widget build(BuildContext context) {
    final isToday = day == startOfDay(DateTime.now());
    final dow = _dowTh[day.weekday % 7];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppToken.emptyGradient,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.movie_creation_outlined,
              size: 64, color: DsColor.white.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            isToday ? 'ยังไม่มีคลิปวันนี้' : 'ไม่มีคลิป',
            style: DsText.display(
                size: DsType.h3, color: DsColor.white, weight: DsType.bold),
          ),
          const SizedBox(height: 6),
          Text('$dow ${day.day}/${day.month}',
              style: DsText.body(
                  size: DsType.sm, color: DsColor.white.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}
