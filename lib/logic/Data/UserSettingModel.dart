
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';

enum Shape{
  rect,
  rRect,
  triangle,
  circle,

}

class ShapeAppearance{
  Shape shape = Shape.rect;
  Color color = Colors.white;
}
class FontAppearance{
  Color color = Colors.black;
}

class NodeAppearance{
  //节点绘制数据

  // 显式添加默认构造函数，因为 factory fromJson 存在
  NodeAppearance();

  //节点形状
  Shape shape = Shape.rRect;
  //节点颜色
  Color? nodeColor;
  //核心节点大小
  Size nodeSize = Size(100*1.3,100);
  //留白。。。。
  double emptySize = 1.4;

  //字体形状
  //字体颜色
  Color? fontColor;
  //字体自适应大小
  double minFontSize = 20;
  double maxFontSize = 100;

  //层级参数
  int minShowingLevel = 2;
  int maxShowingLevel = 4;

  double minChildNodeSize = 80;//看什么时候能看清吧。。。。
    //显示样式。组织模式。
  SortingMode sortingMode = SortingMode.none;

  NodeAppearance Clone(){
    return NodeAppearance()
      ..shape = shape
      ..nodeColor = nodeColor
      ..nodeSize = nodeSize
      ..emptySize = emptySize
      ..fontColor = fontColor
      ..minFontSize = minFontSize
      ..maxFontSize = maxFontSize
      ..minShowingLevel = minShowingLevel
      ..maxShowingLevel = maxShowingLevel
      ..minChildNodeSize = minChildNodeSize
      ..sortingMode = sortingMode;

  }

  Map<String, dynamic> toJson() {
    return {
      'shape': shape.index,
      'nodeColor': nodeColor?.value,
      'nodeWidth': nodeSize.width,
      'nodeHeight': nodeSize.height,
      'emptySize': emptySize,
      'fontColor': fontColor?.value,
      'minFontSize': minFontSize,
      'maxFontSize': maxFontSize,
      'minShowingLevel': minShowingLevel,
      'maxShowingLevel': maxShowingLevel,
      'minChildNodeSize': minChildNodeSize,
      'sortingMode': sortingMode.index,
    };
  }

  factory NodeAppearance.fromJson(Map<String, dynamic> json) {
    return NodeAppearance()
      ..shape = Shape.values[json['shape'] ?? Shape.rRect.index]
      ..nodeColor = json['nodeColor'] != null ? Color(json['nodeColor']) : null
      ..nodeSize = Size((json['nodeWidth'] ?? 130).toDouble(), (json['nodeHeight'] ?? 100).toDouble())
      ..emptySize = (json['emptySize'] ?? 1.4).toDouble()
      ..fontColor = json['fontColor'] != null ? Color(json['fontColor']) : null
      ..minFontSize = (json['minFontSize'] ?? 20).toDouble()
      ..maxFontSize = (json['maxFontSize'] ?? 100).toDouble()
      ..minShowingLevel = json['minShowingLevel'] ?? 2
      ..maxShowingLevel = json['maxShowingLevel'] ?? 4
      ..minChildNodeSize = (json['minChildNodeSize'] ?? 80).toDouble()
      ..sortingMode = SortingMode.values[json['sortingMode'] ?? SortingMode.none.index];
  }

}
class DecoratorAppearance{
  DecoratorAppearance();
  //修饰词绘制数据

  //修饰词形状。
  Shape shape = Shape.circle;
  //节点颜色
  Color? nodeColor;
  //核心节点大小
  Size nodeSize = Size(50 * 1.0,50);
  //留白。。。。
  double emptySize = 1.4;

  //字体形状
  //字体颜色
  Color? fontColor;
  //字体自适应大小
  double minFontSize = 10;
  double maxFontSize = 30;

  DecoratorAppearance Clone(){
    return DecoratorAppearance()
      ..shape = shape
      ..nodeColor = nodeColor
      ..nodeSize = nodeSize
      ..emptySize = emptySize
      ..fontColor = fontColor
      ..minFontSize = minFontSize
      ..maxFontSize = maxFontSize;
  }

  Map<String, dynamic> toJson() {
    return {
      'shape': shape.index,
      'nodeColor': nodeColor?.value,
      'nodeWidth': nodeSize.width,
      'nodeHeight': nodeSize.height,
      'emptySize': emptySize,
      'fontColor': fontColor?.value,
      'minFontSize': minFontSize,
      'maxFontSize': maxFontSize,
    };
  }

  factory DecoratorAppearance.fromJson(Map<String, dynamic> json) {
    return DecoratorAppearance()
      ..shape = Shape.values[json['shape'] ?? Shape.circle.index]
      ..nodeColor = json['nodeColor'] != null ? Color(json['nodeColor'] as int) : null
      ..nodeSize = Size((json['nodeWidth'] ?? 50).toDouble(), (json['nodeHeight'] ?? 50).toDouble())
      ..emptySize = (json['emptySize'] ?? 1.4).toDouble()
      ..fontColor = json['fontColor'] != null ? Color(json['fontColor'] as int) : null
      ..minFontSize = (json['minFontSize'] ?? 10).toDouble()
      ..maxFontSize = (json['maxFontSize'] ?? 30).toDouble();
  }

}
class UserSettingAppearanceModel extends ChangeNotifier{

  //主题

  //字体

  //节点
  NodeAppearance GetNodeApperance(){
    return NodeAppearance();
  }
}


//
// lib/logic/Theme/NodeColorsExtension.dart


class NodeColorsExtension extends ThemeExtension<NodeColorsExtension> {
  final Color defaultConceptNodeColor;
  late Color defaultConceptFontColor;
  final Color defaultDomainNodeColor;
  late Color defaultDomainFontColor;

  // 新增修饰词颜色
  final Color defaultDecoratorNodeColor;
  late Color defaultDecoratorFontColor;

  // 状态颜色
  final Color templateColor;
  final Color referenceColor;
  final Color instanceColor;


  NodeColorsExtension(
  {   Color? defaultConceptFontColor,
     Color? defaultDomainFontColor,
     Color? defaultDecoratorFontColor,
  required this.defaultConceptNodeColor,
    required this.defaultDomainNodeColor,
    required this.defaultDecoratorNodeColor,
    this.templateColor = Colors.purple,
    this.referenceColor = Colors.blue,
    this.instanceColor = Colors.orange,
  }):defaultConceptFontColor =defaultConceptFontColor ??(defaultConceptNodeColor.computeLuminance() > 0.5 ? Colors.black : Colors.white),
      defaultDomainFontColor = defaultDomainFontColor ?? (defaultDomainNodeColor.computeLuminance() > 0.5 ? Colors.black : Colors.white),
      defaultDecoratorFontColor = defaultDecoratorFontColor ?? (defaultDecoratorNodeColor.computeLuminance() > 0.5 ? Colors.black : Colors.white)
  ;


  @override
  ThemeExtension<NodeColorsExtension> copyWith(
      {Color? conceptNode,
        Color? domainNode,
        Color? conceptFont,
        Color? domainFont,
        Color? decoratorNode,
        Color? decoratorFont,
        Color? template,
        Color? reference,
        Color? instance}) {
    return NodeColorsExtension(
      defaultConceptFontColor: conceptFont ?? defaultConceptFontColor,
      defaultDomainFontColor: domainFont ?? defaultDomainFontColor,
      defaultConceptNodeColor: conceptNode ?? defaultConceptNodeColor,
      defaultDomainNodeColor: domainNode ?? defaultDomainNodeColor,
      defaultDecoratorNodeColor: decoratorNode ?? defaultDecoratorNodeColor,
      defaultDecoratorFontColor: decoratorFont ?? defaultDecoratorFontColor,
      templateColor: template ?? templateColor,
      referenceColor: reference ?? referenceColor,
      instanceColor: instance ?? instanceColor,
    );
  }

  @override
  ThemeExtension<NodeColorsExtension> lerp(
      ThemeExtension<NodeColorsExtension>? other, double t) {
    if (other is! NodeColorsExtension) return this;
    return NodeColorsExtension(
      defaultConceptFontColor: Color.lerp(
          defaultConceptFontColor, other.defaultConceptFontColor, t)!,
      defaultDomainFontColor: Color.lerp(
          defaultDomainFontColor, other.defaultDomainFontColor, t)!,
      defaultConceptNodeColor: Color.lerp(
          defaultConceptNodeColor, other.defaultConceptNodeColor, t)!,
      defaultDomainNodeColor: Color.lerp(
          defaultDomainNodeColor, other.defaultDomainNodeColor, t)!,
      defaultDecoratorNodeColor: Color.lerp(
          defaultDecoratorNodeColor, other.defaultDecoratorNodeColor, t)!,
      defaultDecoratorFontColor: Color.lerp(
          defaultDecoratorFontColor, other.defaultDecoratorFontColor, t)!,
      templateColor: Color.lerp(templateColor, other.templateColor, t)!,
      referenceColor: Color.lerp(referenceColor, other.referenceColor, t)!,
      instanceColor: Color.lerp(instanceColor, other.instanceColor, t)!,
    );
  }
}
