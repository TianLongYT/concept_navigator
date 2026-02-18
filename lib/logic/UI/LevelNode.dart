
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
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodePosition.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GlobalCoroutine.dart';

import 'package:concept_navigator/logic/UI/LevelNodePresentation.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class LevelNode extends StatelessWidget {

  LevelNode({super.key,double scale = 1.0, required this.drawingData, required this.nodeTree, required this.parentNodeTree}):
    _scale = scale;
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

    FocusNodeHelper focusNodeHelper = FocusNodeHelper(context,parentNodeTree.IsInDomain, parentNodeTree.GetDomainKey(), parentNodeTree.GetDomainNodeKey(),allSize);


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
                  globalStateModel.State = GlobalState.normal;


                },
                //behavior: HitTestBehavior.translucent,
                //child: DebugUI.pointer(size: Size(100, 100),),

                // child: Transform.scale(
                //   alignment: Alignment.topLeft,
                //   scale: _scale,
                  child: LevelNodePresentation(isInDomain: false,drawingData: drawingData,scale: _scale,nodeTree: nodeTree,domainTree: null,),
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
// class NodePainter extends CustomPainter {
//
//   final NodeDrawingData drawingData;
//   const NodePainter({required this.drawingData});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//
//     NodeAppearance nodeAppearance = drawingData.nodeAppearance;
//     //double emptyRadio = (nodeAppearance.emptySize - 1) * 0.5;
//     //emptyRadio = emptyRadio>0? emptyRadio:0;
//     final Size coreSize = nodeAppearance.nodeSize;
//     final Rect coreRect = Rect.fromLTWH(0, 0, coreSize.width, coreSize.height);//Rect.fromCenter(center : Offset(0,0),width:  nodeAppearance.nodeSize.width,height: nodeAppearance.nodeSize.height);
//     final RRect coreRRect = RRect.fromRectAndRadius(coreRect, Radius.circular(coreSize.height * 0.1));
//     // 绘制核心节点
//     final Paint paint = Paint()
//       ..color = nodeAppearance.nodeColor
//       ..style = PaintingStyle.fill;
//
//     switch(nodeAppearance.shape){
//       case Shape.rect:
//         canvas.drawRect(coreRect,paint);
//         break;
//       case Shape.rRect:
//         canvas.drawRRect(coreRRect, paint);
//         break;
//       default:
//
//         break;
//     }
//
//     //绘制文字。
//     // 设置文字样式
//     final TextStyle textStyle = TextStyle(
//       color: nodeAppearance.fontColor,
//       fontSize: _getTextSize(coreSize), // 动态计算文字大小
//       fontWeight: FontWeight.bold,
//     );
//
//     final textSpan = TextSpan(text: drawingData.text, style: textStyle);
//
//     // 使用 TextPainter 绘制文字
//     final textPainter = TextPainter(
//       text: textSpan,
//       textDirection: TextDirection.ltr,
//       textAlign: TextAlign.left,
//
//     );
//
//     // 布局文字，使其自适应
//     textPainter.layout(maxWidth: coreSize.width*0.9);
//
//     // 计算文字绘制的位置（居中）
//     final Offset offset = Offset(//emptyRadio * coreSize.width,emptyRadio * coreSize.height
//       (size.width - textPainter.width) / 2,
//       (size.height - textPainter.height) / 2,
//     );
//     canvas.save();
//     canvas.clipRRect(coreRRect);
//     // 绘制文字
//     textPainter.paint(canvas, offset);
//     canvas.restore();
//
//     //绘制子节点。。。。。
//
//   }
//   double _getTextSize(Size size) {
//     // 根据矩形的宽度调整文字大小，可以根据需要自定义逻辑
//     return size.width * 0.15; // 比如根据宽度的 15% 来计算文字大小
//   }
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return true;
//   }
//
// }
// //size: Size(100,1999),//,
//
// //canvas.drawRect(Rect.fromCenter(center:  Offset(size.width / 2, size.height / 2),width:  400,height: 100), paint);
