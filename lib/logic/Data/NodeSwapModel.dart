
//记录一些交换时用到的数据（不需要重新绘制UI）、以及这些数据用到的处理逻辑供LevelNode和NodeMoveComponent调用。
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:flutter/material.dart';


class NodeSwapModel{

  int allLength = 1;
  int originIndex = 0;
  int curIndex = 0;

  late ConceptTreeModel treeModel;
  DomainTree? domainTree;
  ConceptNodeTree? nodeTree;
  DomainDrawingData? domainDrawingData;
  NodeDrawingData? nodeDrawingData;

  void updateTree(BuildContext context,SelectionViewData selection,ConceptTreeModel treeModel,ConceptTree2DomainDrawingDataDic domainDrawingDataDic,ConceptTree2NodeDrawingDataDic nodeDrawingDataDic){
    this.treeModel = treeModel;
    if(selection.IsInDomain){
      domainTree = treeModel.GetDomainTree(selection.currentDomain);
      if(domainTree == null){
        throw Exception("nodeMoveComponent找不到当前的domainTree");
      }
      domainDrawingData = domainDrawingDataDic.GetDomainDrawingData(selection.currentDomain);
      if(domainDrawingData == null){
        throw Exception("nodeMoveComponent找不到当前的domainDrawingData");
      }
    }
    else{
      nodeTree = treeModel.GetConceptNodeByDic(selection.CurrentDomainNodeKey);
      if(nodeTree == null){
        throw Exception("nodeMoveComponent找不到当前的nodeTree");
      }
      nodeDrawingData = nodeDrawingDataDic.GetNodeDrawingData(selection.CurrentDomainNodeKey);
      if(nodeDrawingData == null){
        throw Exception("nodeMoveComponent找不到当前的nodeDrawingData");
      }
    }
  }

  void initMoveData(SelectionViewData selection){
    //commandManager.init();
    if(selection.IsInDomain){
      if(selection.IsSelectedDomain){
        //在树中找到当前的序号。因为绘制的Index是跟着treeModel来的。
        int? curIndex = domainTree!.FindDomainIndex(selection.SelectedDomain!);
        if(curIndex == null){
          throw Exception("nodeMoveComponent,无法从父树中找到子树序号");
        }
        print("初始化移动数据${curIndex}");
        originIndex = curIndex;
        this.curIndex = curIndex;
        allLength = domainTree!.children.length;
      }
      else if(selection.IsSelectedConceptNode){
        //在树中找到当前的序号。因为绘制的Index是跟着treeModel来的。
        int? curIndex = domainTree!.FindConceptIndex(selection.SelectedConceptNode!);
        if(curIndex == null){
          throw Exception("nodeMoveComponent,无法从父树中找到子树序号");
        }
        print("初始化移动数据${curIndex}");
        originIndex = curIndex;
        this.curIndex = curIndex;
        allLength = domainTree!.conceptNodeTree.length;
      }
    }
    else{
      //在树中找到当前的序号。因为绘制的Index是跟着treeModel来的。
      int? curIndex = nodeTree!.FindIndex(selection.SelectedConceptNode!);
      if(curIndex == null){
        throw Exception("nodeMoveComponent,无法从父树中找到子树序号");
      }
      print("初始化移动数据${curIndex}");
      originIndex = curIndex;
      this.curIndex = curIndex;
      allLength = nodeTree!.children.length;
    }
  }
  void reCalculateCurIndex(SelectionViewData selection){
    if(selection.IsInDomain){
      if(selection.IsSelectedDomain){
        //在树中找到当前的序号。因为绘制的Index是跟着treeModel来的。
        int? curIndex = domainTree!.FindDomainIndex(selection.SelectedDomain!);
        if(curIndex == null){
          throw Exception("nodeMoveComponent,无法从父树中找到子树序号");
        }
        this.curIndex = curIndex;
      }
      else if(selection.IsSelectedConceptNode){
        //在树中找到当前的序号。因为绘制的Index是跟着treeModel来的。
        int? curIndex = domainTree!.FindConceptIndex(selection.SelectedConceptNode!);
        if(curIndex == null){
          throw Exception("nodeMoveComponent,无法从父树中找到子树序号");
        }
        this.curIndex = curIndex;
      }
    }
    else{
      //在树中找到当前的序号。因为绘制的Index是跟着treeModel来的。
      int? curIndex = nodeTree!.FindIndex(selection.SelectedConceptNode!);
      if(curIndex == null){
        throw Exception("nodeMoveComponent,无法从父树中找到子树序号");
      }
      this.curIndex = curIndex;
    }
    void nodeSwap(int index1,int index2,bool isInDomain,bool isDomain){
      if(index1 == index2)return;
      if(isInDomain){
        if(isDomain){
          // var tmp = domainDrawingData!.childrenDomainPos[index1];
          // domainDrawingData!.childrenDomainPos[index1] =
          // domainDrawingData!.childrenDomainPos[index2];
          // domainDrawingData!.childrenDomainPos[index2] = tmp;
          var tmp2 = domainTree!.children[index1];
          domainTree!.children[index1] = domainTree!.children[index2];
          domainTree!.children[index2] = tmp2;
        }
        else{
          // var tmp = domainDrawingData!.childrenNodePos[index1];
          // domainDrawingData!.childrenNodePos[index1] =
          // domainDrawingData!.childrenNodePos[index2];
          // domainDrawingData!.childrenNodePos[index2] = tmp;
          var tmp2 = domainTree!.conceptNodeTree[index1];
          domainTree!.conceptNodeTree[index1] = domainTree!.conceptNodeTree[index2];
          domainTree!.conceptNodeTree[index2] = tmp2;
        }
      }
      else {
        // var tmp = nodeDrawingData!.childrenNodePos[index1];
        // nodeDrawingData!.childrenNodePos[index1] =
        // nodeDrawingData!.childrenNodePos[index2];
        // nodeDrawingData!.childrenNodePos[index2] = tmp;
        var tmp2 = nodeTree!.children[index1];
        nodeTree!.children[index1] = nodeTree!.children[index2];
        nodeTree!.children[index2] = tmp2;
      }
    }
  }
  int? getNodeIndex(SelectionViewData selection,{required ConceptNodeTree? childConceptTree,required DomainTree? childDomainTree}){

    if(selection.IsInDomain){
      if(childDomainTree != null){
        //在树中找到当前的序号。因为绘制的Index是跟着treeModel来的。
        int? curIndex = domainTree!.FindDomainIndex(childDomainTree);
        if(curIndex == null){
          throw Exception("nodeMoveComponent,无法从父树中找到子树序号");
        }
        return curIndex;
      }
      else if(childConceptTree != null){
        //在树中找到当前的序号。因为绘制的Index是跟着treeModel来的。
        int? curIndex = domainTree!.FindConceptIndex(childConceptTree);
        if(curIndex == null){
          throw Exception("nodeMoveComponent,无法从父树中找到子树序号");
        }
        return curIndex;
      }
    }
    else{
      //在树中找到当前的序号。因为绘制的Index是跟着treeModel来的。
      if(childConceptTree != null){
        int? curIndex = nodeTree!.FindIndex(childConceptTree);
        if(curIndex == null){
          throw Exception("nodeMoveComponent,无法从父树中找到子树序号");
        }
        return curIndex;
      }
    }
    return null;
  }
  void nodeSwap(int index1,int index2,bool isInDomain,bool isDomain){
    if(index1 == index2)return;
    if(isInDomain){
      if(isDomain){
        // var tmp = domainDrawingData!.childrenDomainPos[index1];
        // domainDrawingData!.childrenDomainPos[index1] =
        // domainDrawingData!.childrenDomainPos[index2];
        // domainDrawingData!.childrenDomainPos[index2] = tmp;
        var tmp2 = domainTree!.children[index1];
        domainTree!.children[index1] = domainTree!.children[index2];
        domainTree!.children[index2] = tmp2;
      }
      else{
        // var tmp = domainDrawingData!.childrenNodePos[index1];
        // domainDrawingData!.childrenNodePos[index1] =
        // domainDrawingData!.childrenNodePos[index2];
        // domainDrawingData!.childrenNodePos[index2] = tmp;
        var tmp2 = domainTree!.conceptNodeTree[index1];
        domainTree!.conceptNodeTree[index1] = domainTree!.conceptNodeTree[index2];
        domainTree!.conceptNodeTree[index2] = tmp2;
      }
    }
    else {
      // var tmp = nodeDrawingData!.childrenNodePos[index1];
      // nodeDrawingData!.childrenNodePos[index1] =
      // nodeDrawingData!.childrenNodePos[index2];
      // nodeDrawingData!.childrenNodePos[index2] = tmp;
      var tmp2 = nodeTree!.children[index1];
      nodeTree!.children[index1] = nodeTree!.children[index2];
      nodeTree!.children[index2] = tmp2;
    }
  }
  void rebuildNodeTreeDic(){
    treeModel.GenerateDic();
  }
}