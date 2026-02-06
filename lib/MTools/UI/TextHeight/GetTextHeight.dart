//通过TextPainter来获取字体该有的高度。
import 'package:flutter/material.dart';

class TextSizeHelper{
  static Size GetTextSize({
    int? maxLines,
    double maxWidth = double.infinity,
    required String text,
    required TextStyle style,
  }) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: maxLines,
      textDirection: TextDirection.ltr,

    );

    textPainter.layout(maxWidth: maxWidth);
    return Size(textPainter.width, textPainter.height);
  }
  static double GetTextHeight({
    int? maxLines,
    double maxWidth = double.infinity,
    required String text,
    required TextStyle style,

  }){
    return GetTextSize(maxLines: maxLines,maxWidth: maxWidth,text: text, style: style).height;

  }


}