import 'package:flutter/material.dart';



class PopInspector extends StatefulWidget {
  const PopInspector({super.key, required this.child,
    required this.isPop,
    required this.landscapePopWidth,
    this.landscapeContractWidth = 10,
    required this.landscapeHeight,
    required this.portraitPopHeight,
    this.portraitContractHeight = 10,
    required this.portraitWidth,
    //装饰物//伸缩棒。

  });

  final Widget child;
  final bool isPop;

  final double landscapePopWidth;
  final double? landscapeContractWidth;
  final double landscapeHeight;

  final double portraitPopHeight;
  final double? portraitContractHeight;
  final double portraitWidth;



  @override
  State<PopInspector> createState() => _PopInspectorState();
}

class _PopInspectorState extends State<PopInspector> {
  @override
  Widget build(BuildContext context) {
    // 获取屏幕方向
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // 竖屏时编辑栏从右侧伸出，横屏时从底部伸出
    double widgetWidth = widget.portraitWidth;
    double widgetHeight = widget.landscapeHeight;



    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      left: isLandscape? (widget.isPop? widgetWidth - widget.landscapePopWidth:widgetWidth - widget.landscapeContractWidth!):0,
      top: isLandscape? 0 : widget.isPop? widgetHeight - widget.portraitPopHeight : widgetHeight - widget.portraitContractHeight!,


      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: isLandscape ? widget.landscapePopWidth : widgetWidth,
        // 横屏时宽度限制200，高度整个屏幕。
        height: isLandscape ? widgetHeight : widget.portraitPopHeight,
        // 竖屏时高度限制300，宽度整个屏幕。
        color: Colors.blueAccent,
        child: isLandscape ? Row(
          children: [
            Container(
              width: 10,
              height: widgetHeight,
              color: Colors.black,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius
                          .circular(20), bottom: Radius.circular(10))
                  ),
                  width: 10 * 0.5,
                  height: widgetHeight * 0.5,
                  //color: Colors.white,
                ),
              ),
            ),

            Expanded(child: widget.child),
          ],
        ) :
        Column(
          children: [
            Container(
              width: widgetWidth,
              height: 10,
              color: Colors.black,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius
                          .circular(20), bottom: Radius.circular(10))
                  ),
                  width: widgetWidth * 0.5,
                  height: 10 * 0.5,
                  //color: Colors.white,
                ),
              ),
            ),
            Expanded(child: widget.child),
          ],
        ),

      ),
    );

  }
}
