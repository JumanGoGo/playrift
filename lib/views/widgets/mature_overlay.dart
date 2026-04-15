import 'package:flutter/material.dart';

class MatureOverlay extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const MatureOverlay({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: width,
      height: height,
      color: const Color(0xFF1A0010),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.shade700, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '18+',
              style: TextStyle(
                color: Colors.red.shade400,
                fontWeight: FontWeight.bold,
                fontSize: height > 60 ? 18 : 13,
              ),
            ),
          ),
          if (height > 60) ...[
            const SizedBox(height: 6),
            Text(
              'Contenido\npara adultos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ]
        ],
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }
}