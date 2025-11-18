
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


//执行创建检查。
//命名修改窗口。错误检查。
class EditorPanel extends StatelessWidget {
  EditorPanel({super.key});
  //final String preText = ;
  final TextEditingController controller = TextEditingController.fromValue(TextEditingValue(

    text: "preTextaaaaaaaaaaaaaaaaaaabaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabaaaaaaaaaaaa",
    selection: TextSelection.fromPosition(TextPosition(
      affinity: TextAffinity.downstream,
      offset: "preText".length,
    ))
  ));
  final TextEditingController aliasController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    GlobalStateModel stateModel = context.watch<GlobalStateModel>();
    SelectionViewData selection = context.watch<SelectionViewData>();
    ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    ConceptTree2NodeDrawingDataDic drawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();

    if(stateModel.State == GlobalState.creatingNode){
      return Container(
        color: Colors.blue,
        child: Column(
          children: [
            TextField(
              controller: controller,

            ),
            OutlinedButton(onPressed: (){
                stateModel.State = GlobalState.selectedNode;
                ConceptNodeTree? nodeTree = treeModel.GetConceptNodeByDic(selection.CurrentDomainNodeKey);
                if(nodeTree == null) return;
                nodeTree.children.add(ConceptNodeTree()..name = controller.text);
                treeModel.GenerateDic(selection.currentDomain);
                //查找并添加绘制物
                drawingDataDic.GetNodeDrawingData(ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, controller.text, ""))?.AddNodeDrawingData();
                drawingDataDic.putIfAbsent( ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, controller.text, ""), ()=>
                NodeDrawingData(nodeAppearance: NodeAppearance()));
                viewDataDic.putIfAbsent( ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, controller.text, ""), ()=>NodeViewData());

            }, child: Text("AddNewConcept")),
          ],
        ),
      );
    }
    else /*if(stateModel.State == GlobalState.selectedNode)*/ {
      return Container(
        color: Colors.blue[100],
        child: Column(
          children: [
            TextField(
              controller: controller,
              onEditingComplete: ()=>{

              },
            )
            ,
            TextField(
              controller: aliasController,

            )
          ],
        ),
      );
    }
    return Container();
  }
}
