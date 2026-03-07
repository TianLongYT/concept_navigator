//仅负责呈现视觉效果。不负责处理点击关系。
import 'package:concept_navigator/MTools/UI/DebugUI.dart';
import 'package:concept_navigator/MTools/UI/TextHeight/GetTextHeight.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodeInfo/GetNodeColor.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/LevelNodePanel.dart';
import 'package:concept_navigator/logic/UI/NodePresentation.dart';
import 'package:flutter/material.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/NodePainter.dart';

class LevelNodePresentation extends StatefulWidget {
  LevelNodePresentation({
    super.key,
    double scale = 1.0,
    required this.isDomain,
    required this.parentDomainDrawingData,
    required this.parentConceptDrawingData,
    required this.drawingData,
    required this.nodeTree,
    required this.domainTree,
  }) : painter = NodePainter(drawingData: drawingData),
       _scale = scale;

  final bool isDomain;
  final NodeDrawingData? parentConceptDrawingData; //仅仅传入父节点绘制物的推荐颜色。
  final DomainDrawingData? parentDomainDrawingData;
  final NodeDrawingData drawingData;
  final ConceptNodeTree? nodeTree;
  final DomainTree? domainTree;
  final NodePainter? painter;
  final double _scale;

  @override
  State<LevelNodePresentation> createState() => _LevelNodePresentationState();
}

class _LevelNodePresentationState extends State<LevelNodePresentation> {
  bool showingLevel = false;
  double width = 100;
  double height = 100;

  @override
  void initState() {
    super.initState();
    showingLevel = false;
  }

  @override
  Widget build(BuildContext context) {
    NodeColorHelper colorHelper = NodeColorHelper.byDrawingData(
      parentDomainDrawingData: widget.parentDomainDrawingData,
      parentConceptDrawingData: widget.parentConceptDrawingData,
      nodeAppearance: widget.drawingData.nodeAppearance,
      isSelectedDomain: widget.isDomain,
    );

    Color nodeColor = colorHelper.getNodeColor(context);
    Color fontColor = colorHelper.getFontColor(context);

    width = widget.drawingData.nodeAppearance.nodeSize.width * widget._scale;
    height = widget.drawingData.nodeAppearance.nodeSize.height * widget._scale;

    if (height > widget.drawingData.nodeAppearance.minChildNodeSize) {
      showingLevel = true;
    } else {
      showingLevel = false;
    }

    TextStyle textStyle = TextStyle(
      color: fontColor,
      inherit: false,
      fontSize: 14, //动态计算
    );
    const double BORDER = 2.0;
    const double EDGEINSETS = 6.0;
    double singleLineTextHeight = TextSizeHelper.GetTextHeight(maxLines: 1, text: widget.drawingData.text, style: textStyle);
    double fullLineTextHeight = TextSizeHelper.GetTextHeight(maxWidth: width, text: widget.drawingData.text, style: textStyle);
    double nextWidgetTop = singleLineTextHeight + 2 * EDGEINSETS;
    double centerFontTop = height * 0.5 - fullLineTextHeight * 0.5 - EDGEINSETS;
    centerFontTop = centerFontTop > 0 ? centerFontTop : 0;

    String domainKey = widget.isDomain ? widget.domainTree!.GetDomainKey() : "";

    // 修饰词渲染组件
    Widget? decorationWidget;
    if (!widget.isDomain && widget.drawingData.decoration.isNotEmpty) {
      final decoratorAppearance = widget.drawingData.decoratorAppearance;
      final double decWidth = decoratorAppearance.nodeSize.width * widget._scale;
      final double decHeight = decoratorAppearance.nodeSize.height * widget._scale;
      final Color decBgColor = NodeColorHelper.getDecoratorColor(decoratorAppearance.nodeColor, context);
      final Color decFontColor = NodeColorHelper.getDecoratorFontColor(decoratorAppearance.fontColor,context);
      final String decText = widget.drawingData.decoration.join(", ");

      decorationWidget = Positioned(
        left: width - (decWidth * 0.4), // 紧贴主节点右侧，稍微重叠
        top: - (decHeight * 0.2), // 稍微往上偏移，呈现悬挂感
        child: Container(
          width: decWidth,
          height: decHeight,
          decoration: BoxDecoration(
            color: decBgColor,
            shape: decoratorAppearance.shape == Shape.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: decoratorAppearance.shape == Shape.circle ? null : BorderRadius.circular(decHeight * 0.2),
            border: Border.all(
              width: BORDER * 0.5 * widget._scale,
              color: Theme.of(context).colorScheme.outline,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4 * widget._scale,
                offset: Offset(0, 2 * widget._scale),
              )
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Text(
                decText,
                style: TextStyle(
                  color: decFontColor,
                  fontSize: (decoratorAppearance.minFontSize * widget._scale).clamp(6.0, 30.0),
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none, // 允许修饰词超出父容器边界显示
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: nodeColor,
            borderRadius: BorderRadius.circular(height * 0.1),
            border: Border.all(
              width: BORDER,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: showingLevel ? 0 : centerFontTop,
                  child: SizedBox(
                    height: fullLineTextHeight + 2 * EDGEINSETS,
                    width: width,
                    child: Padding(
                      padding: const EdgeInsets.all(EDGEINSETS),
                      child: Text(
                        widget.drawingData.text,
                        softWrap: true,
                        maxLines: showingLevel ? 1 : null,
                        overflow: TextOverflow.clip,
                        textAlign: TextAlign.center,
                        style: textStyle,
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  top: showingLevel ? nextWidgetTop : height,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedOpacity(
                    opacity: showingLevel ? 1 : 0,
                    duration: const Duration(milliseconds: 1000),
                    child: Container(
                      width: width,
                      height: showingLevel ? height - nextWidgetTop : 0,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        border: Border.all(
                          width: 1.0,
                          strokeAlign: BorderSide.strokeAlignOutside,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: showingLevel
                          ? Padding(
                              padding: EdgeInsets.all(0.05 * (height - nextWidgetTop)),
                              child: LevelNodePanel(
                                isInDomain: widget.isDomain,
                                currentDomainKey: widget.isDomain ? domainKey : widget.nodeTree!.domainKey,
                                currentDomainNodeKey: widget.isDomain
                                    ? domainKey
                                    : ConceptTreeModel.GenerateDomainNodeKey(
                                        widget.nodeTree!.domainKey, widget.nodeTree!.name, widget.nodeTree!.alias),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (decorationWidget != null) decorationWidget,
      ],
    );
  }
}
