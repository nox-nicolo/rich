// lib/features/overlay/view/overlay_hud.dart
//
// The full-screen overlay HUD. This is the root widget
// rendered inside the Android overlay window via the
// foreground service. It hosts the draggable pill.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/overlay_viewmodel.dart';
import 'overlay_pill_widget.dart';

class OverlayHud extends ConsumerWidget {
  const OverlayHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(overlayViewModelProvider);

    // Full transparent screen — only the pill is visible
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Transparent full-screen tap interceptor — collapsed when not expanded
            if (state.isExpanded)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () =>
                      ref.read(overlayViewModelProvider.notifier).collapse(),
                  child: Container(color: Colors.transparent),
                ),
              ),

            // The draggable pill
            OverlayPillWidget(key: const ValueKey('overlay_pill')),
          ],
        ),
      ),
    );
  }
}
