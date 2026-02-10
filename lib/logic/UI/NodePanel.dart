import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/UI/AddressBar/AddressBar.dart';
import 'package:concept_navigator/logic/UI/EditPanel/EditorPanel.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/CustomGesture/PanGestureDetector.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodePosition.dart';
import 'package:concept_navigator/logic/UI/LevelDomain.dart';
import 'package:concept_navigator/logic/UI/LevelNode.dart';
import 'package:concept_navigator/logic/UI/LevelNodePresentation.dart';
import 'package:concept_navigator/logic/UI/PopInspector.dart';
import 'package:concept_navigator/logic/UI/SelectorBox.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Nodepanel extends StatelessWidget {
  const Nodepanel({super.key});
  //制作levelNode的排版功能。显示所有的levelNode。


  @override
  Widget build(BuildContext context) {
    //获取必要显示数据。
    final ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    final ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    final ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();
    final SelectionViewData selection = context.watch<SelectionViewData>();
    final ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    final GlobalStateModel globalStateModel = context.watch<GlobalStateModel>();

    //节点位置助手
    NodePositionHelper nodePositionHelper = NodePositionHelper(treeModel: treeModel, domainDrawingDataDic: domainDrawingDataDic, nodeDrawingDataDic: nodeDrawingDataDic, viewDrawingDataDic: viewDataDic);
    nodePositionHelper.InitData(selection.IsInDomain, selection.currentDomain, selection.CurrentDomainNodeKey);
    //获取视口数据
    final NodeViewData? nodeViewData = viewDataDic.GetNodeViewData(selection.CurrentDomainNodeKey);
    if(nodeViewData == null) return ErrorWidget("exception,节点绘制主界面没找到nodeviewData，检查参数配置");

    ConceptNodeTree? nodeTree = nodePositionHelper.nodeTree;
    DomainTree? domainTree = nodePositionHelper.domainTree;

    double scale = nodeViewData.scale;

    //
    // DomainDrawingData? domainDrawingData;
    // NodeDrawingData? nodeDrawingData;
    //
    // nodeTree = treeModel.GetConceptNodeByDic(selection.CurrentDomainNodeKey);
    //
    // if(selection.IsInDomain){
    //   domainDrawingData = domainDrawingDataDic.GetDomainDrawingData(domainNameKey);
    //   if(domainDrawingData == null) return ErrorWidget("exception，未找到当前domainDrawingData");
    //   domainTree = treeModel.GetDomainTree(selection.currentDomain);
    //   if(domainTree == null) return ErrorWidget("exception,getDomainTreeError");
    // }
    // else{
    //   nodeDrawingData = nodeDrawingDataDic.GetNodeDrawingData(domainNameKey);
    //   if(nodeDrawingData == null) return ErrorWidget("exception，未找到当前nodeDrawingData");
    //   if(nodeTree == null) return ErrorWidget("exception,getNodeTreeError");
    // }
    //
    //
    //
    //

    //
    // //如果在域内，且节点和域都不为空，需要计算域到节点的偏移。
    // Offset domainOffset = Offset.zero;
    // Offset conceptOffset = Offset.zero;
    // if(selection.IsInDomain){
    //   //计算domain所占的宽度。
    //   double domainWidth = 0;
    //   if(domainTree!.children.length!= 0){
    //     final String domainNameKey = ConceptTreeModel.AppendDomainKey(selection.currentDomain, domainTree!.children[0].name);
    //     final NodeDrawingData? drawingData = domainDrawingDataDic.GetDomainDrawingData(domainNameKey);
    //     if(drawingData == null) return ErrorWidget("exception，找不到第一个子域的渲染数据");
    //     Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
    //     int usefulCount = domainTree!.children.length > domainDrawingData!.domainMaxX ? domainDrawingData!.domainMaxX:domainTree!.children.length;
    //
    //     domainWidth = usefulCount * nodeSize.width;
    //   }
    //
    //   //计算concept所占宽度。
    //   double conceptWidth = 0;
    //   if(domainTree!.conceptNodeTree.length!= 0){
    //     final String domainNameKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, domainTree.conceptNodeTree[0].name, domainTree.conceptNodeTree[0].alias);
    //     final NodeDrawingData? drawingData = nodeDrawingDataDic.GetNodeDrawingData(domainNameKey);
    //     if(drawingData == null) return ErrorWidget("exception,根据子树找不到绘制子节点的渲染物体,键:${domainNameKey}");
    //
    //     Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
    //     int usefulCount = domainTree!.conceptNodeTree.length > domainDrawingData!.maxX ? domainDrawingData!.maxX:domainTree!.conceptNodeTree.length;
    //
    //     conceptWidth = usefulCount * nodeSize.width;
    //   }
    //   //计算中轴线位置。
    //
    //   //计算offset偏移。
    //   double maxWidth = domainWidth > conceptWidth?domainWidth: conceptWidth;
    //   Offset allOffset = Offset( maxWidth *1.1,0);//加上基础偏移值。
    //   double t = domainWidth/(domainWidth+conceptWidth);
    //   domainOffset = - allOffset * t;
    //   conceptOffset = allOffset * (1-t);
    //
    // }

    print("重新绘制stackModel,节点树"+treeModel.PrintTree() + "\r\n概念树字典${treeModel.PrintDic()}"+"\r\n节点名到渲染物"+nodeDrawingDataDic.toString());
    final Widget editorPanel = GestureDetector(
      onTap: (){
        print("onTapEditor");
      },
        child: EditorPanel()
    );
    final Widget bgContainer = GestureDetector(//手势识别会进行冲突判断，且一次仅有一个手势可以被执行。
        onTap: (){
          print("onTap");
          if(selection.IsSelecting) {
            globalStateModel.State = GlobalState.normal;
            selection.CancelSelection();
          }
        },
        child: Container(color: Colors.black38),
    );




      return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints){
        bool isPop = globalStateModel.State != GlobalState.normal;
        // 获取屏幕方向
        bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

        double landscapeContractWidth = 100;
        double landscapePopWidth = 200;
        double portraitContractHeight = 10;
        double portraitPopHeight = 300;

        double centerLeft = 100;
        double centerTop = 100;

        if(isLandscape){
          print("MainMenuConstraints${constraints}");
          centerLeft = isPop? (constraints.maxWidth - landscapePopWidth)  * 0.5 : (constraints.maxWidth - landscapeContractWidth) * 0.5;
          centerTop = constraints.maxHeight * 0.5;
        }
        else{
          centerLeft = constraints.maxWidth * 0.5;
          centerTop = isPop? (constraints.maxHeight - portraitPopHeight) * 0.5 : (constraints.maxHeight - portraitContractHeight) * 0.5;
        }
        final Widget selectorBox = SelectorBox(offset: Offset(centerLeft, centerTop),);


        Widget MainNodePanel = Stack(
          children: [
            if (selection.IsInDomain)
              Stack(
                children: [
                  //绘制域。
                  ...domainTree!.children.asMap().entries.map((nodeTreeMap){

                    Offset position = nodePositionHelper.GetNodePositionByIndex(true, nodeTreeMap.key);
                    DomainDrawingData drawingData= nodePositionHelper.childDomainDrawingData!;
                    Size nodeSize = nodePositionHelper.nodeSize! * scale;

                    return Positioned(
                      left : position.dx * scale + nodeViewData.viewPosX * scale ,
                      top : position.dy * scale + nodeViewData.viewPosY * scale ,


                      child:AnimatedPadding(
                        duration: Duration(milliseconds: 200),
                        padding: EdgeInsetsGeometry.only(left:  centerLeft, top:  centerTop),
                        child: SizedBox(
                            width: nodeSize.width,
                            height:  nodeSize.height,
                            child:
                            LevelDomain(scale: scale, drawingData: drawingData, domainTree: nodeTreeMap.value!,parentNodeTree: domainTree,)
                        ),
                      ),


                    );

                  })

                  //绘制节点
                  ,...domainTree!.conceptNodeTree.asMap().entries.map((nodeTreeMap){

                    Offset position = nodePositionHelper.GetNodePositionByIndex(false, nodeTreeMap.key);
                    NodeDrawingData drawingData= nodePositionHelper.childNodeDrawingData!;
                    Size nodeSize = nodePositionHelper.nodeSize! * scale;

                    return Positioned(
                      left : position.dx * scale + nodeViewData.viewPosX * scale ,
                      top : position.dy * scale + nodeViewData.viewPosY * scale ,
                      child: AnimatedPadding(
                          //alignment: AlignmentGeometry.xy(100, 100),
                          padding: EdgeInsetsGeometry.only(left: centerLeft,top: centerTop),
                          duration: Duration(milliseconds: 200),
                          child: LevelNode(
                            scale: scale,
                            drawingData: nodePositionHelper.childNodeDrawingData!,
                            nodeTree: nodeTreeMap.value!,
                            parentNodeTree: domainTree,
                          ),
                      ),
                    );
                  })

                ],
              )

            else
              ...nodeTree!.children.asMap().entries.map((nodeTreeMap){

                Offset position = nodePositionHelper.GetNodePositionByIndex(false, nodeTreeMap.key);

                return Positioned(
                  left : position.dx * scale + nodeViewData.viewPosX * scale ,
                  top : position.dy * scale + nodeViewData.viewPosY * scale ,
                  child: AnimatedPadding(
                    padding: EdgeInsets.only(left: centerLeft,top: centerTop),
                    duration: Duration(milliseconds: 200),
                    child: LevelNode(
                      scale: scale,
                      drawingData: nodePositionHelper.childNodeDrawingData!,
                      nodeTree: nodeTreeMap.value!,
                      parentNodeTree: nodeTree,
                    ),
                  ),

                );

              }),
          ],
        );
        Widget MainNodePanelWithGesture = CustomScaleGestureDetector(

          onStart: (startDetails){
            nodeViewData.SaveCurData();
            viewDataDic.repaint();
            print("onScaleStart");
          },
          onUpdate: (details){
            nodeViewData.MoveScaleView(details.focalPointDelta,details.scale);
            print("onScaleUpdate ${nodeViewData.scale} detail ${details.scale} pos ${nodeViewData.CurViewPos()} focal point ${details.focalPoint} point count ${details.pointerCount} "  );
            viewDataDic.repaint();
          },
          onEnd: (endDetails){
            nodeViewData.UploadDataCommand();
            viewDataDic.repaint();
            print("onScaleEnd");
          },

          child: Listener(
            //onPointerDown: (_){print("ONPointerDown");},//还需要额外处理双指缩放。//键鼠滚轮输入等。//需要使用自定义的手势识别器。

            onPointerPanZoomStart: (PointerPanZoomStartEvent details)//专门处理触摸板用的。
            {
              nodeViewData.SaveCurData();
              viewDataDic.repaint();
              print("**********************************************Scale Start");
            },
            onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent details)
            {
              nodeViewData.MoveScaleView(details.panDelta,details.scale);
              //nodeGroupModel.MoveScale();
              print("scale ${nodeViewData.scale} detail ${details.scale} pos ${nodeViewData.CurViewPos()} focal point ${details.pan} point count ${details.pointer} "  );
              viewDataDic.repaint();
            },
            onPointerPanZoomEnd: (details)
            {
              nodeViewData.UploadDataCommand();
              viewDataDic.repaint();
            },

            child: MainNodePanel,
          ),
        );
        Widget PopingEditPanel = PopInspector(
          isPop: isPop,
          landscapePopWidth: landscapePopWidth,
          portraitPopHeight: portraitPopHeight,
          portraitContractHeight: portraitContractHeight,
          landscapeContractWidth: landscapeContractWidth,
          landscapeHeight:constraints.maxHeight,
          portraitWidth: constraints.maxWidth,
          child: editorPanel,
        );

        return Stack(
          children: [
            bgContainer,
            AddressBar(maxWidth: constraints.maxWidth,),

            MainNodePanelWithGesture,
            // if (selection.IsInDomain)
            //   Stack(
            //     children: [
            //       //绘制域。
            //       ...domainTree!.children.asMap().entries.map((nodeTreeMap){
            //
            //         Offset position = nodePositionHelper.GetNodePositionByIndex(true, nodeTreeMap.key);
            //         DomainDrawingData drawingData= nodePositionHelper.childDomainDrawingData!;
            //         Size nodeSize = nodePositionHelper.nodeSize! * scale;
            //
            //         return Positioned(
            //           left : position.dx * scale + nodeViewData.viewPosX * scale,
            //           top : position.dy * scale + nodeViewData.viewPosY * scale,
            //
            //
            //           child:SizedBox(
            //             width: nodeSize.width,
            //             height:  nodeSize.height,
            //             child:
            //               LevelDomain(drawingData: drawingData, domainTree: nodeTreeMap.value!,)
            //           ),
            //
            //
            //         );
            //
            //       })
            //
            //       //绘制节点
            //       ,...domainTree!.conceptNodeTree.asMap().entries.map((nodeTreeMap){
            //
            //         Offset position = nodePositionHelper.GetNodePositionByIndex(false, nodeTreeMap.key);
            //         NodeDrawingData drawingData= nodePositionHelper.childNodeDrawingData!;
            //         Size nodeSize = nodePositionHelper.nodeSize! * scale;
            //
            //         return Positioned(
            //           left : position.dx * scale + nodeViewData.viewPosX * scale,
            //           top : position.dy * scale + nodeViewData.viewPosY * scale,
            //           child: LevelNodePresentation(scale: scale,drawingData: nodePositionHelper.childNodeDrawingData!, nodeTree: nodeTreeMap.value!,),
            //
            //         );
            //       })
            //
            //     ],
            //   )
            //
            // else
            // ...nodeTree!.children.asMap().entries.map((nodeTreeMap){
            //
            //   Offset position = nodePositionHelper.GetNodePositionByIndex(false, nodeTreeMap.key);
            //
            //   return Positioned(
            //     left : position.dx * scale + nodeViewData.viewPosX * scale,
            //     top : position.dy * scale + nodeViewData.viewPosY * scale,
            //     child: LevelNode(scale: scale,drawingData: nodePositionHelper.childNodeDrawingData!, nodeTree: nodeTreeMap.value!,),
            //
            //   );
            //
            // }),
            //绘制选择框光标。
            if(selection.IsSelecting)
              selectorBox,

            PopingEditPanel,

          ],
        );
      },
    );
  }
}
