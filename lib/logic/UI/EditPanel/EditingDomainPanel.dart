import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditingDomainPanel extends StatefulWidget {
  const EditingDomainPanel({super.key});

  @override
  State<EditingDomainPanel> createState() => _EditingDomainPanelState();
}

class _EditingDomainPanelState extends State<EditingDomainPanel> {
  final TextEditingController controller = TextEditingController.fromValue(
    TextEditingValue(
    ),
  );
  @override
  Widget build(BuildContext context) {
    SelectionViewData selection = context.watch<SelectionViewData>();
    ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    // ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    // ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    // ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();

    if(selection.IsSelecting == false)
      return Placeholder();

    //初始化controller
    controller.text = selection.SelectedDomain!.name;

    return Container(
      color: Colors.blue[200],
      child: ListView(
        children: [
          Center(child: Text("域信息")),

          TextField(
            controller: controller,
            onEditingComplete: ()=>{

            },
          )
        ],
      ),
    );
  }
}
