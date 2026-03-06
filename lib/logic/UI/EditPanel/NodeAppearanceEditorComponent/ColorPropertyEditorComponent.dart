import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

class ColorPropertyEditor extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color? color;        // 原始存储的颜色值 (可为 null)
  final Color displayColor;  // 实际显示的颜色 (包含回退色)
  final ValueChanged<Color?> onChanged; // 预览回调 (滑动色轮时触发)
  final Function(Color? oldColor, Color? newColor) onConfirm; // 确认回调 (点击对勾触发，用于 Push Command)
  final VoidCallback onReset;   // 重置回调 (点击刷新触发)
  final VoidCallback onStartEdit;
  final VoidCallback onEndEdit;

  const ColorPropertyEditor({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.displayColor,
    required this.onChanged,
    required this.onConfirm,
    required this.onReset,
    required this.onStartEdit,
    required this.onEndEdit,
  });

  @override
  State<ColorPropertyEditor> createState() => _ColorPropertyEditorState();
}

class _ColorPropertyEditorState extends State<ColorPropertyEditor> {
  int editorState = 0; // 0: 常态, 1: 编辑态
  Color? _originalColor;
  late Color _tempSelectColor;

  @override
  void initState() {
    super.initState();
    _tempSelectColor = widget.displayColor;
  }

  @override
  void didUpdateWidget(covariant ColorPropertyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有在非编辑态时同步外部颜色
    // if (editorState == 0) {
    //
    // }
    _tempSelectColor = widget.displayColor;
  }

  @override
  Widget build(BuildContext context) {
    const double wheelHeight = 170;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(widget.icon, size: 24),
              const SizedBox(width: 12),
              Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              // 复原按钮
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: widget.color == null ? null : widget.onReset,
              ),
              const SizedBox(width: 4),
              if (editorState == 0)
                ColorIndicator(
                  width: 35,
                  height: 35,
                  borderRadius: 4,
                  color: widget.displayColor,
                  onSelect: () {
                    setState(() {
                      _originalColor = widget.color;
                      _tempSelectColor = widget.color ?? Colors.blue;
                      editorState = 1;
                    });
                    widget.onStartEdit();
                  },
                )
              else
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        widget.onChanged(_originalColor); // 恢复原状
                        setState(() => editorState = 0);
                        widget.onEndEdit();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        widget.onConfirm(_originalColor, _tempSelectColor);
                        setState(() => editorState = 0);
                        widget.onEndEdit();
                      },
                    ),
                  ],
                ),
              if (editorState == 0) const SizedBox(width: 50),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Container(
            padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
            height: wheelHeight + 20,
            child: ColorWheelPicker(
              color: _tempSelectColor,
              shouldUpdate: true,
              onChanged: (color) {
                setState(() => _tempSelectColor = color);
                widget.onChanged(color);
              },
              onWheel: (bool value) {},
            ),
          ),
          crossFadeState: editorState == 1 ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeInOutCubic,
        ),
      ],
    );
  }
}
