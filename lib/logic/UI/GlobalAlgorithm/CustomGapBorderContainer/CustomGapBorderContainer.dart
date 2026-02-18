import 'package:flutter/material.dart';
//这里可以贪一个Stack，只是动画效果比较困难。

class GapBorderContainer extends StatelessWidget {
  const GapBorderContainer({

    Key? key,
    this.decoration = const GapBorderDecoration(),

    this.contentPadding = const EdgeInsets.all(16.0),
    this.ignoreBorderWidth = false,

    this.child,



  }) : super(key: key);

  final GapBorderDecoration decoration;

  final EdgeInsetsGeometry contentPadding;
  //如果忽视线宽，则将线绘制在内部。contentPadding会偏小。
  //如果不忽视线宽，将子物体会在线宽基础上再缩进。视觉上符合contentPadding数值。
  final bool ignoreBorderWidth;
  final Widget? child;


  @override
  Widget build(BuildContext context) {

    return CustomPaint(
      painter: _GapBorderPainter(
        label: decoration.label,
        textStyle: decoration.labelStyle,
        borderSide: decoration.borderSide == null? BorderSide(color: Theme.of(context).colorScheme.outline,width: 2,):decoration.borderSide!,
        borderRadius: decoration.borderRadius,
        gapPadding: decoration.gapPadding,
        gapAlignment: decoration.labelGapAlignment,
        context: context,
      ),
      //size: Size(10, 100),
      child: Padding(
        padding: !ignoreBorderWidth && decoration.borderSide != null? EdgeInsetsGeometry.all(decoration.borderSide!.width).add(contentPadding):contentPadding , // 内容内边距
        child: child,
      ),
    );
  }
}

class _GapBorderPainter extends CustomPainter {
  final String? label;
  final TextStyle? textStyle;

  final BorderSide borderSide;
  final BorderRadius borderRadius;
  final double gapPadding;

  final GapTextAlignment gapAlignment;

  final BuildContext context;

  _GapBorderPainter(
      {this.label,
        this.textStyle,
        required this.borderSide,
        required this.borderRadius,
        required this.gapPadding,
        required this.gapAlignment,
        required this.context,

      });

  @override
  void paint(Canvas canvas, Size size) {

    if(label == null){
      final border = OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: borderSide,
        //gapPadding: gapPadding, // 这个参数不影响绘制，我们手动传 gapExtent
      );

      // 手动调用 paint，传入缺口参数
      border.paint(
        canvas,
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    }

    final textSpan = TextSpan(
      text: label,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final textWidth = textPainter.width + gapPadding * 2;
    final textHeight = textPainter.height;

    // 缺口起始位置（这里让缺口位于左边 16dp 处）
    double gapStart = 16.0;
    switch(gapAlignment){
      case GapTextAlignment.topCenter:
        gapStart = (size.width - textWidth)*0.5;
        break;
      case GapTextAlignment.topRight:
        gapStart = size.width - textWidth - gapStart;
      default:
        break;
    }

    final border = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: borderSide,
      gapPadding: gapPadding, // 这个参数不影响绘制，我们手动传 gapExtent
    );

    // 手动调用 paint，传入缺口参数
    border.paint(
      canvas,
      Rect.fromLTWH(0, 0, size.width, size.height),
      gapStart: gapStart,
      gapExtent: textWidth,
      gapPercentage: 1.0,
      textDirection: TextDirection.ltr,
    );

    // 绘制文本（放在缺口正上方）
    textPainter.paint(
      canvas,
      Offset(gapStart + gapPadding, -textHeight *0.5), // 骑在边框上
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GapBorderDecoration{
  const GapBorderDecoration({

    this.label = "label",
    this.labelStyle,
    this.labelGapAlignment = GapTextAlignment.topCenter,

    //没实装，暂时没啥用。
    this.hint = "hint",
    this.hintStyle,
    this.hintGapAlignment = GapTextAlignment.bottomLeft,

    this.third = "third",
    this.thirdStyle,
    this.thirdGapAlignment = GapTextAlignment.bottomLeft,


    this.borderSide,
    this.borderRadius = const BorderRadius.all(Radius.circular(4.0)),
    this.gapPadding = 5,


  });

  final String? label;
  final TextStyle? labelStyle;
  final GapTextAlignment labelGapAlignment;

  final String? hint;
  final TextStyle? hintStyle;
  final GapTextAlignment hintGapAlignment;

  final String? third;
  final TextStyle? thirdStyle;
  final GapTextAlignment thirdGapAlignment;

  final BorderSide? borderSide;
  final BorderRadius borderRadius;
  final double gapPadding; // 文本两侧留白


}

enum GapTextAlignment{
  topLeft,
  topCenter,
  topRight,

  bottomLeft,
  bottomCenter,
  bottomRight,


}