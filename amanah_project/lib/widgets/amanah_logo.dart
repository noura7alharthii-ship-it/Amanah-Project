import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AmanahLogo extends StatelessWidget {
  final double size;
  const AmanahLogo({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) {
    // Arabic uses ArefRuqaa; English uses Inter
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'أمانة',
            style: TextStyle(
              fontFamily: 'ArefRuqaa',
              fontSize: size,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
              height: 1.1,
            ),
          ),
          TextSpan(
            text: ' | ',
            style: TextStyle(
              fontSize: size * 0.85,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: 'Amanah',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: size * 0.92,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}
