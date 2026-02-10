//提供一个公用计算位置的算法。通过此算法获取节点具体位置。

import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GlobalCoroutine.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class NodePositionHelper{

  //加载当前界面的数据。
  NodePositionHelper({required this.treeModel
    ,required this. domainDrawingDataDic
    ,required this. nodeDrawingDataDic
    ,required this. viewDrawingDataDic
  }
      ) {


  }
  NodePositionHelper.byContext(BuildContext context):
    treeModel = context.read<ConceptTreeModel>(),
    domainDrawingDataDic = context.read<ConceptTree2DomainDrawingDataDic>(),
    nodeDrawingDataDic = context.read<ConceptTree2NodeDrawingDataDic>(),
    viewDrawingDataDic = context.read<ConceptTree2NodeViewDataDic>();


  ConceptTreeModel treeModel;
  ConceptTree2DomainDrawingDataDic domainDrawingDataDic;
  ConceptTree2NodeDrawingDataDic nodeDrawingDataDic;
  ConceptTree2NodeViewDataDic viewDrawingDataDic;

  bool isInDomain = false;
  String curDomainKey = "";

  DomainTree? domainTree;
  ConceptNodeTree? nodeTree;
  DomainDrawingData? domainDrawingData;
  NodeDrawingData? nodeDrawingData;

  //NodeViewData? nodeViewData;
  Offset domainOffset = Offset.zero;
  Offset conceptOffset = Offset.zero;



  void InitData(bool isInDomain
      ,String curDomainKey
      ,String curDomainNodeKey
      ){
    this.isInDomain = isInDomain;
    this.curDomainKey = curDomainKey;

    //nodeViewData = viewDrawingDataDic.GetNodeViewData(curDomainNodeKey);
    //if(nodeViewData == null){
      //throw Exception("无法找到视口数据");
    //}

    if(isInDomain){

      domainDrawingData = domainDrawingDataDic.GetDomainDrawingData(curDomainKey);
      if(domainDrawingData == null){
        throw Exception("无法获取当前域的渲染物");
      }
      domainTree = treeModel.GetDomainTree(curDomainKey);
      if(domainTree == null){
        throw Exception("无法获取当前域的树");
      }
      Size emptySize = Size.zero;

      //计算偏移量。域的大小。
      double domainWidth = 0;
      double domainHeight = 0;
      if(domainTree!.children.isNotEmpty){
        final String domainNameKey = ConceptTreeModel.AppendDomainKey(curDomainKey, domainTree!.children[0].name);
        final NodeDrawingData? drawingData = domainDrawingDataDic.GetDomainDrawingData(domainNameKey);
        if(drawingData == null) throw Exception("exception，找不到第一个子域的渲染数据");
        Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
        int usefulCount = domainTree!.children.length > domainDrawingData!.domainMaxX ? domainDrawingData!.domainMaxX:domainTree!.children.length;

        domainWidth = usefulCount * nodeSize.width;

        domainHeight = (domainTree!.children.length ~/ domainDrawingData!.domainMaxX + 1) * nodeSize.height;

        emptySize = drawingData.nodeAppearance.nodeSize * (drawingData.nodeAppearance.emptySize - 1);
      }

      //计算concept所占宽度。
      double conceptWidth = 0;
      double conceptHeight = 0;
      if(domainTree!.conceptNodeTree.isNotEmpty){
        final String domainNameKey = ConceptTreeModel.GenerateDomainNodeKey(curDomainKey, domainTree!.conceptNodeTree[0].name, domainTree!.conceptNodeTree[0].alias);
        final NodeDrawingData? drawingData = nodeDrawingDataDic.GetNodeDrawingData(domainNameKey);
        if(drawingData == null) throw Exception("exception,根据子树找不到绘制子节点的渲染物体,键:${domainNameKey}");

        Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
        int usefulCount = domainTree!.conceptNodeTree.length > domainDrawingData!.maxX ? domainDrawingData!.maxX:domainTree!.conceptNodeTree.length;

        conceptWidth = usefulCount * nodeSize.width;

        conceptHeight = (domainTree!.conceptNodeTree.length ~/ domainDrawingData!.maxX + 1) * nodeSize.height;

        emptySize = drawingData.nodeAppearance.nodeSize * (drawingData.nodeAppearance.emptySize - 1);

      }

      //计算offset偏移。
      Offset allOffset = Offset(domainWidth + emptySize.width * 2, 0) ;//加上基础偏移值。
      double t = domainWidth/(domainWidth+conceptWidth);
      // domainOffset = - allOffset * t;
      // conceptOffset = allOffset * (1-t) ;
      domainOffset = Offset.zero;
      conceptOffset = allOffset;

      //计算整个面板大小。
      levelSize = Size(allOffset.dx+ conceptWidth,domainHeight>conceptHeight?domainHeight:conceptHeight);
      levelSizeWithoutEmpty = Size(levelSize!.width - emptySize.width, levelSize!.height - emptySize.height);
    }
    else{

      nodeDrawingData = nodeDrawingDataDic.GetNodeDrawingData(curDomainNodeKey);
      if(nodeDrawingData == null){
        throw Exception("无法获取当前概念的渲染物,curDomainNodeKey${curDomainNodeKey}");
      }
      nodeTree = treeModel.GetConceptNodeByDic(curDomainNodeKey);
      if(nodeTree == null){
        throw Exception("无法获取当前概念的树,curDomainNodeKey${curDomainNodeKey}");
      }

      //计算概念群的大小。
      //计算concept所占宽度。
      double conceptWidth = 0;
      double conceptHeight = 0;
      Size emptySize = Size.zero;
      if(nodeTree!.children.isNotEmpty){
        final String domainNameKey = nodeTree!.children[0].GetDomainNodeKey(); //ConceptTreeModel.GenerateDomainNodeKey(curDomainKey, nodeTree!.children[0].name, nodeTree!.children[0].alias);
        final NodeDrawingData? drawingData = nodeDrawingDataDic.GetNodeDrawingData(domainNameKey);
        if(drawingData == null) throw Exception("exception,根据子树找不到绘制子节点的渲染物体,键:${domainNameKey}");

        Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
        int usefulCount = nodeTree!.children.length > nodeDrawingData!.maxX ? nodeDrawingData!.maxX:nodeTree!.children.length;

        conceptWidth = usefulCount * nodeSize.width;
        emptySize = drawingData.nodeAppearance.nodeSize * (drawingData.nodeAppearance.emptySize - 1);

        conceptHeight = (nodeTree!.children.length ~/ nodeDrawingData!.maxX + 1) * nodeSize.height;
        print("!!!!!!object${nodeTree!.children.length ~/ nodeDrawingData!.maxX}");
      }
      levelSize = Size(conceptWidth, conceptHeight);
      levelSizeWithoutEmpty = Size(conceptWidth - emptySize.width, conceptHeight - emptySize.height);

    }

  }
  Size _GetNodeSizeByIndex(bool isDomain,int childIndex){

    if(isInDomain){
      //如果选的是域，获取子域的信息。
      if(isDomain){
        final String childDomainName = domainTree!.children[childIndex].name;
        final String childDomainKey = ConceptTreeModel.AppendDomainKey(curDomainKey, childDomainName);
        final DomainDrawingData? drawingData = domainDrawingDataDic.GetDomainDrawingData(childDomainKey);
        if(drawingData == null) throw Exception("无法找到子域节点的绘制数据");

        childDomainDrawingData = drawingData;

        return drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
      }
      else{
        final ConceptNodeTree childNodeTree = domainTree!.conceptNodeTree[childIndex];
        final String childDomainNodeKey = ConceptTreeModel.GenerateDomainNodeKey(curDomainKey, childNodeTree.name, childNodeTree.alias);
        final NodeDrawingData? drawingData = nodeDrawingDataDic.GetNodeDrawingData(childDomainNodeKey);
        if(drawingData == null) throw Exception("无法找到子概念节点的绘制数据");

        childNodeDrawingData = drawingData;

        return drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;

      }
    }
    else{
      final ConceptNodeTree childNodeTree = nodeTree!.children[childIndex];
      final String childDomainNodeKey = ConceptTreeModel.GenerateDomainNodeKey(curDomainKey, childNodeTree.name, childNodeTree.alias);
      final NodeDrawingData? drawingData = nodeDrawingDataDic.GetNodeDrawingData(childDomainNodeKey);
      if(drawingData == null) throw Exception("无法找到子概念节点的绘制数据");

      childNodeDrawingData = drawingData;

      return drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
    }

  }

  Offset GetNodePositionByIndex(bool isDomain,int childIndex){

    Size nodeSize = _GetNodeSizeByIndex(isDomain, childIndex);
    this.nodeSize = nodeSize;

    if(isInDomain){
    //如果选的是域，获取子域的信息。
      if(isDomain){
        //需要额外考虑父节点绘制物中的排列规则。
        //把位置绘制在选中的节点上。
        return Offset(
          nodeSize.width * domainDrawingData!.childrenDomainPos[childIndex].x  + domainOffset.dx ,
          nodeSize.height * domainDrawingData!.childrenDomainPos[childIndex].y  + domainOffset.dy ,
        );
      }
      else{

        //把位置绘制在选中的节点上。
        return Offset(
          nodeSize.width * domainDrawingData!.childrenNodePos[childIndex].x  + conceptOffset.dx ,
          nodeSize.height * domainDrawingData!.childrenNodePos[childIndex].y  + conceptOffset.dy ,
        );
      }
    }
    else{

      //把位置绘制在选中的节点上。
      return Offset(
        nodeSize.width * nodeDrawingData!.childrenNodePos[childIndex].x  + domainOffset.dx ,
        nodeSize.height * nodeDrawingData!.childrenNodePos[childIndex].y  + domainOffset.dy ,
      );
    }
    return Offset.zero;
  }
  Offset? GetNodePositionByInstance(ConceptNodeTree? childNodeTree,DomainTree? childDomainTree ){
    if(isInDomain){
      if(childDomainTree != null){

        int? index = domainTree!.FindDomainIndex(childDomainTree);
        if(index == null) {
          throw Exception("无法根据子域节点在域树中找到对应树");
        }

        return GetNodePositionByIndex(true,index);

      }
      else if(childNodeTree != null){
        int? index = domainTree!.FindConceptIndex(childNodeTree);
        if(index == null) {
          throw Exception("无法根据子概念节点在域树中找到对应树");
        }

        return GetNodePositionByIndex(false,index);
      }
    }
    else{
      if(childNodeTree != null){

        int? index = nodeTree!.FindIndex(childNodeTree);
        if(index == null) {
          throw Exception("无法根据子概念节点在概念树中找到对应树");
        }

        return GetNodePositionByIndex(false,index);
      }
    }


    return null;
  }

  //附产物。必须执行过获取位置函数后才能读取。
  Size? nodeSize;
  NodeDrawingData? childNodeDrawingData;
  DomainDrawingData? childDomainDrawingData;
  Size? levelSize;
  Size? levelSizeWithoutEmpty;




   static Offset GetNodePositionStatic(ConceptTreeModel treeModel
       ,ConceptTree2DomainDrawingDataDic domainDrawingDataDic
       ,ConceptTree2NodeDrawingDataDic nodeDrawingDataDic
       ,ConceptTree2NodeViewDataDic viewDrawingDataDic
       ,bool isInDomain
       ,String curDomainKey
       ,String curDomainNodeKey
       ,bool isDomain
       ,String name
       ,String alias
       ,int childIndex
       ){
      //从宇宙大爆炸之初获取单个节点的位置。
     //后面支持创建实例获取多个节点。

     //1.通过当前节点key获取绘制物。
     //2.通过当前节点key获取子节点信息。

     //String curDomainKey = curDomainKey;
     //String curDomainNodeKey = curDomainNodeKey;

     String childDomainKey = ConceptTreeModel.AppendDomainKey(curDomainKey, name);
     String childDomainNodeKey = ConceptTreeModel.GenerateDomainNodeKey(curDomainKey, name, alias);

     Offset domainOffset = Offset.zero;
     Offset conceptOffset = Offset.zero;

     NodeViewData? nodeViewData = viewDrawingDataDic.GetNodeViewData(curDomainNodeKey);
     if(nodeViewData == null){
       throw Exception("无法找到视口数据");
     }


     if(isInDomain){
       DomainDrawingData? domainDrawingData = domainDrawingDataDic.GetDomainDrawingData(curDomainKey);
       if(domainDrawingData == null){
         throw Exception("无法获取当前域的渲染物");
       }
       DomainTree? domainTree = treeModel.GetDomainTree(curDomainKey);
       if(domainTree == null){
         throw Exception("无法获取当前域的树");
       }
        //计算偏移量。域的大小。
       double domainWidth = 0;
       if(domainTree.children.isNotEmpty){
         final String domainNameKey = ConceptTreeModel.AppendDomainKey(curDomainKey, domainTree.children[0].name);
         final NodeDrawingData? drawingData = domainDrawingDataDic.GetDomainDrawingData(domainNameKey);
         if(drawingData == null) throw Exception("exception，找不到第一个子域的渲染数据");
         Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
         int usefulCount = domainTree.children.length > domainDrawingData.domainMaxX ? domainDrawingData.domainMaxX:domainTree.children.length;

         domainWidth = usefulCount * nodeSize.width;
       }

       //计算concept所占宽度。
       double conceptWidth = 0;
       if(domainTree.conceptNodeTree.isNotEmpty){
         final String domainNameKey = ConceptTreeModel.GenerateDomainNodeKey(curDomainKey, domainTree.conceptNodeTree[0].name, domainTree.conceptNodeTree[0].alias);
         final NodeDrawingData? drawingData = nodeDrawingDataDic.GetNodeDrawingData(domainNameKey);
         if(drawingData == null) throw Exception("exception,根据子树找不到绘制子节点的渲染物体,键:${domainNameKey}");

         Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
         int usefulCount = domainTree.conceptNodeTree.length > domainDrawingData.maxX ? domainDrawingData.maxX:domainTree.conceptNodeTree.length;

         conceptWidth = usefulCount * nodeSize.width;
       }

       //计算offset偏移。
       double maxWidth = domainWidth > conceptWidth?domainWidth: conceptWidth;
       Offset allOffset = Offset( maxWidth *1.1,0);//加上基础偏移值。
       double t = domainWidth/(domainWidth+conceptWidth);
       domainOffset = - allOffset * t;
       conceptOffset = allOffset * (1-t);

       //如果选的是域，获取子域的信息。
       if(isDomain){
         final DomainDrawingData? drawingData = domainDrawingDataDic.GetDomainDrawingData(childDomainKey);
         if(drawingData == null) throw Exception("无法找到子域节点的绘制数据");

         Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
         //把位置绘制在选中的节点上。
         return Offset(
             nodeSize.width * domainDrawingData.childrenDomainPos[childIndex].x + nodeViewData.viewPosX + domainOffset.dx ,
             nodeSize.height * domainDrawingData.childrenDomainPos[childIndex].y + nodeViewData.viewPosY + domainOffset.dy ,
         );
       }
       else{
         final NodeDrawingData? drawingData = nodeDrawingDataDic.GetNodeDrawingData(childDomainNodeKey);
         if(drawingData == null) throw Exception("无法找到子概念节点的绘制数据");

         Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
         //把位置绘制在选中的节点上。
         return Offset(
           nodeSize.width * domainDrawingData.childrenNodePos[childIndex].x + nodeViewData.viewPosX + conceptOffset.dx ,
           nodeSize.height * domainDrawingData.childrenNodePos[childIndex].y + nodeViewData.viewPosY + conceptOffset.dy ,
         );
       }
     }
     else{

       NodeDrawingData? nodeDrawingData = nodeDrawingDataDic.GetNodeDrawingData(curDomainNodeKey);
       if(nodeDrawingData == null){
         throw Exception("无法获取当前概念的渲染物");
       }
       // ConceptNodeTree? nodeTree = treeModel.GetConceptNodeByDic(curDomainNodeKey);
       // if(nodeTree == null){
       //   throw Exception("无法获取当前概念的树");
       // }

       final NodeDrawingData? drawingData = nodeDrawingDataDic.GetNodeDrawingData(childDomainNodeKey);
       if(drawingData == null) throw Exception("无法找到子概念节点的绘制数据");

       Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
       //把位置绘制在选中的节点上。
       return Offset(
         nodeSize.width * nodeDrawingData.childrenNodePos[childIndex].x + nodeViewData.viewPosX + domainOffset.dx ,
         nodeSize.height * nodeDrawingData.childrenNodePos[childIndex].y + nodeViewData.viewPosY + domainOffset.dy ,
       );

     }

     return Offset.zero;
   }
}

class FocusNodeHelper{
  FocusNodeHelper(BuildContext context,bool parentIsInDomain,String curDomainKey,String curDomainNodeKey,this.allSize):
    _posHelper = NodePositionHelper.byContext(context),
    nodeViewDic = context.read<ConceptTree2NodeViewDataDic>()
  {
    _posHelper.InitData(parentIsInDomain, curDomainKey, curDomainNodeKey);

    nodeViewData = nodeViewDic.GetNodeViewData(curDomainNodeKey);
    if(nodeViewData == null){
      throw Exception("LevelNode找不到NodeViewData");
    }

  }
  FocusNodeHelper.lateInit(BuildContext context):
        _posHelper = NodePositionHelper.byContext(context),
        nodeViewDic = context.read<ConceptTree2NodeViewDataDic>()
  {

  }
  void Init(bool parentIsInDomain,String curDomainKey,String curDomainNodeKey,Size allSize){
    nodeViewData = nodeViewDic.GetNodeViewData(curDomainNodeKey);
    if(nodeViewData == null){
      throw Exception("LevelNode找不到NodeViewData");
    }
    this.allSize = allSize;
    _posHelper.InitData(parentIsInDomain, curDomainKey, curDomainNodeKey);
  }
  final NodePositionHelper _posHelper;
  late NodeViewData? nodeViewData;
  final ConceptTree2NodeViewDataDic nodeViewDic;
  late Size allSize;
  late VoidCallback moveView;

  void FocusNode(ConceptNodeTree? childConceptTree,DomainTree? childDomainTree ){
    //获取当前位置。
    Offset? pos = _posHelper.GetNodePositionByInstance(childConceptTree, childDomainTree);
    AnimationController controller = GlobalCoroutine().GetController();
    double originPosX = nodeViewData!.viewPosX;
    double targetPosX = -pos!.dx - allSize.width * 0.5;
    double originPosY = nodeViewData!.viewPosY;
    double targetPosY = -pos!.dy - allSize.height * 0.5;
    controller.duration = Duration(milliseconds: 300);
    
    moveView = (){
      double t = controller.value;

      //print("tick${t}");

      nodeViewData!.viewPosX = Tween(begin: originPosX, end: targetPosX)
          .chain(CurveTween(curve: Curves.easeOut))
          .animate(controller).value;
      //print("posX${nodeViewData.viewPosX},origin${originPosX},target${targetPosX}");
      nodeViewData!.viewPosY = Tween(begin: originPosY,end: targetPosY)
          .chain(CurveTween(curve: Curves.easeOut))
          .animate(controller).value;
      nodeViewDic.repaint();

      if(controller.isCompleted){
        print("controllerCompleted${controller.value}");
        controller.removeListener(moveView);
      }
    };
    controller.addListener(moveView);

    controller.forward(from: 0);
  }

}

