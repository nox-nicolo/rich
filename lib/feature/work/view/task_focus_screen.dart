// lib/features/work/view/task_focus_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/services/tick_sound_service.dart';
import '../viewmodel/work_viewmodel.dart';

class TaskFocusScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskFocusScreen({required this.taskId, super.key});

  @override
  ConsumerState<TaskFocusScreen> createState() => _TaskFocusScreenState();
}

class _TaskFocusScreenState extends ConsumerState<TaskFocusScreen> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Force black system UI to match the screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        systemNavigationBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workViewModelProvider.notifier).markTaskStarted(widget.taskId);
    });

    WakelockPlus.enable();
    // Prime the 443Hz tick generator so the very first second doesn't
    // have audible startup lag.
    TickSoundService.instance.prime();
    _tick(playSound: false); // initial render — don't tick on entry
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(playSound: true),
    );
  }

  void _tick({bool playSound = true}) {
    final task = ref
        .read(workViewModelProvider.notifier)
        .taskById(widget.taskId);
    final end = task?.scheduledEnd;
    if (end == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }
    final now = DateTime.now();
    final next = end.difference(now);
    setState(() {
      _remaining = next;
    });
    // 443Hz tick — only while time is still counting down. Stops the moment
    // the countdown hits zero so the user isn't ticked at after the deadline.
    if (playSound && next.inSeconds > 0) {
      TickSoundService.instance.tick();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  String get _display {
    final total = _remaining.inSeconds;
    final overrun = total <= 0;
    final secs = overrun ? -total : total;
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    final body = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return overrun ? '+$body' : body;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workViewModelProvider);
    final matches = state.todayTasks.where((t) => t.id == widget.taskId);
    if (matches.isEmpty) return _missing(context);
    final task = matches.first;

    final overrun = _remaining.inSeconds <= 0;
    final color = overrun ? const Color(0xFFFF3B30) : Colors.white;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — minimal close button only
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white24, size: 22),
                onPressed: () => _exit(context),
              ),
            ),

            const Spacer(),

            // Task title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                task.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Countdown
            Text(
              _display,
              style: TextStyle(
                color: color,
                fontFamily: 'monospace',
                fontFeatures: const [FontFeature.tabularFigures()],
                fontSize: 72,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              overrun ? 'OVER' : 'REMAINING',
              style: TextStyle(
                color: overrun ? const Color(0xFFFF3B30) : Colors.white24,
                fontSize: 10,
                letterSpacing: 3,
              ),
            ),

            const Spacer(),

            // Mark done — solid filled button for clear visual + tap target
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _markDone(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'MARK DONE',
                    style: TextStyle(
                      color: Colors.black,
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

  Future<void> _markDone(BuildContext context) async {
    // Stop the ticker so it can't keep rebuilding the screen during exit.
    _ticker?.cancel();
    _ticker = null;

    // Capture the notifier and id BEFORE we navigate — `ref` may not be
    // valid once this widget is disposed.
    final notifier = ref.read(workViewModelProvider.notifier);
    final taskId = widget.taskId;

    // Navigate away IMMEDIATELY so the user sees the screen close.
    if (context.mounted) {
      _exit(context);
    }

    // Persist the completion in the background (fire-and-forget). Errors
    // are swallowed so a hung tracking/vibration call can't strand the user.
    () async {
      try {
        await notifier.completeTask(taskId);
      } catch (_) {}
    }();
  }

  void _exit(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      context.go('/work');
    }
  }

  Widget _missing(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Task not found',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/work'),
              child: const Text(
                'BACK',
                style: TextStyle(color: Colors.white, letterSpacing: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
