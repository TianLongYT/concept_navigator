//加一个无参数的构造函数，其他保持一样
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
class ScrollablePositionedListExtension extends ScrollablePositionedList {
  ScrollablePositionedListExtension({
    super.key,
    List<Widget> children = const <Widget>[],
    super.itemPositionsListener,
    super.itemScrollController,

  }):super.builder(itemCount: children.length,
    itemBuilder: (BuildContext context,int index) => children[index],
  );

}