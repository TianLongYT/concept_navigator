import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/UI/EditorPanel.dart';
import 'package:concept_navigator/logic/UI/LevelNode.dart';
import 'package:concept_navigator/logic/UI/PopInspector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Nodepanel extends StatelessWidget {
  const Nodepanel({super.key});
  //制作levelNode的排版功能。显示所有的levelNode。


  @override
  Widget build(BuildContext context) {
    final ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    final ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();
    final SelectionViewData selection = context.watch<SelectionViewData>();
    final String domainNameKey = selection.CurrentDomainNodeKey;
    final NodeViewData? nodeViewData = viewDataDic.GetNodeViewData(domainNameKey);
    if(nodeViewData is Null) return ErrorWidget("exception");
    final NodeDrawingData? nodeDrawingData = nodeDrawingDataDic.GetNodeDrawingData(domainNameKey);
    if(nodeDrawingData is Null) return ErrorWidget("exception");

    final ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();

    Offset lastViewPos = nodeViewData.CurViewPos();
    double scale = nodeViewData.scale;
    print("重新绘制stackModel");
    return GestureDetector(
      onScaleStart: (details)
      {
        lastViewPos = nodeViewData.CurViewPos();
        scale = nodeViewData.scale;
      },
      onScaleUpdate: (details)
      {
        nodeViewData.MoveScaleView(details.focalPointDelta,details.scale);
        //nodeGroupModel.MoveScale();
        print("scale ${nodeViewData.scale} pos ${nodeViewData.CurViewPos()}" );

      },
      onScaleEnd: (details){
        nodeViewData.EndScaleView(lastViewPos,scale);
      },
      child: _BuildStack(nodeViewData,nodeDrawingData,selection,treeModel,nodeDrawingDataDic),
    );


  }
  Widget _BuildStack(NodeViewData viewData,NodeDrawingData parentDrawingData,SelectionViewData selection,ConceptTreeModel treeModel,ConceptTree2NodeDrawingDataDic drawingDataDic){
    ConceptNodeTree? nodeTree = treeModel.GetConceptNodeByDic(selection.CurrentDomainNodeKey);
    if(nodeTree == null) return ErrorWidget("exception,getNodeTreeError");
    print("重新绘制stack");
    return Stack(
      children: [Container(color: Colors.blueGrey)
        ,...nodeTree.children.asMap().entries.map((nodeTreeMap){
          final String domainNameKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, nodeTreeMap.value.name, nodeTreeMap.value.alias);
          final NodeDrawingData? drawingData = drawingDataDic.GetNodeDrawingData(domainNameKey);
          if(drawingData is Null) return ErrorWidget("exception");
          
          Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
          switch(drawingData.sortingMode){
            case SortingMode.grid:
              print(nodeTreeMap.key);
              return Positioned(
                left : (nodeSize.width * parentDrawingData.childrenNodePos[nodeTreeMap.key].x) + viewData.viewPosX,
                top : nodeSize.height * parentDrawingData.childrenNodePos[nodeTreeMap.key].y + viewData.viewPosY,

                child: LevelNode(drawingData: drawingData, nodeTree: nodeTree,),

              );
              default :
                break;
          }

        return LevelNode(drawingData: drawingData, nodeTree: nodeTree,);
      }),
        PopInspector(child: EditorPanel(), isPop: true, landscapePopWidth: 300, portraitPopHeight: 200, landscapeHeight:200, portraitWidth: 200,),
      ],
    );
  }
}
