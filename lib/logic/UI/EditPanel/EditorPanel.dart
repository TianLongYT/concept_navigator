
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/CreatingConceptPanel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/CreatingDomainPanel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/EditingConceptPanel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/EditingDomainPanel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


//执行创建检查。
//命名修改窗口。错误检查。
class EditorPanel extends StatefulWidget {
  EditorPanel({super.key});

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {


  @override
  Widget build(BuildContext context) {
    GlobalStateModel stateModel = context.watch<GlobalStateModel>();
    SelectionViewData selection = context.watch<SelectionViewData>();
    ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();


    switch(stateModel.State) {
      case GlobalState.creatingNode:
        return CreatingConceptPanel();
      case GlobalState.creatingDomain:
        return CreatingDomainPanel();
      case GlobalState.selectedNode:

        return EditingConceptPanel();
      case GlobalState.selectedDomain:
        return EditingDomainPanel();


      default :
        return Placeholder();
    }

  }


}
