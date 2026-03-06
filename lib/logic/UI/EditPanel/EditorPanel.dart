import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/UI/EditPanel/CreatingConceptPanel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/CreatingDomainPanel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/EditingConceptPanel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/EditingDomainPanel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/EditingParentConceptPanel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/EditingParentDomainPanel.dart';
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
  ConceptNodeTree? lastSelectedConcept;
  DomainTree? lastSelectedDomain;


  @override
  Widget build(BuildContext context) {
    GlobalStateModel stateModel = context.watch<GlobalStateModel>();
    SelectionViewData selection = context.watch<SelectionViewData>();

    bool changeSelected = false;
    if(lastSelectedConcept!=selection.SelectedConceptNode || lastSelectedDomain != selection.SelectedDomain){
      changeSelected = true;
    }
    lastSelectedConcept = selection.SelectedConceptNode;
    lastSelectedDomain = selection.SelectedDomain;

    switch(stateModel.State) {
      case GlobalState.creatingConcept:
        return CreatingConceptPanel();
      case GlobalState.creatingDomain:
        return CreatingDomainPanel();
      case GlobalState.editingConcept:
        return EditingConceptPanel(needInit: changeSelected,);
      case GlobalState.editingDomain:
        return EditingDomainPanel(needInit: changeSelected,);

      default :
        if (!selection.IsSelecting) {
          if (selection.IsInDomain) {
            return const EditingParentDomainPanel();
          } else {
            return const EditingParentConceptPanel();
          }
        }
        return Container(
          color: Theme.of(context).colorScheme.surface,
        );
    }
  }
}
