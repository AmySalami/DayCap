import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/text_styles.dart';
import '../../models/clip.dart';

/// แผงตัดต่อ: แถบเดียวรวมทุกคลิป (filmstrip)
/// - แตะคลิป = เลือก (คลิปที่เลือกขึ้นกรอบเหลือง + มีที่จับซ้าย/ขวา)
/// - ลากที่จับซ้าย = ขอบซ้าย (ขอบขวานิ่ง, แถบเลื่อนชดเชย) · ขวา = ขอบขวา
/// - ลากพื้นที่ว่าง = เลื่อนแถบ (pan) · กดค้างคลิปแล้วลากลง = ลบ
class Timeline extends StatefulWidget {
  const Timeline({
    super.key,
    required this.clips,
    required this.selected,
    required this.startOf,
    required this.endOf,
    required this.durOf,
    required this.playheadMs,
    required this.onSelect,
    required this.onChanged,
    required this.onDragStarted,
    required this.onDragEnd,
  });

  final List<Clip> clips;
  final int selected;
  final int Function(String id) startOf;
  final int Function(String id) endOf;
  final int Function(String id) durOf;
  final int playheadMs;
  final ValueChanged<int> onSelect;
  final void Function(int start, int end) onChanged;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;

  static const int minGapMs = 500;

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline>
    with SingleTickerProviderStateMixin {
  static const double _pxPerSec = 42.0;
  static const double _scale = _pxPerSec / 1000.0; // px ต่อ ms (คงที่)
  static const double _handleW = 26;
  static const double _h = 44;
  static const double _gap = 6;
  static const double _pad = 12; // margin หัว/ท้ายแถบ
  static const double _minW = 56;

  double _offset = 0; // virtual scroll (px ที่เลื่อนไป, raw — display จะ clamp)

  // สถานะการลาก
  int _mode = 0; // 0 ไม่ลาก · 1 ที่จับซ้าย · 2 ที่จับขวา · 3 pan
  double _baseX = 0;
  double _baseOffset = 0;
  int _baseStart = 0;
  int _baseEnd = 0;
  double _baseWidth = 0;
  int? _liveStart;
  int? _liveEnd;

  // snapshot จาก build ล่าสุด (ใช้ใน gesture callback)
  List<double> _lastLefts = const [];
  double _lastOff = 0;
  double _lastMaxOff = 0;

  // momentum/inertia ตอน pan (ปัดแรง = พุ่งไกล)
  late final AnimationController _fling;

  @override
  void initState() {
    super.initState();
    _fling = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        final clamped = _fling.value.clamp(0.0, _lastMaxOff);
        setState(() => _offset = clamped);
        if (clamped != _fling.value) _fling.stop(); // ชนขอบ → หยุด
      });
  }

  @override
  void dispose() {
    _fling.dispose();
    super.dispose();
  }

  String get _selId => widget.clips[widget.selected].id;

  int _startOf(int i) {
    if (i == widget.selected && _liveStart != null) return _liveStart!;
    return widget.startOf(widget.clips[i].id);
  }

  int _endOf(int i) {
    if (i == widget.selected && _liveEnd != null) return _liveEnd!;
    return widget.endOf(widget.clips[i].id);
  }

  double _wOf(int i) {
    final w = (_endOf(i) - _startOf(i)) * _scale;
    return w < _minW ? _minW : w;
  }

  String _fmt(int ms) {
    final t = (ms / 1000).round();
    return '${(t ~/ 60).toString().padLeft(2, '0')}:'
        '${(t % 60).toString().padLeft(2, '0')}';
  }

  @override
  void didUpdateWidget(covariant Timeline old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      // แค่ล้าง live state — ไม่เลื่อนแถบ (คงตำแหน่งเดิมตามที่ผู้ใช้ต้องการ)
      _liveStart = null;
      _liveEnd = null;
      _mode = 0;
    }
  }

  void _dragStart(double x) {
    _fling.stop(); // แตะจับ = หยุด momentum ที่ค้างอยู่
    final sel = widget.selected;
    _baseX = x;
    _baseOffset = _lastOff;
    if (sel >= _lastLefts.length) {
      _mode = 3;
      return;
    }
    final selL = _lastLefts[sel] - _lastOff;
    final selW = _wOf(sel);
    final selR = selL + selW;
    if (x >= selL - 6 && x <= selL + _handleW) {
      _mode = 1;
    } else if (x >= selR - _handleW && x <= selR + 6) {
      _mode = 2;
    } else {
      _mode = 3;
      return;
    }
    _baseStart = _startOf(sel);
    _baseEnd = _endOf(sel);
    _baseWidth = selW;
    _liveStart = _baseStart;
    _liveEnd = _baseEnd;
  }

  void _dragUpdate(double x) {
    final total = x - _baseX;
    if (_mode == 1) {
      final ns = (_baseStart + total / _scale).round().clamp(
        0,
        _baseEnd - Timeline.minGapMs,
      );
      final nw = (_baseEnd - ns) * _scale;
      setState(() {
        _liveStart = ns;
        _offset = _baseOffset + (nw - _baseWidth); // คงขอบขวา
      });
      widget.onChanged(ns, _baseEnd);
    } else if (_mode == 2) {
      final dur = widget.durOf(_selId);
      final ne = (_baseEnd + total / _scale).round().clamp(
        _baseStart + Timeline.minGapMs,
        dur,
      );
      setState(() => _liveEnd = ne);
      widget.onChanged(_baseStart, ne);
    } else if (_mode == 3) {
      setState(() => _offset = (_baseOffset - total).clamp(0.0, _lastMaxOff));
    }
  }

  void _dragEnd([DragEndDetails? d]) {
    final wasPan = _mode == 3;
    final v = d?.primaryVelocity ?? 0;
    setState(() {
      _mode = 0;
      _liveStart = null;
      _liveEnd = null;
    });
    // ปัด (pan) แรงพอ → ปล่อยให้ไหลต่อด้วย friction physics (เหมือน scroll ปกติ)
    if (wasPan && v.abs() > 50 && _lastMaxOff > 0) {
      // _offset เพิ่มเมื่อปัดซ้าย (นิ้วไปทางลบ) → ความเร็วของ offset = -v
      _fling.animateWith(FrictionSimulation(0.135, _offset, -v));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final trimmed = _endOf(sel) - _startOf(sel);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ยาว ${_fmt(trimmed)}',
            style: DsText.body(
              size: DsType.sm,
              color: DsColor.white,
              weight: DsType.bold,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              final availW = c.maxWidth;
              // คำนวณตำแหน่ง/ความกว้างทุกคลิป
              final lefts = <double>[];
              var x = _pad;
              for (var i = 0; i < widget.clips.length; i++) {
                lefts.add(x);
                x += _wOf(i) + _gap;
              }
              final total = x - _gap + _pad;
              final maxOff = (total - availW).clamp(0.0, double.infinity);
              final off = _offset.clamp(0.0, maxOff);

              // เก็บ snapshot ให้ gesture ใช้
              _lastLefts = lefts;
              _lastOff = off;
              _lastMaxOff = maxOff;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (d) => _dragStart(d.localPosition.dx),
                onHorizontalDragUpdate: (d) => _dragUpdate(d.localPosition.dx),
                onHorizontalDragEnd: (d) => _dragEnd(d),
                onHorizontalDragCancel: () => _dragEnd(),
                child: SizedBox(
                  height: _h,
                  width: double.infinity,
                  child: ClipRect(
                    child: Stack(
                      children: [
                        for (var i = 0; i < widget.clips.length; i++)
                          Positioned(
                            left: lefts[i] - off,
                            top: 0,
                            bottom: 0,
                            width: _wOf(i),
                            child: _blockDraggable(i, _wOf(i)),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            'แตะเลือกคลิป · ลากที่จับเหลืองเพื่อตัด · กดค้างแล้วลากลงเพื่อลบ',
            style: DsText.body(size: DsType.badge, color: DsColor.whiteMid),
          ),
        ],
      ),
    );
  }

  Widget _blockDraggable(int i, double w) {
    final clip = widget.clips[i];
    final visual = i == widget.selected ? _selectedBlock(w) : _clipBlock(i, w);
    return LongPressDraggable<Clip>(
      data: clip,
      onDragStarted: widget.onDragStarted,
      onDragEnd: (_) => widget.onDragEnd(),
      onDraggableCanceled: (_, _) => widget.onDragEnd(),
      feedback: Material(
        color: Colors.transparent,
        child: _clipBlock(i, w, forceLabel: true),
      ),
      childWhenDragging: Opacity(opacity: 0.2, child: visual),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelect(i),
        child: visual,
      ),
    );
  }

  Widget _clipBlock(int i, double w, {bool forceLabel = false}) {
    final selected = i == widget.selected && !forceLabel;
    return Container(
      width: w,
      height: _h,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: DsColor.paper2,
        borderRadius: BorderRadius.circular(DsRadius.sm),
        border: selected ? Border.all(color: DsColor.accent, width: 3) : null,
      ),
      child: Text(
        widget.clips[i].label,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          color: DsColor.ink,
          fontWeight: DsType.bold,
          fontSize: DsType.caption,
        ),
      ),
    );
  }

  Widget _selectedBlock(double w) {
    final s = _startOf(widget.selected);
    final e = _endOf(widget.selected);
    final ph = widget.playheadMs;
    final showPh = ph > s && ph < e;
    final phX = ((ph - s) * _scale).clamp(0.0, w);

    return SizedBox(
      width: w,
      height: _h,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: DsColor.paper2,
                borderRadius: BorderRadius.circular(DsRadius.sm),
                border: Border.all(color: DsColor.accent, width: 3),
              ),
            ),
          ),
          if (showPh)
            Positioned(
              left: phX - 1,
              top: 4,
              bottom: 4,
              width: 2,
              child: const ColoredBox(color: DsColor.white),
            ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _handleW,
            child: _grip(left: true),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: _handleW,
            child: _grip(left: false),
          ),
        ],
      ),
    );
  }

  Widget _grip({required bool left}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DsColor.accent,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(left ? DsRadius.sm : 0),
          right: Radius.circular(left ? 0 : DsRadius.sm),
        ),
      ),
      child: Icon(
        left ? Icons.chevron_left : Icons.chevron_right,
        color: DsColor.secondary,
        size: 20,
      ),
    );
  }
}

/// โซนถังขยะ (โผล่ตอนลากคลิป) — ลากมาปล่อยเพื่อลบ
class TrashDropZone extends StatelessWidget {
  const TrashDropZone({super.key, required this.onDelete});
  final ValueChanged<Clip> onDelete;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Clip>(
      onAcceptWithDetails: (d) => onDelete(d.data),
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        return Container(
          height: 110,
          width: double.infinity,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ลากมาปล่อยเพื่อลบ',
                style: DsText.body(
                  size: DsType.sm,
                  color: active ? DsColor.ai2 : DsColor.whiteMid,
                  weight: DsType.bold,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: active ? 60 : 50,
                height: active ? 60 : 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? DsColor.ai2 : Colors.transparent,
                  border: Border.all(
                    color: active ? DsColor.ai2 : DsColor.whiteMid,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.delete,
                  color: active ? DsColor.white : DsColor.whiteMid,
                  size: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
