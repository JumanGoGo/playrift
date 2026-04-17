import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0A1E),
            Color(0xFF0F0614),
            Color(0xFF1A0A1E),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: height > 60 ? 14 : 8,
                vertical: height > 60 ? 5 : 3,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFFEF4444).withAlpha(180), width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('18+',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w800,
                    fontSize: height > 60 ? 16 : 10,
                    letterSpacing: 1,
                  )),
            ),
            if (height > 80) ...[
              const SizedBox(height: 6),
              Text('CONTENIDO\nRESTRINGIDO',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    height: 1.4,
                  )),
            ],
          ],
        ),
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }
}
