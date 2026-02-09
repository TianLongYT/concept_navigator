import 'package:concept_navigator/MTools/UI/DebugUI.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodePosition.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SelectorBox extends StatelessWidget {


  const SelectorBox({super.key,required this.offset});

  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final ConceptTree2NodeViewDataDic conceptTree2NodeViewDataDic = context.watch<ConceptTree2NodeViewDataDic>();
    final ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    final SelectionViewData selection = context.watch<SelectionViewData>();
    final ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    final ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();

    final NodeViewData? nodeViewData = conceptTree2NodeViewDataDic.GetNodeViewData(selection.CurrentDomainNodeKey);
    if(nodeViewData == null) return ErrorWidget("exception,选择框没找到nodeviewData，检查参数配置");
    double scale = nodeViewData.scale;

    if(!selection.IsSelecting)
      return Placeholder();
    NodePositionHelper nodePositionHelper = NodePositionHelper(treeModel: treeModel, domainDrawingDataDic: domainDrawingDataDic, nodeDrawingDataDic: nodeDrawingDataDic, viewDrawingDataDic: conceptTree2NodeViewDataDic);
    nodePositionHelper.InitData(selection.IsInDomain, selection.currentDomain, selection.CurrentDomainNodeKey);

    Offset? position = nodePositionHelper.GetNodePositionByInstance(selection.SelectedConceptNode, selection.SelectedDomain);
    Size nodeSize = nodePositionHelper.nodeSize!;
    if(position == null)
      return ErrorWidget("选择框查找位置错位，可能是参数传递错误");
    return Positioned(
        left : position.dx * scale + nodeViewData.viewPosX * scale + offset.dx,
        top : position.dy * scale + nodeViewData.viewPosY * scale + offset.dy,
        child: IgnorePointer(
          child: Transform.scale(
            alignment: Alignment.topLeft,
            scale: scale,
            //child:DebugUI.pointer()
            child: Container(
              width: nodeSize.width ,
              height: nodeSize.height ,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(),
              ),
            ),
          ),
        )
    );


    // NodeViewData? nodeViewData = conceptTree2NodeViewDataDic.GetNodeViewData(selection.CurrentDomainNodeKey);
    // if(nodeViewData == null)
    //   return ErrorWidget("选择框无法找到当前窗口的ViewData");

    if(selection.IsInDomain){
      DomainDrawingData? domainDrawingData = domainDrawingDataDic.GetDomainDrawingData(selection.currentDomain);
      if(domainDrawingData == null){
        return ErrorWidget("选择框无法通过当前域找到域绘制数据");
      }
      DomainTree? domainTree = treeModel.GetDomainTree(selection.currentDomain);
      if(domainTree == null){
        return ErrorWidget("选择框无法通过当前域找到当前域树");
      }

      //如果在域内，且节点和域都不为空，需要计算域到节点的偏移。
      Offset domainOffset = Offset.zero;
      Offset conceptOffset = Offset.zero;
      if(selection.IsInDomain){
        //计算domain所占的宽度。
        double domainWidth = 0;
        if(domainTree!.children.length!= 0){
          final String domainNameKey = ConceptTreeModel.AppendDomainKey(selection.currentDomain, domainTree!.children[0].name);
          final NodeDrawingData? drawingData = domainDrawingDataDic.GetDomainDrawingData(domainNameKey);
          if(drawingData == null) return ErrorWidget("exception，找不到第一个子域的渲染数据");
          Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
          int usefulCount = domainTree!.children.length > domainDrawingData!.domainMaxX ? domainDrawingData!.domainMaxX:domainTree!.children.length;

          domainWidth = usefulCount * nodeSize.width;
        }

        //计算concept所占宽度。
        double conceptWidth = 0;
        if(domainTree!.conceptNodeTree.length!= 0){
          final String domainNameKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, domainTree.conceptNodeTree[0].name, domainTree.conceptNodeTree[0].alias);
          final NodeDrawingData? drawingData = nodeDrawingDataDic.GetNodeDrawingData(domainNameKey);
          if(drawingData == null) return ErrorWidget("exception,根据子树找不到绘制子节点的渲染物体,键:${domainNameKey}");

          Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
          int usefulCount = domainTree!.conceptNodeTree.length > domainDrawingData!.maxX ? domainDrawingData!.maxX:domainTree!.conceptNodeTree.length;

          conceptWidth = usefulCount * nodeSize.width;
        }
        //计算中轴线位置。

        //计算offset偏移。
        double maxWidth = domainWidth > conceptWidth?domainWidth: conceptWidth;

        Offset allOffset = Offset( maxWidth *1.1,0);//加上基础偏移值。
        double t = domainWidth/(domainWidth+conceptWidth);
        domainOffset = - allOffset * t;
        conceptOffset = allOffset * (1-t);

      }


      if(selection.IsSelectedConceptNode){
        ConceptNodeTree selectedConceptNode = selection.SelectedConceptNode!;
        int? index = domainTree.FindConceptIndex(selectedConceptNode);
        if(index == null) {
          return ErrorWidget("选择框无法根据当前选择的节点在域树中找到对应树");
        }
        String domainNameKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, selectedConceptNode.name, selectedConceptNode.alias);
        final NodeDrawingData? drawingData = nodeDrawingDataDic.GetNodeDrawingData(domainNameKey);
        if(drawingData == null) return ErrorWidget("选择框无法找到当前选择节点的绘制数据");

        Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
        //把位置绘制在选中的节点上。
        return Positioned(
          left: nodeSize.width * domainDrawingData!.childrenNodePos[index!].x + nodeViewData.viewPosX + conceptOffset.dx,
          top: nodeSize.height * domainDrawingData!.childrenNodePos[index!].y + nodeViewData.viewPosY + conceptOffset.dy,
            child: IgnorePointer(
              child: Container(
                width: nodeSize.width,
                height: nodeSize.height,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(),
                ),
              ),
            )
        );
      }
      else if (selection.IsSelectedDomain){
        DomainTree selectedDomain = selection.SelectedDomain!;
        int? index = domainTree.FindDomainIndex(selectedDomain);
        if(index == null) {
          return ErrorWidget("选择框无法根据当前选择的节点在域树中找到对应树");
        }
        String domainNameKey = selection.currentDomain;
        final NodeDrawingData? drawingData = domainDrawingDataDic.GetDomainDrawingData(domainNameKey);
        if(drawingData == null) return ErrorWidget("选择框无法找到当前选择节点的绘制数据");

        Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
        //把位置绘制在选中的节点上。
        return Positioned(
            left: nodeSize.width * domainDrawingData!.childrenDomainPos[index!].x + nodeViewData.viewPosX + domainOffset.dx ,
            top: nodeSize.height * domainDrawingData!.childrenDomainPos[index!].y + nodeViewData.viewPosY + domainOffset.dy ,
            child: Container(
              width: nodeSize.width,
              height: nodeSize.height,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(),
              ),
            )
        );
      }
    }
    else{

      NodeDrawingData? nodeDrawingData = nodeDrawingDataDic.GetNodeDrawingData(selection.CurrentDomainNodeKey);
      if(nodeDrawingData == null){
        return ErrorWidget("选择框无法通过当前概念找到概念绘制数据");
      }
      ConceptNodeTree? nodeTree = treeModel.GetConceptNodeByDic(selection.CurrentDomainNodeKey);
      if(nodeTree == null){
        return ErrorWidget("选择框无法通过当前概念找到当前概念树");
      }

      if(selection.IsSelectedConceptNode){
        ConceptNodeTree selectedConceptNode = selection.SelectedConceptNode!;
        //print("找到的节点树" +nodeTree.toString() + "选中的节点树"+selectedConceptNode.toString() );
        int? index = nodeTree.FindIndex(selectedConceptNode);
        if(index == null) {
          return ErrorWidget("选择框无法根据当前选择的节点在概念树中找到对应树");
        }
        String domainNameKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, selectedConceptNode.name, selectedConceptNode.alias);
        final NodeDrawingData? drawingData = nodeDrawingDataDic.GetNodeDrawingData(domainNameKey);
        if(drawingData == null) return ErrorWidget("选择框无法找到当前选择节点的绘制数据");

        Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
        //把位置绘制在选中的节点上。
        return Positioned(
            left: nodeSize.width * nodeDrawingData!.childrenNodePos[index!].x + nodeViewData.viewPosX,
            top: nodeSize.height * nodeDrawingData!.childrenNodePos[index!].y + nodeViewData.viewPosY,
            child: IgnorePointer(
              child: Container(
                width: nodeSize.width,
                height: nodeSize.height,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(),
                ),
              ),
            )
        );
      }
    }

    return Placeholder();

  }
}
