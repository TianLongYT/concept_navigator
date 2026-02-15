import 'package:concept_navigator/logic/UI/EditPanel/NodeMoveComponent/NodeMoveJoystick/MJoystickEnum.dart';
import 'package:flutter/material.dart';

/// 摇杆背景组件（正方形 + 四方向梯形 + 中心方块） by deepSeek
class MJoystickSquireBase extends StatelessWidget {

  final Duration animationDuration; // 颜色过渡动画时长
  final double size;                // 整体正方形边长
  final double trapezoidHeight;     // 梯形高度（边框厚度）
  final Map<EJoystickDirection, bool> highlighted; // 各区域高亮状态
  final Map<EJoystickDirection, Color> baseColors; // 各区域基础颜色
  final Map<EJoystickDirection, Color> highlightColors; // 各区域高亮颜色
  final Map<EJoystickDirection, IconData> icons; // 方向图标（中心可不传）
  final double iconSize;           // 图标大小
  final Color iconColor;          // 图标颜色
  final Color? borderColor;      // 边框颜色，null 表示不绘制边框
  final double borderWidth;      // 边框宽度
  final BorderRadiusGeometry borderRadius; // 圆角半径（默认无圆角）
  final Color? outerBorderColor;           // 外边框颜色（null 表示不绘制）
  final double outerBorderWidth;          // 外边框宽度

  const MJoystickSquireBase({
    super.key,
    this.animationDuration = const Duration(milliseconds: 200), // 新增
    required this.size,
    required this.trapezoidHeight,
    required this.highlighted,
    this.baseColors = const {},
    this.highlightColors = const {},
    this.icons = const {
      EJoystickDirection.left:Icons.keyboard_double_arrow_left,
      EJoystickDirection.right:Icons.keyboard_double_arrow_right,
      EJoystickDirection.top:Icons.keyboard_double_arrow_up,
      EJoystickDirection.bottom:Icons.keyboard_double_arrow_down,
    },
    this.iconSize = 24.0,
    this.iconColor = Colors.white,
    this.borderColor,            // 新增，默认 null 不绘制
    this.borderWidth = 1.0,      // 新增，默认宽度

    this.borderRadius = BorderRadius.zero,   // 新增，默认无圆角
    this.outerBorderColor,                  // 新增，默认不绘制
    this.outerBorderWidth = 1.0,           // 新增，默认宽度
  })  : assert(trapezoidHeight <= size / 2,
  '梯形高度不能超过边长的一半，否则中心区域会消失');
  MJoystickSquireBase.all({
    super.key,
    this.animationDuration = const Duration(milliseconds: 200), // 新增
    required this.size,
    required double trapezoidHeightInput,
    required this.highlighted,
    Color? centerBaseColor,
    Color? centerHighlightColor,
    Color baseColor = Colors.white38,
    Color highlightColor = Colors.white,

    this.icons = const {
      EJoystickDirection.left: Icons.keyboard_double_arrow_left,
      EJoystickDirection.right: Icons.keyboard_double_arrow_right,
      EJoystickDirection.top: Icons.keyboard_double_arrow_up,
      EJoystickDirection.bottom: Icons.keyboard_double_arrow_down,
    },
    this.iconSize = 24.0,
    this.iconColor = Colors.white,
    this.borderColor,           // 新增
    this.borderWidth = 1.0,     // 新增

    this.borderRadius = BorderRadius.zero,
    this.outerBorderColor,
    this.outerBorderWidth = 1.0, //绘制的线的一半会被裁剪。

  }) :baseColors = {EJoystickDirection.left:baseColor,EJoystickDirection.right:baseColor,EJoystickDirection.top:baseColor,EJoystickDirection.bottom:baseColor,EJoystickDirection.center:centerBaseColor ?? baseColor,},
  highlightColors = {EJoystickDirection.left:highlightColor,EJoystickDirection.right:highlightColor,EJoystickDirection.top:highlightColor,EJoystickDirection.bottom:highlightColor,EJoystickDirection.center: centerHighlightColor??highlightColor},
        trapezoidHeight = trapezoidHeightInput > size / 2 ? size / 2:trapezoidHeightInput;
        //assert(trapezoidHeight <= size / 2,'梯形高度不能超过边长的一半，否则中心区域会消失');


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ,
      height: size ,

      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // ---------- 1. 五个背景色块（通过裁剪实现形状）----------
            _buildClippedRegion(
              direction: EJoystickDirection.top,
              clipper: _TopClipper(trapezoidHeight: trapezoidHeight),
            ),
            _buildClippedRegion(
              direction: EJoystickDirection.bottom,
              clipper: _BottomClipper(trapezoidHeight: trapezoidHeight),
            ),
            _buildClippedRegion(
              direction: EJoystickDirection.left,
              clipper: _LeftClipper(trapezoidHeight: trapezoidHeight),
            ),
            _buildClippedRegion(
              direction: EJoystickDirection.right,
              clipper: _RightClipper(trapezoidHeight: trapezoidHeight),
            ),
            _buildClippedRegion(
              direction: EJoystickDirection.center,
              clipper: _CenterClipper(trapezoidHeight: trapezoidHeight),
            ),

            // ---------- 2. 方向图标（精确居中对齐）----------
            _buildIcon(EJoystickDirection.top)!,
            _buildIcon(EJoystickDirection.bottom)!,
            _buildIcon(EJoystickDirection.left)!,
            _buildIcon(EJoystickDirection.right)!,
            if (icons.containsKey(EJoystickDirection.center))
              _buildIcon(EJoystickDirection.center)!,

            if (borderColor != null)
              CustomPaint(
                size: Size(size, size),
                painter: _JoystickBorderPainter(
                  size: size,
                  trapezoidHeight: trapezoidHeight,
                  borderColor: borderColor!,
                  borderWidth: borderWidth,
                ),
              ),
            if (outerBorderColor != null)
              CustomPaint(
                size: Size(size, size),
                painter: _OuterBorderPainter(
                  size: size,
                  borderRadius: borderRadius,
                  borderColor: outerBorderColor!,
                  borderWidth: outerBorderWidth,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 构建单个裁剪区域（背景色）
  Widget _buildClippedRegion({
    required EJoystickDirection direction,
    required CustomClipper<Path> clipper,
  }) {
    final bool isHighlighted = highlighted[direction] ?? false;
    final Color defaultBase = _defaultBaseColor(direction);
    final Color defaultHighlight = _defaultHighlightColor(direction);

    final Color color = isHighlighted
        ? (highlightColors[direction] ?? defaultHighlight)
        : (baseColors[direction] ?? defaultBase);

    return Positioned.fill(
      child: ClipPath(
        clipper: clipper,
        child: TweenAnimationBuilder(
          tween: ColorTween(end: color), // begin = null → 自动从当前色开始
          duration: animationDuration,
          curve: Curves.easeOut,               // 你可以自定义曲线
          builder: (context, color, _) {
            return Container(color: color);    // 每一帧刷新颜色
          },
        ),
      ),
    );
  }

  // 构建单个方向图标
  Widget? _buildIcon(EJoystickDirection direction) {
    if (!icons.containsKey(direction)) return null;
    final Offset center = _regionCenter(direction);
    return Positioned(
      left: center.dx - iconSize / 2,
      top: center.dy - iconSize / 2,
      width: iconSize,
      height: iconSize,
      child: Icon(
        icons[direction],
        color: iconColor,
        size: iconSize,
      ),
    );
  }

  // 计算各区域几何中心（用于放置图标）
  Offset _regionCenter(EJoystickDirection direction) {
    final t = trapezoidHeight;
    final half = size / 2;
    switch (direction) {
      case EJoystickDirection.top:
        return Offset(half, t * 0.5);
      case EJoystickDirection.bottom:
        return Offset(half, size - t * 0.5);
      case EJoystickDirection.left:
        return Offset(t * 0.5, half);
      case EJoystickDirection.right:
        return Offset(size - t * 0.5, half);
      case EJoystickDirection.center:
        return Offset(half, half);
    }
  }

  // 默认基础颜色（低饱和度灰）
  Color _defaultBaseColor(EJoystickDirection direction) => Colors.grey.shade800;

  // 默认高亮颜色（带透明度的主题色）
  Color _defaultHighlightColor(EJoystickDirection direction) {
    switch (direction) {
      case EJoystickDirection.top:
        return Colors.blue.withOpacity(0.7);
      case EJoystickDirection.bottom:
        return Colors.green.withOpacity(0.7);
      case EJoystickDirection.left:
        return Colors.orange.withOpacity(0.7);
      case EJoystickDirection.right:
        return Colors.purple.withOpacity(0.7);
      case EJoystickDirection.center:
        return Colors.red.withOpacity(0.7);
    }
  }
}


// ---------- 四个梯形 + 中心矩形的 Clipper ----------

class _TopClipper extends CustomClipper<Path> {
  final double trapezoidHeight;
  _TopClipper({required this.trapezoidHeight});

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    final t = trapezoidHeight;
    final centerW = w - 2 * t;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w - t, t)
      ..lineTo(t, t)
      ..close();
  }

  @override
  bool shouldReclip(covariant _TopClipper oldClipper) =>
      oldClipper.trapezoidHeight != trapezoidHeight;
}

class _BottomClipper extends CustomClipper<Path> {
  final double trapezoidHeight;
  _BottomClipper({required this.trapezoidHeight});

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    final t = trapezoidHeight;
    final centerW = w - 2 * t;
    return Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      ..lineTo(w - t, h - t)
      ..lineTo(t, h - t)
      ..close();
  }

  @override
  bool shouldReclip(covariant _BottomClipper oldClipper) =>
      oldClipper.trapezoidHeight != trapezoidHeight;
}

class _LeftClipper extends CustomClipper<Path> {
  final double trapezoidHeight;
  _LeftClipper({required this.trapezoidHeight});

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    final t = trapezoidHeight;
    final centerH = h - 2 * t;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(0, h)
      ..lineTo(t, h - t)
      ..lineTo(t, t)
      ..close();
  }

  @override
  bool shouldReclip(covariant _LeftClipper oldClipper) =>
      oldClipper.trapezoidHeight != trapezoidHeight;
}

class _RightClipper extends CustomClipper<Path> {
  final double trapezoidHeight;
  _RightClipper({required this.trapezoidHeight});

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    final t = trapezoidHeight;
    final centerH = h - 2 * t;
    return Path()
      ..moveTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w - t, h - t)
      ..lineTo(w - t, t)
      ..close();
  }

  @override
  bool shouldReclip(covariant _RightClipper oldClipper) =>
      oldClipper.trapezoidHeight != trapezoidHeight;
}

class _CenterClipper extends CustomClipper<Path> {
  final double trapezoidHeight;
  _CenterClipper({required this.trapezoidHeight});

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    final t = trapezoidHeight;
    return Path()
      ..addRect(Rect.fromLTWH(t, t, w - 2 * t, h - 2 * t));
  }

  @override
  bool shouldReclip(covariant _CenterClipper oldClipper) =>
      oldClipper.trapezoidHeight != trapezoidHeight;
}

class _JoystickBorderPainter extends CustomPainter {
  final double size;
  final double trapezoidHeight;
  final Color borderColor;
  final double borderWidth;

  _JoystickBorderPainter({
    required this.size,
    required this.trapezoidHeight,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final w = this.size, h = this.size;
    final t = trapezoidHeight;
    final half = w / 2;

    // ---------- 上梯形 ----------
    // 左腰
    canvas.drawLine(Offset(t, t), Offset(0, 0), paint);
    // 右腰
    canvas.drawLine(Offset(w - t, t), Offset(w, 0), paint);
    // 底边（与中心交界）
    canvas.drawLine(Offset(t, t), Offset(w - t, t), paint);

    // ---------- 下梯形 ----------
    // 左腰
    canvas.drawLine(Offset(t, h - t), Offset(0, h), paint);
    // 右腰
    canvas.drawLine(Offset(w - t, h - t), Offset(w, h), paint);
    // 顶边（与中心交界）
    canvas.drawLine(Offset(t, h - t), Offset(w - t, h - t), paint);

    // ---------- 左梯形 ----------
    // 上腰
    canvas.drawLine(Offset(t, t), Offset(0, 0), paint); // 已画过，此处可去重，但笔触叠加无害
    // 下腰
    canvas.drawLine(Offset(t, h - t), Offset(0, h), paint);
    // 右边（与中心交界）
    canvas.drawLine(Offset(t, t), Offset(t, h - t), paint);

    // ---------- 右梯形 ----------
    // 上腰
    canvas.drawLine(Offset(w - t, t), Offset(w, 0), paint);
    // 下腰
    canvas.drawLine(Offset(w - t, h - t), Offset(w, h), paint);
    // 左边（与中心交界）
    canvas.drawLine(Offset(w - t, t), Offset(w - t, h - t), paint);
  }

  @override
  bool shouldRepaint(covariant _JoystickBorderPainter oldDelegate) {
    return oldDelegate.size != size ||
        oldDelegate.trapezoidHeight != trapezoidHeight ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
class _OuterBorderPainter extends CustomPainter {
  final double size;
  final BorderRadiusGeometry borderRadius;
  final Color borderColor;
  final double borderWidth;

  _OuterBorderPainter({
    required this.size,
    required this.borderRadius,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, this.size, this.size);
    final rrect = borderRadius.resolve(TextDirection.ltr).toRRect(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _OuterBorderPainter oldDelegate) {
    return oldDelegate.size != size ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}