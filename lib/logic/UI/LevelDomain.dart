
import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/NodeSwapModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodeInfo/GetNodePosition.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GlobalCoroutine.dart';
import 'package:concept_navigator/logic/UI/LevelNodePresentation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class LevelDomain extends StatelessWidget {

  LevelDomain({super.key,double scale = 1.0,required this.parentConceptDrawingData,required this.parentDomainDrawingData, required this.drawingData, required this.domainTree, required this.parentNodeTree, }):
    _scale = scale;
  final NodeDrawingData? parentConceptDrawingData;//仅仅传入父节点绘制物的推荐颜色。
  final DomainDrawingData? parentDomainDrawingData;
  final NodeDrawingData drawingData;
  final NodeTree parentNodeTree;
  final DomainTree domainTree;

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
    FocusNodeHelper focusNodeHelper = FocusNodeHelper(context,parentNodeTree.IsInDomain, parentNodeTree.GetDomainKey(), parentNodeTree.GetDomainNodeKey(),nodeAllSize:  allSize);

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
            print("clicked domain ${domainTree.name}");
            if(editingStateModel.State == EditingState.selectingMovingNode){
              //初始化自身坐标了。
              selection.SelectedDomain = domainTree;
              globalStateModel.State = GlobalState.editingDomain;
              swapModel.initMoveData(selection);
              editingStateModel.State = EditingState.waitingMovingTarget;
              return;
            }
            else if(editingStateModel.State == EditingState.waitingMovingTarget){
              //自身与目标交换了！！！！
              int? index = swapModel.getNodeIndex(selection,childConceptTree: null,childDomainTree: domainTree);
              if(index == null){
                throw Exception("LevelNode尝试通过NodeSwapModel找自身在父Tree的Index,但是失败了");
              }
              if(index == swapModel.originIndex){
                return;
              }
              int originIndex = swapModel.originIndex;
              swapModel.nodeSwap(swapModel.originIndex, index, selection.IsInDomain, true);
              commandManager.moveNodeInstance.PushCommand(
                  Command(
                      function: (){
                        swapModel.nodeSwap(originIndex, index, selection.IsInDomain, true);//创建临时变量。防止调用时再次获取当前的sawpModel.originIndex。
                        swapModel.rebuildNodeTreeDic();
                      },
                      undoFunction: (){
                        swapModel.nodeSwap(originIndex, index, selection.IsInDomain, true);
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
            selection.SelectedDomain = domainTree;
            globalStateModel.State = GlobalState.editingDomain;

            focusNodeHelper.FocusNode(null, domainTree);

          },
          onDoubleTap: (){
            print("double clicked domain ${domainTree.name}");

            addressBarModel.AddDomainAddress(domainTree);

            selection.CancelSelection();
            selection.currentDomain = ConceptTreeModel.AppendDomainKey(selection.currentDomain,  domainTree!.name);
            globalStateModel.State = GlobalState.normal;


          },
          child: LevelNodePresentation(scale: _scale,isDomain: true,parentConceptDrawingData: parentConceptDrawingData,parentDomainDrawingData: parentDomainDrawingData,drawingData: drawingData, nodeTree: null,domainTree: domainTree,),
        ),
      );
  }
}
