import 'package:flutter/material.dart';

class BiometricButton extends StatelessWidget {
  final VoidCallback onPressed;

  const BiometricButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: const Icon(
            Icons.fingerprint,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Use fingerprint',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}