import 'package:flutter/material.dart';

class PopInspector extends StatefulWidget {
  const PopInspector({
    super.key,
    required this.child,
    required this.isPop,
    required this.landscapePopWidth,
    this.landscapeContractWidth = 10,
    required this.landscapeHeight,
    required this.portraitPopHeight,
    this.portraitContractHeight = 10,
    required this.portraitWidth,
    this.onExpandRequest,
    this.onCollapseRequest,
  });

  final Widget child;
  final bool isPop;

  final double landscapePopWidth;
  final double? landscapeContractWidth;
  final double landscapeHeight;

  final double portraitPopHeight;
  final double? portraitContractHeight;
  final double portraitWidth;

  final VoidCallback? onExpandRequest;
  final VoidCallback? onCollapseRequest;

  @override
  State<PopInspector> createState() => _PopInspectorState();
}

class _PopInspectorState extends State<PopInspector> {
  @override
  Widget build(BuildContext context) {
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    double widgetWidth = widget.portraitWidth;
    double widgetHeight = widget.landscapeHeight;

    double currentOffset = widget.isPop
        ? (isLandscape ? widget.landscapePopWidth : widget.portraitPopHeight)
        : (isLandscape ? widget.landscapeContractWidth! : widget.portraitContractHeight!);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: isLandscape ? widgetWidth - currentOffset : 0,
      top: isLandscape ? 0 : widgetHeight - currentOffset,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: isLandscape ? widget.landscapePopWidth : widgetWidth,
        height: isLandscape ? widgetHeight : widget.portraitPopHeight,
        color: Colors.transparent, // 修改为透明，由内部装饰决定
        child: isLandscape
            ? Row(
                children: [
                  _buildHandle(isLandscape),
                  Expanded(
                    child: _buildChildWrapper(),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildHandle(isLandscape),
                  Expanded(
                    child: _buildChildWrapper(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildChildWrapper() {
    return Listener(
      onPointerDown: (_) {
        if (!widget.isPop) {
          widget.onExpandRequest?.call();
        }
      },
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: widget.child,
      ),
    );
  }

  Widget _buildHandle(bool isLandscape) {
    return GestureDetector(
      onTap: () {
        if (widget.isPop) {
          widget.onCollapseRequest?.call();
        } else {
          widget.onExpandRequest?.call();
        }
      },
      onHorizontalDragUpdate: isLandscape
          ? (details) {
              if (details.primaryDelta! < -5 && !widget.isPop) {
                widget.onExpandRequest?.call();
              } else if (details.primaryDelta! > 5 && widget.isPop) {
                widget.onCollapseRequest?.call();
              }
            }
          : null,
      onVerticalDragUpdate: !isLandscape
          ? (details) {
              if (details.primaryDelta! < -5 && !widget.isPop) {
                widget.onExpandRequest?.call();
              } else if (details.primaryDelta! > 5 && widget.isPop) {
                widget.onCollapseRequest?.call();
              }
            }
          : null,
      child: Container(
        width: isLandscape ? 12 : widget.portraitWidth,
        height: isLandscape ? widget.landscapeHeight : 12,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: isLandscape
              ? const BorderRadius.horizontal(left: Radius.circular(4))
              : const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            width: isLandscape ? 3 : widget.portraitWidth * 0.15,
            height: isLandscape ? widget.landscapeHeight * 0.15 : 3,
          ),
        ),
      ),
    );
  }
}
