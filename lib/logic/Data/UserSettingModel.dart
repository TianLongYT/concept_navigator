
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';

//外观设置

enum Theme{
  light,
  black,
}
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

  //节点形状
  Shape shape = Shape.rRect;
  //节点颜色
  Color nodeColor = Colors.white;
  //核心节点大小
  Size nodeSize = Size(100*1.3,100);
  //留白。。。。
  double emptySize = 1.4;

  //字体形状
  //字体颜色
  Color fontColor = Colors.black;
  //字体自适应大小
  double minFontSize = 20;
  double maxFontSize = 100;

  //层级参数
  int minShowingLevel = 2;
  int maxShowingLevel = 4;

  double minChildNodeSize = 80;//看什么时候能看清吧。。。。
    //显示样式。组织模式。
  SortingMode sortingMode = SortingMode.none;

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