// lib/features/work/view/meeting_active_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../model/meeting_model.dart';
import '../viewmodel/work_viewmodel.dart';

const Color _micGreen = Color(0xFF2ECC71);

class MeetingActiveScreen extends ConsumerStatefulWidget {
  final String meetingId;
  const MeetingActiveScreen({required this.meetingId, super.key});

  @override
  ConsumerState<MeetingActiveScreen> createState() =>
      _MeetingActiveScreenState();
}

class _MeetingActiveScreenState extends ConsumerState<MeetingActiveScreen>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  late final AnimationController _pulse;
  MeetingModel? _meeting;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      systemNavigationBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    WakelockPlus.enable();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(workViewModelProvider.notifier)
          .startMeeting(widget.meetingId);
      _refreshMeeting();
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshMeeting();
    });
  }

  void _refreshMeeting() {
    final m =
        ref.read(workViewModelProvider.notifier).meetingById(widget.meetingId);
    if (m == null) {
      setState(() => _meeting = null);
      return;
    }
    // If actualStart is still missing (e.g. stale state before startMeeting
    // finished), kick startMeeting again — it now always sets actualStart.
    if (m.actualStart == null) {
      ref.read(workViewModelProvider.notifier).startMeeting(widget.meetingId);
    }
    final start = m.actualStart ?? DateTime.now();
    setState(() {
      _meeting = m;
      _elapsed = DateTime.now().difference(start);
      if (_elapsed.isNegative) _elapsed = Duration.zero;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _elapsedDisplay {
    final s = _elapsed.inSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return h > 0
        ? '${_two(h)}:${_two(m)}:${_two(sec)}'
        : '${_two(m)}:${_two(sec)}';
  }

  String _remainingDisplay(MeetingModel meeting) {
    final planned = Duration(minutes: meeting.durationMinutes);
    final remaining = planned - _elapsed;
    final d = remaining.isNegative ? (_elapsed - planned) : remaining;
    final h = d.inSeconds ~/ 3600;
    final m = (d.inSeconds % 3600) ~/ 60;
    final s = d.inSeconds % 60;
    final body = h > 0
        ? '${_two(h)}:${_two(m)}:${_two(s)}'
        : '${_two(m)}:${_two(s)}';
    return remaining.isNegative ? '+$body' : body;
  }

  bool _isOvertime(MeetingModel meeting) =>
      _elapsed.inMinutes >= meeting.durationMinutes;

  @override
  Widget build(BuildContext context) {
    final meeting = _meeting;
    if (meeting == null) return _missing(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close,
                    color: Colors.white24, size: 22),
                onPressed: () => _exit(context),
              ),
            ),

            const Spacer(),

            // Pulsing green mic
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final t = _pulse.value;
                final glowSize = 140 + 30 * t;
                final glowOpacity = 0.18 + 0.22 * (1 - t);
                return SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: glowSize,
                        height: glowSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _micGreen.withValues(alpha: glowOpacity),
                        ),
                      ),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _micGreen.withValues(alpha: 0.12),
                          border: Border.all(
                            color: _micGreen.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: _micGreen,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            const Text(
              'LIVE',
              style: TextStyle(
                color: _micGreen,
                fontSize: 11,
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                meeting.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Elapsed | Remaining — side-by-side with clear labels and divider
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    const Text(
                      'ELAPSED',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _elapsedDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: Colors.white12,
                ),
                Column(
                  children: [
                    Text(
                      _isOvertime(meeting) ? 'OVER' : 'LEFT',
                      style: TextStyle(
                        color: _isOvertime(meeting)
                            ? const Color(0xFFFF3B30)
                            : _micGreen,
                        fontSize: 9,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _remainingDisplay(meeting),
                      style: TextStyle(
                        color: _isOvertime(meeting)
                            ? const Color(0xFFFF3B30)
                            : _micGreen,
                        fontFamily: 'monospace',
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // Materials button (only if there's something to show)
            if (meeting.hasMaterials)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showMaterialsSheet(context, meeting),
                    icon: const Icon(Icons.description_outlined,
                        color: Colors.white54, size: 18),
                    label: const Text(
                      'VIEW MATERIALS',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 3,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                            color: Colors.white12, width: 0.5),
                      ),
                    ),
                  ),
                ),
              ),

            // End meeting — solid filled button for clear tap target
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _endMeeting(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'END MEETING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _endMeeting(BuildContext context) async {
    // Stop the per-second ticker so it can't keep refreshing _meeting and
    // hold the screen alive after we navigate.
    _ticker?.cancel();
    _ticker = null;

    // Capture the notifier and id BEFORE we navigate — `ref` may not be
    // valid once this widget is disposed.
    final notifier = ref.read(workViewModelProvider.notifier);
    final meetingId = widget.meetingId;

    // Navigate away IMMEDIATELY so the user sees the screen close. Don't
    // wait for state updates — they can finish in the background.
    if (context.mounted) {
      _exit(context);
    }

    // Persist the end-of-meeting state in the background (fire-and-forget).
    // Errors are swallowed so a hung tracking/notification call can't strand
    // the user on the live screen.
    () async {
      try {
        await notifier.endMeeting(meetingId);
      } catch (_) {}
    }();
  }

  void _exit(BuildContext context) {
    // Use Flutter's Navigator first (most reliable), falling back to
    // go_router only if there's no route to pop.
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      context.go('/work');
    }
  }

  void _showMaterialsSheet(BuildContext context, MeetingModel m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'MATERIALS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                m.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (m.hasAgenda) ...[
                const Text('AGENDA',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 2,
                    )),
                const SizedBox(height: 6),
                Text(
                  m.agenda!.trim(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (m.hasPrepNotes) ...[
                const Text('PREP NOTES',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 2,
                    )),
                const SizedBox(height: 6),
                Text(
                  m.prepNotes!.trim(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _missing(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Meeting not found',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/work'),
              child: const Text('BACK',
                  style:
                      TextStyle(color: Colors.white, letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }
}
