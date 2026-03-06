import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/StatefulComponentManagerModel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/StatefulComponent/StatefulComponents.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/ScroallablePositionedList/ScrollablePositionedListItem.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';


class EditingParentConceptPanel extends StatefulWidget {
  const EditingParentConceptPanel({super.key});

  @override
  State<EditingParentConceptPanel> createState() => _EditingParentConceptPanelState();
}

class _EditingParentConceptPanelState extends State<EditingParentConceptPanel> {

  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  final ItemScrollController scrollController = ItemScrollController();
  int centerIndex = 0;

  bool hasFocusState = false;
  void _hasFocusState(bool value) {
    setState(() {
      hasFocusState = value;
    });
  }

  @override
  void initState() {
    itemPositionsListener.itemPositions.addListener((){
      double maxVisualSize = 0;
      int index = 0;
      for(var itemPosition in itemPositionsListener.itemPositions.value){
        double leadEdge = itemPosition.itemLeadingEdge < 0? 0:itemPosition.itemLeadingEdge;
        double trailEdge = itemPosition.itemTrailingEdge > 1? 1:itemPosition.itemTrailingEdge;
        double maxEdge = trailEdge - leadEdge;
        if(maxEdge > maxVisualSize){
          maxVisualSize = maxEdge;
          index = itemPosition.index;
        }
      }
      if(centerIndex != index){
        setState(() {
          centerIndex = index;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    StatefulComponentManagerModelForProvider statefulComponentManagerModelForProvider = context.watch<StatefulComponentManagerModelForProvider>();
    StatefulComponentManagerModel statefulComponentManagerModel = statefulComponentManagerModelForProvider.editingParentConceptPanel;
    SelectionViewData selection = context.watch<SelectionViewData>();

    hasFocusState = statefulComponentManagerModel.containsState(2);//focus状态

    if(selection.IsSelecting){
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: ScrollablePositionedList.builder(
        initialScrollIndex: 0,
        initialAlignment: 0.0,
        physics: hasFocusState? const NeverScrollableScrollPhysics() : null,
        itemPositionsListener: itemPositionsListener,
        itemScrollController: scrollController,
        itemCount: statefulComponentManagerModel.components.length,
        itemBuilder: (BuildContext context, int index) {
          double state = centerIndex == index? 1:-1;

          return StlessScrollablePositionedListItem(
            index: index,
            controller : scrollController,
            needStopScroll: _hasFocusState,
            child: AnimatedStatefulComponent(
              componentTitle: statefulComponentManagerModel.components[index].title,
              state: state,
              duration: const Duration(milliseconds: 200),
              child: statefulComponentManagerModel.components[index].child,
            ),
          );
        },
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height / (hasFocusState? 2 : 10)),
      ),
    );
  }
}
