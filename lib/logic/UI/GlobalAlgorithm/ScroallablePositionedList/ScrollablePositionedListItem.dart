//传入Controller，自动驱动StatefulComponent
import 'package:concept_navigator/logic/UI/EditPanel/StatefulComponent/StatefulComponents.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
//太耗了，没啥用。就存存数据得了。
class ScrollablePositionedListItem extends StatefulWidget {
  const ScrollablePositionedListItem({
    super.key,
    this.duration = const Duration(milliseconds: 200),
    required this.index,
    required this.controller,
    required this.listener,
    required this.child,

  });
  final Widget child;
  final Duration duration;
  final int index;
  final ItemScrollController controller;
  final ItemPositionsListener listener;

  @override
  State<ScrollablePositionedListItem> createState() => _ScrollablePositionedListItemState();
}

class _ScrollablePositionedListItemState extends State<ScrollablePositionedListItem> {
  @override
  void initState() {
    var itemPositions = widget.listener.itemPositions;
    itemPositions.addListener((){
      //
      // for(var itemPosition in itemPositions.value){
      //   itemPosition.
      // }
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedStatefulComponent(
      state: 0,
      duration: widget.duration,

      child: widget.child,
    );
  }
}

class StlessScrollablePositionedListItem extends InheritedWidget {

  const StlessScrollablePositionedListItem({
    super.key,
    required this.index,
    required this.controller,
    this.needStopScroll,
    required super.child
  });

  //final Widget child;
  //final Duration duration;
  final int index;
  final ItemScrollController controller;
  final ValueChanged<bool>? needStopScroll;

  //final ItemPositionsListener listener;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}

