// lib/features/work/view/task_focus_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      systemNavigationBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workViewModelProvider.notifier).markTaskStarted(widget.taskId);
    });

    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final task = ref.read(workViewModelProvider.notifier).taskById(widget.taskId);
    final end = task?.scheduledEnd;
    if (end == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }
    final now = DateTime.now();
    setState(() {
      _remaining = end.isAfter(now) ? end.difference(now) : Duration.zero;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
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

            // Mark done
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _markDone(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24, width: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'MARK DONE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      letterSpacing: 3,
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
    await ref.read(workViewModelProvider.notifier).completeTask(widget.taskId);
    if (!context.mounted) return;
    _exit(context);
  }

  void _exit(BuildContext context) {
    if (context.canPop()) {
      context.pop();
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
            const Text('Task not found',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/work'),
              child: const Text('BACK',
                  style: TextStyle(color: Colors.white, letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }
}
