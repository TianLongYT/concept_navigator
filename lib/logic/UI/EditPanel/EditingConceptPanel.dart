import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/StatefulComponentManagerModel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeConflictCheck.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeMoveComponent/NodeMoveComponent.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeRenameComponent/ConceptRenameComponent.dart';
import 'package:concept_navigator/logic/UI/EditPanel/StatefulComponent/StatefulComponents.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/DoubleActionButton.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/ScroallablePositionedList/ScrollablePositionedListExtension.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/ScroallablePositionedList/ScrollablePositionedListItem.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class EditingConceptPanel extends StatefulWidget {
  const EditingConceptPanel({super.key, this.needInit = false});
  final bool needInit;

  @override
  State<EditingConceptPanel> createState() => _EditingConceptPanelState();
}

class _EditingConceptPanelState extends State<EditingConceptPanel> {
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  final ItemScrollController scrollController = ItemScrollController();
  int centerIndex = 0;

  bool hasFocusState = false;
  void _hasFocusState(bool value) {
    print("hasFocusState${value}");
    setState(() {
      hasFocusState = value;
    });
  }

  @override
  void initState() {
    itemPositionsListener.itemPositions.addListener((){
      print("!!!??????itemPosition?${itemPositionsListener.itemPositions.value}");
      //计算中心序号
      double maxVisualSize = 0;
      int index = 0;
      for(var itemPosition in itemPositionsListener.itemPositions.value){
        double centerEdge = 0.5;
        if(itemPosition.itemLeadingEdge<centerEdge && itemPosition.itemTrailingEdge>centerEdge){
          index = itemPosition.index;
        }

        double leadEdge = itemPosition.itemLeadingEdge < 0? 0:itemPosition.itemLeadingEdge;
        double trailEdge = itemPosition.itemTrailingEdge > 1? 1:itemPosition.itemTrailingEdge;
        double maxEdge = trailEdge - leadEdge;
        if(maxEdge > maxVisualSize){
          maxVisualSize = maxEdge;
          index = itemPosition.index;
        }
      }
      //print("Cal!!!!$index");
      if(centerIndex != index){
        setState(() {
          centerIndex = index;
        });
      }
    });
    //itemPositionsListener.itemPositions.
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    GlobalStateModel stateModel = context.watch<GlobalStateModel>();
    StatefulComponentManagerModelForProvider statefulComponentManagerModelForProvider = context.watch<StatefulComponentManagerModelForProvider>();
    StatefulComponentManagerModel statefulComponentManagerModel = statefulComponentManagerModelForProvider.editingConceptPanel;
    SelectionViewData selection = context.watch<SelectionViewData>();


    hasFocusState = statefulComponentManagerModel.containsState(2);//focus状态


    if(selection.IsSelecting == false){
      return Placeholder();
    }
    //如果进入focus状态，额外添加一个较宽的空组件适应自动滚动。
    List<StatefulComponentModel> components = [
      ...statefulComponentManagerModel.components,
      if(hasFocusState)
        StatefulComponentModel(title: "empty", child:
        Container(
          width: double.infinity,
          height: 1000,
          color: Colors.red,
        )),

    ];

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: ScrollablePositionedList.builder(
        initialScrollIndex: 0,
        initialAlignment: 0.0,//在父widget保存记录focus数据，初始化时载入。
        physics: hasFocusState? NeverScrollableScrollPhysics() : null,
        itemPositionsListener: itemPositionsListener,
        itemScrollController: scrollController,
        itemCount: statefulComponentManagerModel.components.length,
        itemBuilder: (BuildContext context, int index) {
          double state = centerIndex == index? 1:-1;
          //return FlutterLogo(size: 100,);

          return StlessScrollablePositionedListItem(
            index: index,
            controller : scrollController,
            needStopScroll: _hasFocusState,
            child: AnimatedStatefulComponent(
              componentTitle: statefulComponentManagerModel.components[index].title,
              state: state,
              duration: Duration(milliseconds: 200),
              child: statefulComponentManagerModel.components[index].child,
            ),
          );
        },
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height / (hasFocusState? 2 : 10)),
      ),
    );
  }


}
