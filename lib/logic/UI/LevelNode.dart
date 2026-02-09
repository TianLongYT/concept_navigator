
import 'dart:ui';

import 'package:concept_navigator/MTools/UI/DebugUI.dart';
import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
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
    GlobalStateModel stateModel = context.watch<GlobalStateModel>();

    ConceptTree2NodeViewDataDic nodeViewDic = context.watch<ConceptTree2NodeViewDataDic>();
    NodeViewData? nodeViewData = nodeViewDic.GetNodeViewData(parentNodeTree.GetDomainNodeKey());
    if(nodeViewData == null){
      throw Exception("LevelNode找不到NodeViewData");
    }

    NodePositionHelper posHelper = NodePositionHelper.byContext(context);
    posHelper.InitData(parentNodeTree.IsInDomain, parentNodeTree.GetDomainKey(), parentNodeTree.GetDomainNodeKey());

    //获取当前位置。
    Offset? pos = posHelper.GetNodePositionByInstance(nodeTree, null);



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

                  selection.SelectedConceptNode = nodeTree;
                  stateModel.State = GlobalState.selectedNode;

                  AnimationController controller = GlobalCoroutine().controller;
                  double originPosX = nodeViewData.viewPosX;
                  double targetPosX = -pos!.dx - allSize.width * 0.5;
                  double originPosY = nodeViewData.viewPosY;
                  double targetPosY = -pos!.dy - allSize.height * 0.5;
                  controller.duration = Duration(milliseconds: 300);
                  controller.addListener((){
                    double t = controller.value;

                    //print("tick${t}");

                    nodeViewData.viewPosX = Tween(begin: originPosX, end: targetPosX)
                                              .chain(CurveTween(curve: Curves.easeOut))
                                              .animate(controller).value;
                    //print("posX${nodeViewData.viewPosX},origin${originPosX},target${targetPosX}");
                    nodeViewData.viewPosY = Tween(begin: originPosY,end: targetPosY)
                                              .chain(CurveTween(curve: Curves.easeOut))
                                              .animate(controller).value;
                    nodeViewDic.repaint();
                  });
                  controller.forward(from: 0);
                  //controller.stop();

                },
                onDoubleTap: (){
                  print("double clicked node ${nodeTree.name}");

                  addressBarModel.AddConceptAddress(nodeTree);

                  selection.CancelSelection();
                  selection.currentConceptNodeName = nodeTree!.name;
                  selection.currentConceptNodeAlias = nodeTree!.alias;
                  stateModel.State = GlobalState.normal;


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
