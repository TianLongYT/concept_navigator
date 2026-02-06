import 'package:concept_navigator/MTools/UI/DebugUI.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
//import 'package:concept_navigator/logic/Data/GlobalState.dart';
//import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
//import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodePosition.dart';
import 'package:concept_navigator/logic/UI/LevelDomain.dart';
import 'package:concept_navigator/logic/UI/LevelNode.dart';
import 'package:concept_navigator/logic/UI/LevelNodePresentation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LevelNodePanel  extends StatelessWidget {
  final double _scale;
  final bool isInDomain;
  final String currentDomainKey;
  final String currentDomainNodeKey;

  const LevelNodePanel({super.key,double scale = 1.0, required this.isInDomain, required this.currentDomainKey, required this.currentDomainNodeKey}):
    _scale = scale;


  @override
  Widget build(BuildContext context) {
    final ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    final ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    final ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();
    //final SelectionViewData selection = context.watch<SelectionViewData>();
    final ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();

    //节点位置助手
    NodePositionHelper nodePositionHelper = NodePositionHelper(treeModel: treeModel, domainDrawingDataDic: domainDrawingDataDic, nodeDrawingDataDic: nodeDrawingDataDic, viewDrawingDataDic: viewDataDic);
    nodePositionHelper.InitData(isInDomain, currentDomainKey, currentDomainNodeKey);

    ConceptNodeTree? nodeTree = nodePositionHelper.nodeTree;
    DomainTree? domainTree = nodePositionHelper.domainTree;

    //根据整体大小计算最终缩放。
    double scale = 0.5;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        print("Layerconstraints${constraints}");
        double scaleW = constraints.maxWidth / nodePositionHelper.levelSizeWithoutEmpty!.width;
        double scaleH = constraints.maxHeight / nodePositionHelper.levelSizeWithoutEmpty!.height;
        scale  = scaleW>scaleH? scaleH:scaleW;
        print("levelHeight${nodePositionHelper.levelSizeWithoutEmpty!.height} calculatedScale${scale}");

        return Stack(
          children: [
            if (isInDomain)
              Stack(
                children: [
                  //绘制域。
                  ...domainTree!.children.asMap().entries.map((nodeTreeMap){

                    Offset position = nodePositionHelper.GetNodePositionByIndex(true, nodeTreeMap.key);
                    return Positioned(
                      left : position.dx * scale,
                      top : position.dy * scale,
                      //child: DebugUI.pointer(),
                      child:LevelNodePresentation(scale: scale,drawingData: nodePositionHelper.childDomainDrawingData!, isInDomain: true,nodeTree: null,domainTree: nodeTreeMap.value!,),
                    );

                  })

                  //绘制节点
                  ,...domainTree!.conceptNodeTree.asMap().entries.map((nodeTreeMap){

                    Offset position = nodePositionHelper.GetNodePositionByIndex(false, nodeTreeMap.key);

                    return Positioned(
                      left : position.dx * scale ,
                      top : position.dy * scale,
                      //child: DebugUI.pointer(),
                      child: LevelNodePresentation(scale: scale, drawingData: nodePositionHelper.childNodeDrawingData!,isInDomain: false, nodeTree: nodeTreeMap.value!,domainTree: null,),
                    );
                  })

                ],
              )

            else
              ...nodeTree!.children.asMap().entries.map((nodeTreeMap){

                Offset position = nodePositionHelper.GetNodePositionByIndex(false, nodeTreeMap.key);

                return Positioned(
                  left : position.dx * scale ,
                  top : position.dy *scale,
                  //child: DebugUI.pointer(),
                  child: LevelNodePresentation(isInDomain: false,scale: scale,drawingData: nodePositionHelper.childNodeDrawingData!, nodeTree: nodeTreeMap.value!,domainTree: null,),
                );

              }),
          ],
        );
      },

    );

  }
}
