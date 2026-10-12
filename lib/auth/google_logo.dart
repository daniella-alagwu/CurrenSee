import 'package:flutter/material.dart';

//google logo for social login button
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: const CustomPaint(painter: _GoogleLogoPainter()),
      );
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static void _fill(Canvas canvas, double scale, Color color, void Function(Path) build) {
    final path = Path();
    build(path);
    canvas.drawPath(
      path.transform((Matrix4.identity()..scale(scale, scale)).storage),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48; // the logo is drawn on a 48 x 48 grid
    _fill(canvas, scale, const Color(0xFFEA4335), (p) {
      p.moveTo(24, 9.5);
      p.cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1);
      p.lineTo(40.06, 6.25);
      p.cubicTo(35.9, 2.38, 30.47, 0, 24, 0);
      p.cubicTo(14.62, 0, 6.51, 5.38, 2.56, 13.22);
      p.lineTo(10.54, 19.41);
      p.cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5);
      p.close();
    });
    _fill(canvas, scale, const Color(0xFF4285F4), (p) {
      p.moveTo(46.98, 24.55);
      p.cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20);
      p.lineTo(24, 20);
      p.lineTo(24, 29.02);
      p.lineTo(36.94, 29.02);
      p.cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2);
      p.lineTo(39.89, 42.2);
      p.cubicTo(44.4, 38.02, 46.98, 31.84, 46.98, 24.55);
      p.close();
    });
    _fill(canvas, scale, const Color(0xFFFBBC05), (p) {
      p.moveTo(10.53, 28.59);
      p.cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24);
      p.cubicTo(9.77, 22.4, 10.04, 20.86, 10.53, 19.41);
      p.lineTo(2.55, 13.22);
      p.cubicTo(0.92, 16.46, 0, 20.12, 0, 24);
      p.cubicTo(0, 27.88, 0.92, 31.54, 2.56, 34.78);
      p.lineTo(10.53, 28.59);
      p.close();
    });
    _fill(canvas, scale, const Color(0xFF34A853), (p) {
      p.moveTo(24, 48);
      p.cubicTo(30.48, 48, 35.93, 45.87, 39.89, 42.19);
      p.lineTo(32.16, 36.19);
      p.cubicTo(30.01, 37.64, 27.24, 38.49, 24, 38.49);
      p.cubicTo(17.74, 38.49, 12.43, 34.27, 10.53, 28.58);
      p.lineTo(2.55, 34.77);
      p.cubicTo(6.51, 42.62, 14.62, 48, 24, 48);
      p.close();
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}