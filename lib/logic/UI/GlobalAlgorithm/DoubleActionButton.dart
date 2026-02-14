import 'package:flutter/material.dart';

/// 圆角双按钮组件（左右按钮 + 中间分隔线） by deepseek
class DoubleActionButton extends StatelessWidget {
  //final String leftText;
  //final String rightText;
  final Widget? lChild;
  final Widget? rChild;
  final VoidCallback? onLeftPressed;
  final VoidCallback? onRightPressed;
  final Color? borderColor;
  final double borderRadius;
  final double borderWidth;
  final Color? leftBackgroundColor;
  final Color? rightBackgroundColor;
  //final TextStyle? leftTextStyle;
  //final TextStyle? rightTextStyle;
  final double height;
  final double width;
  final EdgeInsetsGeometry padding;

  const DoubleActionButton({
    super.key,
    //required this.leftText,
    //required this.rightText,
    this.onLeftPressed,
    this.onRightPressed,
    this.borderColor,
    this.borderRadius = 12.0,
    this.borderWidth = 1.0,
    this.leftBackgroundColor,
    this.rightBackgroundColor,
    this.height = 48.0,
    this.width = 100,
    this.padding = EdgeInsets.zero,
    this.lChild,
    this.rChild,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBorderColor = theme.dividerColor;
    final defaultTextStyle = theme.textTheme.labelLarge ?? const TextStyle();

    return Container(
      height: height,
      width: width,
      //padding: padding,
      //child: DecoratedBox(//这个是关键，可以绕过container的边框占用。
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor ?? defaultBorderColor,
            width: borderWidth,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),

        child: Row(
          children: [
            // 左按钮
            Expanded(
              child: _buildButtonArea(
                child: lChild,
                onPressed: onLeftPressed,
                backgroundColor: leftBackgroundColor,
                //textStyle: leftTextStyle ?? defaultTextStyle,
                borderRadius: borderRadius,
                isLeft: true,
              ),
            ),
            // 中间分隔线
            Container(
              width: 2.0,
              height: height * 0.6, // 分隔线高度为按钮高度的60%
              color: borderColor ?? defaultBorderColor,
            ),
            // 右按钮
            Expanded(
              child: _buildButtonArea(
                child: rChild,
                onPressed: onRightPressed,
                backgroundColor: rightBackgroundColor,
                //textStyle: rightTextStyle ?? defaultTextStyle,
                borderRadius: borderRadius,
                isLeft: false,
              ),
            ),
          ],
        ),
     // ),
    );
  }

  Widget _buildButtonArea({
    //required String text,
    required Widget? child,
    required VoidCallback? onPressed,
    required Color? backgroundColor,
    //required TextStyle textStyle,
    required double borderRadius,
    required bool isLeft,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.horizontal(
        left: Radius.circular(isLeft ? borderRadius : 0),
        right: Radius.circular(isLeft ? 0 : borderRadius),
      ),
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),

    );
  }
}