// lib/core/widgets/rich_divider.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RichDivider extends StatelessWidget {
  final double indent;
  final double endIndent;
  final double thickness;

  const RichDivider({
    this.indent = 0,
    this.endIndent = 0,
    this.thickness = 0.5,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.divider,
      thickness: thickness,
      height: 1,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

class RichVerticalDivider extends StatelessWidget {
  final double height;
  final double thickness;

  const RichVerticalDivider({
    this.height = 32,
    this.thickness = 0.5,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: thickness,
      height: height,
      color: AppColors.divider,
    );
  }
}
