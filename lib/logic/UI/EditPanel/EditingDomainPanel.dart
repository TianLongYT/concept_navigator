import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/StatefulComponentManagerModel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeConflictCheck.dart';
import 'package:concept_navigator/logic/UI/EditPanel/StatefulComponent/StatefulComponents.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/ScroallablePositionedList/ScrollablePositionedListItem.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class EditingDomainPanel extends StatefulWidget {
  const EditingDomainPanel({super.key, this.needInit = false});
  final bool needInit;

  @override
  State<EditingDomainPanel> createState() => _EditingDomainPanelState();
}

class _EditingDomainPanelState extends State<EditingDomainPanel> {
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
  Widget build(BuildContext context) {
    StatefulComponentManagerModelForProvider statefulComponentManagerModelForProvider = context.watch<StatefulComponentManagerModelForProvider>();
    StatefulComponentManagerModel statefulComponentManagerModel = statefulComponentManagerModelForProvider.editingDomainPanel;
    SelectionViewData selection = context.watch<SelectionViewData>();

    hasFocusState = statefulComponentManagerModel.containsState(2);//focus状态

    if(selection.IsSelecting == false){
      return Placeholder();
    }

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
  // Widget build(BuildContext context) {
  //   SelectionViewData selection = context.watch<SelectionViewData>();
  //   ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
  //   // ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
  //   // ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
  //   // ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();
  //
  //   if(selection.IsSelecting == false)
  //     return Placeholder();
  //
  //   //初始化controller
  //   controller.text = selection.SelectedDomain!.name;
  //
  //   return Container(
  //     color: Colors.blue[200],
  //     child: ListView(
  //       children: [
  //         Center(child: Text("域信息")),
  //
  //         TextField(
  //           controller: controller,
  //           onEditingComplete: ()=>{
  //
  //           },
  //         )
  //       ],
  //     ),
  //   );
  // }

}
