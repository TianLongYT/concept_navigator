
import 'dart:ui';

import 'package:concept_navigator/MTools/UI/DebugUI.dart';
import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/NodeSwapModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/DeleteNodeLogic.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodeInfo/GetNodePosition.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GlobalCoroutine.dart';

import 'package:concept_navigator/logic/UI/LevelNodePresentation.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class LevelNode extends StatelessWidget {

  LevelNode({super.key,double scale = 1.0,required this.parentConceptDrawingData,required this.parentDomainDrawingData, required this.drawingData, required this.nodeTree, required this.parentNodeTree}):
    _scale = scale;
  final NodeDrawingData? parentConceptDrawingData;//仅仅传入父节点绘制物的推荐颜色。
  final DomainDrawingData? parentDomainDrawingData;
  final NodeDrawingData drawingData;
  final NodeTree parentNodeTree;
  final ConceptNodeTree nodeTree;


  final double _scale;


  @override
  Widget build(BuildContext context) {

    Size deltaSize = drawingData.nodeAppearance.nodeSize * (drawingData.nodeAppearance.emptySize - 1);
    Size allSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
    SelectionViewData selection = context.watch<SelectionViewData>();
    AddressBarModel addressBarModel = context.watch<AddressBarModel>();
    GlobalStateModel globalStateModel = context.watch<GlobalStateModel>();
    EditingStateModel editingStateModel = context.watch<EditingStateModel>();
    NodeSwapModel swapModel = context.read<NodeSwapModel>();
    CommandManagerForProvider commandManager = context.read<CommandManagerForProvider>();

    ConceptTree2NodeViewDataDic nodeViewDic = context.read<ConceptTree2NodeViewDataDic>();



    //获取当前位置。

    FocusNodeHelper focusNodeHelper = FocusNodeHelper(context,parentNodeTree.IsInDomain, parentNodeTree.GetDomainKey(), parentNodeTree.GetDomainNodeKey(),nodeAllSize:  allSize);


    //drawingData.text = nodeTree.name;
    return LayoutBuilder(
        builder: (BuildContext context,BoxConstraints constraints){
          print("LevelNodeConstraints${constraints}");
          //return DebugUI.pointer(size: Size(100, 100),);

          return
            Padding(

              padding: EdgeInsetsGeometry.only(
                left: deltaSize.width * 0.5 * _scale,
                right : deltaSize.width * 0.5 * _scale,
                top:  deltaSize.height *0.5 * _scale,
                bottom:  deltaSize.height*0.5 * _scale,
              ),
              child: GestureDetector(
                onTap: (){
                  print("clicked node ${nodeTree.name}");
                  if(editingStateModel.State == EditingState.selectingMovingNode){
                    //初始化自身坐标了。
                    selection.SelectedConceptNode = nodeTree;
                    globalStateModel.State = GlobalState.editingConcept;
                    swapModel.initMoveData(selection);
                    editingStateModel.State = EditingState.waitingMovingTarget;
                    return;
                  }
                  else if(editingStateModel.State == EditingState.waitingMovingTarget){
                    //自身与目标交换了！！！！
                    int? index = swapModel.getNodeIndex(selection,childConceptTree: nodeTree,childDomainTree: null);
                    if(index == null){
                      throw Exception("LevelNode尝试通过NodeSwapModel找自身在父Tree的Index,但是失败了");
                    }
                    if(index == swapModel.originIndex){
                      return;
                    }
                    int originIndex = swapModel.originIndex;
                    swapModel.nodeSwap(swapModel.originIndex, index, selection.IsInDomain, false);
                    commandManager.moveNodeInstance.PushCommand(
                      Command(
                        function: (){
                          swapModel.nodeSwap(originIndex, index, selection.IsInDomain, false);//创建临时变量。防止调用时再次获取当前的sawpModel.originIndex。
                          swapModel.rebuildNodeTreeDic();
                        },
                        undoFunction: (){
                          swapModel.nodeSwap(originIndex, index, selection.IsInDomain, false);
                          swapModel.rebuildNodeTreeDic();
                          print("发生rebuild,${originIndex}与${index}交换");
                        }
                      )
                    );
                    //commandManager
                    //交换完过后，进入继续选择节点的状态。
                    editingStateModel.State = EditingState.selectingMovingNode;
                    return;
                  }

                  selection.SelectedConceptNode = nodeTree;
                  globalStateModel.State = GlobalState.editingConcept;

                  focusNodeHelper.FocusNode(nodeTree, null);
                  //controller.stop();

                },
                onDoubleTap: (){
                  print("double clicked node ${nodeTree.name}");

                  addressBarModel.AddConceptAddress(nodeTree);

                  selection.CancelSelection();
                  selection.currentConceptNodeName = nodeTree!.name;
                  selection.currentConceptNodeAlias = nodeTree!.alias;
                  selection.currentConceptTree = nodeTree;
                  selection.currentDomainTree = null;

                  globalStateModel.State = GlobalState.normal;


                },
                onLongPress: () {
                  // 长按进入粘贴模式
                  //DeleteNodeLogic.copyNode(context, nodeTree, parentNodeTree);
                  globalStateModel.State = GlobalState.pasting;
                },
                //behavior: HitTestBehavior.translucent,
                //child: DebugUI.pointer(size: Size(100, 100),),

                // child: Transform.scale(
                //   alignment: Alignment.topLeft,
                //   scale: _scale,
                  child: LevelNodePresentation(isDomain: false,parentConceptDrawingData: parentConceptDrawingData,parentDomainDrawingData: parentDomainDrawingData,drawingData: drawingData,scale: _scale,nodeTree: nodeTree,domainTree: null,),
                //),


              ),
            );

        });
    if(true){
      //尝试绘制子层节点。

      return Container(
        color: Colors.blue,
        width: allSize.width ,
        height: allSize.height,
      );
    }


  }
}
