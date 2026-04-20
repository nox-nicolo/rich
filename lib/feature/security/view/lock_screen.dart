import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rich/feature/security/view/widget/biometric_button.dart';
import 'package:rich/feature/security/view/widget/pin_pad.dart';

import '../viewmodel/app_lock_viewmodel.dart';


class LockScreen extends ConsumerWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appLockViewModelProvider);
    final vm = ref.read(appLockViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            /// 🔒 Title
            Text(
              'Unlock RICH',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            /// Error
            if (state.errorMessage != null)
              Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),

            const SizedBox(height: 24),

            /// PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final filled = index < state.pinInput.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? Colors.white : Colors.grey.shade700,
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            /// Biometric
            if (state.canUseBiometrics)
              BiometricButton(
                onPressed: () async {
                  await vm.tryBiometricUnlock();
                },
              ),

            const Spacer(),

            /// PIN PAD
            PinPad(
              onNumber: (n) async {
                vm.appendPinDigit(n);

                if (ref.read(appLockViewModelProvider).pinInput.length == 6) {
                  await vm.verifyPinAndUnlock(
                    ref.read(appLockViewModelProvider).pinInput,
                  );
                }
              },
              onBackspace: vm.removeLastPinDigit,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}