import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:flutter/material.dart';


///废弃类，别用。直接用内置的绘制方法画出的图形要好一万倍。
class NodePainter extends CustomPainter {

  final NodeDrawingData drawingData;
  const NodePainter({required this.drawingData});

  @override
  void paint(Canvas canvas, Size size) {

    NodeAppearance nodeAppearance = drawingData.nodeAppearance;
    //double emptyRadio = (nodeAppearance.emptySize - 1) * 0.5;
    //emptyRadio = emptyRadio>0? emptyRadio:0;
    final Size coreSize = nodeAppearance.nodeSize;
    final Rect coreRect = Rect.fromLTWH(0, 0, coreSize.width, coreSize.height);//Rect.fromCenter(center : Offset(0,0),width:  nodeAppearance.nodeSize.width,height: nodeAppearance.nodeSize.height);
    final RRect coreRRect = RRect.fromRectAndRadius(coreRect, Radius.circular(coreSize.height * 0.1));
    // 绘制核心节点
    final Paint paint = Paint()
      ..color = nodeAppearance.nodeColor
      ..style = PaintingStyle.fill;

    switch(nodeAppearance.shape){
      case Shape.rect:
        canvas.drawRect(coreRect,paint);
        break;
      case Shape.rRect:
        canvas.drawRRect(coreRRect, paint);
        break;
      default:

        break;
    }

    //绘制文字。
    // 设置文字样式
    final TextStyle textStyle = TextStyle(
      color: nodeAppearance.fontColor,
      fontSize: _getTextSize(coreSize), // 动态计算文字大小
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(text: drawingData.text, style: textStyle);

    // 使用 TextPainter 绘制文字
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,

    );

    // 布局文字，使其自适应
    textPainter.layout(maxWidth: coreSize.width*0.9);

    // 计算文字绘制的位置（居中）
    final Offset offset = Offset(//emptyRadio * coreSize.width,emptyRadio * coreSize.height
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    canvas.save();
    canvas.clipRRect(coreRRect);
    // 绘制文字
    textPainter.paint(canvas, offset);
    canvas.restore();

    //绘制子节点。。。。。

  }
  double _getTextSize(Size size) {
    // 根据矩形的宽度调整文字大小，可以根据需要自定义逻辑
    return size.width * 0.15; // 比如根据宽度的 15% 来计算文字大小
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}
//size: Size(100,1999),//,

//canvas.drawRect(Rect.fromCenter(center:  Offset(size.width / 2, size.height / 2),width:  400,height: 100), paint);
