import 'package:flutter/material.dart';

class NodePresentation extends StatelessWidget {
  const NodePresentation({super.key, this.width, this.height, this.textAlign = TextAlign.center, required this.text, this.bgColor = Colors.white, this.fontColor = Colors.black,});
  final String text;
  final Color? bgColor;
  final Color? fontColor;
  final double? width;
  final double? height;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ErrorWidget("废弃类别用");

  }
}
