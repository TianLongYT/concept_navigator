import 'package:flutter/material.dart';

class DebugUI extends StatelessWidget {
  const DebugUI({super.key, this.size});
  final Size? size;

  DebugUI.pointer({this.size = const Size(100.0,100.0)}){

  }
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: this.size!,
      painter: CustomCrossPainter(),
    );
  }
}
class CustomCrossPainter extends CustomPainter{
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.purpleAccent
      ..style = PaintingStyle.fill
      ..strokeWidth = 4;


    canvas.drawLine(Offset(-size.width,0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(0,-size.height), Offset(0,size.height), paint);


  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}
