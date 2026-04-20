import 'package:flutter/material.dart';

class PinPad extends StatelessWidget {
  final Function(String) onNumber;
  final VoidCallback onBackspace;

  const PinPad({
    super.key,
    required this.onNumber,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final numbers = [
      '1','2','3',
      '4','5','6',
      '7','8','9',
      '','0','<',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GridView.builder(
        shrinkWrap: true,
        itemCount: numbers.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final value = numbers[index];

          if (value == '') {
            return const SizedBox.shrink();
          }

          if (value == '<') {
            return _buildButton(
              icon: Icons.backspace_outlined,
              onTap: onBackspace,
            );
          }

          return _buildButton(
            label: value,
            onTap: () => onNumber(value),
          );
        },
      ),
    );
  }

  Widget _buildButton({
    String? label,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 26)
              : Text(
                  label ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}