import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AnalysisPanel extends StatefulWidget {
  final NodeTree? rootNode;
  final int maxLevel;

  const AnalysisPanel({
    super.key,
    this.rootNode,
    this.maxLevel = 99,
  });

  @override
  State<AnalysisPanel> createState() => _AnalysisPanelState();
}

class _AnalysisPanelState extends State<AnalysisPanel> {
  // 配置参数
  double levelGap = 80.0;    // 层级间距
  double siblingGap = 20.0;  // 同级节点间距
  final Size nodeSize = const Size(130, 80); // 增加高度以容纳多行文字

  final TransformationController _transformationController = TransformationController();
  bool _isInitialized = false;
  NodeTree? _lastRoot;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final treeModel = context.watch<ConceptTreeModel>();
    final nodeColors = Theme.of(context).extension<NodeColorsExtension>();
    
    NodeTree? root = widget.rootNode ?? treeModel.rootTree;
    if (root == null) return const Center(child: Text("未找到根节点数据"));

    // 检测根节点变化，以便重新居中
    if (_lastRoot != root) {
      _lastRoot = root;
      _isInitialized = false;
    }

    return LayoutBuilder(builder: (context, constraints) {
      bool isPortrait = constraints.maxHeight > constraints.maxWidth;
      
      // 1. 构建布局树并计算空间
      _LayoutResult layoutRoot = _computeLayout(root, 0, isPortrait);

      // 定义一个足够大的画布，并将绘图起始点放在画布中心，给予四周充分的平移空间
      const double canvasSize = 10000.0;
      const Offset drawingOrigin = Offset(canvasSize / 2, canvasSize / 2);

      // 计算根节点的几何中心位置
      double rootCenterX, rootCenterY;
      if (isPortrait) {
        rootCenterX = drawingOrigin.dx + layoutRoot.totalBreadth / 2;
        rootCenterY = drawingOrigin.dy + nodeSize.height / 2;
      } else {
        rootCenterX = drawingOrigin.dx + nodeSize.width / 2;
        rootCenterY = drawingOrigin.dy + layoutRoot.totalBreadth / 2;
      }

      // 初始居中逻辑：将画布平移，使根节点中心对齐视口中心
      if (!_isInitialized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final double tx = constraints.maxWidth / 2 - rootCenterX;
            final double ty = constraints.maxHeight / 2 - rootCenterY;
            _transformationController.value = Matrix4.identity()..translate(tx, ty);
            setState(() {
              _isInitialized = true;
            });
          }
        });
      }

      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: InteractiveViewer(
          transformationController: _transformationController,
          constrained: false, 
          boundaryMargin: const EdgeInsets.all(canvasSize / 2), 
          minScale: 0.05,
          maxScale: 5.0,
          child: SizedBox(
            width: canvasSize,
            height: canvasSize,
            child: Stack(
              children: [
                // 绘制连接线
                CustomPaint(
                  painter: _TreeLinkPainter(
                    root: layoutRoot,
                    isPortrait: isPortrait,
                    nodeSize: nodeSize,
                    levelGap: levelGap,
                    siblingGap: siblingGap,
                    drawingOrigin: drawingOrigin,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                // 绘制节点
                ..._buildNodes(context, layoutRoot, treeModel, isPortrait, nodeColors, drawingOrigin),
              ],
            ),
          ),
        ),
      );
    });
  }

  // 递归计算布局位置
  _LayoutResult _computeLayout(NodeTree node, int currentLevel, bool isPortrait) {
    List<_LayoutResult> childrenResults = [];
    
    if (currentLevel < widget.maxLevel) {
      if (node is DomainTree) {
        for (var d in node.children) childrenResults.add(_computeLayout(d, currentLevel + 1, isPortrait));
        for (var c in node.conceptNodeTree) childrenResults.add(_computeLayout(c, currentLevel + 1, isPortrait));
      } else if (node is ConceptNodeTree) {
        for (var c in node.children) childrenResults.add(_computeLayout(c, currentLevel + 1, isPortrait));
      }
    }

    double totalBreadth = 0;
    if (childrenResults.isEmpty) {
      totalBreadth = isPortrait ? nodeSize.width : nodeSize.height;
    } else {
      for (var child in childrenResults) {
        totalBreadth += child.totalBreadth;
      }
      totalBreadth += (childrenResults.length - 1) * siblingGap;
    }

    return _LayoutResult(
      node: node,
      level: currentLevel,
      totalBreadth: totalBreadth,
      children: childrenResults,
    );
  }

  List<Widget> _buildNodes(BuildContext context, _LayoutResult result, ConceptTreeModel treeModel, bool isPortrait, NodeColorsExtension? colors, Offset offset) {
    List<Widget> widgets = [];
    
    double x, y;
    if (isPortrait) {
      x = offset.dx + result.totalBreadth / 2 - nodeSize.width / 2;
      y = offset.dy + result.level * (nodeSize.height + levelGap);
    } else {
      x = offset.dx + result.level * (nodeSize.width + levelGap);
      y = offset.dy + result.totalBreadth / 2 - nodeSize.height / 2;
    }

    Color bgColor;
    Color textColor;
    String displayText = result.node.name;

    if (result.node is ConceptNodeTree) {
      final conceptNode = result.node as ConceptNodeTree;
      final status = conceptNode.getStatus(treeModel);
      switch (status) {
        case ConceptStatus.template:
          displayText = "${conceptNode.name}\n(概念模板)";
          bgColor = colors?.templateColor ?? Colors.purple;
          break;
        case ConceptStatus.templateReference:
          displayText = "${conceptNode.name}\n(概念引用)";
          bgColor = colors?.referenceColor ?? Colors.blue;
          break;
        case ConceptStatus.instance:
          displayText = "${conceptNode.name}\n别名:${conceptNode.alias}\n(概念实例)";
          bgColor = colors?.instanceColor ?? Colors.orange;
          break;
        case ConceptStatus.normal:
        default:
          bgColor = colors?.defaultConceptNodeColor ?? Colors.green;
          break;
      }
      // 根据背景亮度自动选择文字颜色
      textColor = bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    } else {
      bgColor = colors?.defaultDomainNodeColor ?? Colors.blue;
      textColor = colors?.defaultDomainFontColor ?? Colors.white;
    }

    widgets.add(Positioned(
      left: x,
      top: y,
      child: Container(
        width: nodeSize.width,
        height: nodeSize.height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          displayText,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
      ),
    ));

    double currentBreadthOffset = 0;
    for (var child in result.children) {
      Offset childOffset = isPortrait 
          ? Offset(offset.dx + currentBreadthOffset, offset.dy)
          : Offset(offset.dx, offset.dy + currentBreadthOffset);
      widgets.addAll(_buildNodes(context, child, treeModel, isPortrait, colors, childOffset));
      currentBreadthOffset += child.totalBreadth + siblingGap;
    }

    return widgets;
  }
}

class _LayoutResult {
  final NodeTree node;
  final int level;
  final double totalBreadth;
  final List<_LayoutResult> children;
  _LayoutResult({required this.node, required this.level, required this.totalBreadth, required this.children});
}

class _TreeLinkPainter extends CustomPainter {
  final _LayoutResult root;
  final bool isPortrait;
  final Size nodeSize;
  final double levelGap;
  final double siblingGap;
  final Offset drawingOrigin;
  final Color color;

  _TreeLinkPainter({
    required this.root, 
    required this.isPortrait, 
    required this.nodeSize, 
    required this.levelGap, 
    required this.siblingGap,
    required this.drawingOrigin,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    _drawLinks(canvas, paint, root, drawingOrigin);
  }

  void _drawLinks(Canvas canvas, Paint paint, _LayoutResult result, Offset offset) {
    if (result.children.isEmpty) return;

    double px, py; 
    if (isPortrait) {
      px = offset.dx + result.totalBreadth / 2;
      py = offset.dy + result.level * (nodeSize.height + levelGap) + nodeSize.height;
      
      double midY = py + levelGap / 2;
      canvas.drawLine(Offset(px, py), Offset(px, midY), paint);

      double firstChildX = offset.dx + result.children.first.totalBreadth / 2;
      double lastChildX = offset.dx + result.totalBreadth - result.children.last.totalBreadth / 2;
      canvas.drawLine(Offset(firstChildX, midY), Offset(lastChildX, midY), paint);

      double currentX = offset.dx;
      for (var child in result.children) {
        double cx = currentX + child.totalBreadth / 2;
        double cy = offset.dy + (result.level + 1) * (nodeSize.height + levelGap);
        canvas.drawLine(Offset(cx, midY), Offset(cx, cy), paint);
        _drawLinks(canvas, paint, child, Offset(currentX, offset.dy));
        currentX += child.totalBreadth + siblingGap;
      }
    } else {
      px = offset.dx + result.level * (nodeSize.width + levelGap) + nodeSize.width;
      py = offset.dy + result.totalBreadth / 2;
      
      double midX = px + levelGap / 2;
      canvas.drawLine(Offset(px, py), Offset(midX, py), paint);

      double firstChildY = offset.dy + result.children.first.totalBreadth / 2;
      double lastChildY = offset.dy + result.totalBreadth - result.children.last.totalBreadth / 2;
      canvas.drawLine(Offset(midX, firstChildY), Offset(midX, lastChildY), paint);

      double currentY = offset.dy;
      for (var child in result.children) {
        double cy = currentY + child.totalBreadth / 2;
        double cx = offset.dx + (result.level + 1) * (nodeSize.width + levelGap);
        canvas.drawLine(Offset(midX, cy), Offset(cx, cy), paint);
        _drawLinks(canvas, paint, child, Offset(offset.dx, currentY));
        currentY += child.totalBreadth + siblingGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
