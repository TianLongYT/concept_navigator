import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:flutter/material.dart';

class NodeColorHelper{

  NodeColorHelper({
    required this.domainDrawingDataDic,
    required this.nodeDrawingDataDic,
  });
  NodeColorHelper.byDrawingData({
    required this.parentDomainDrawingData,
    required this.parentConceptDrawingData,
    required this.nodeAppearance,
    required this.isSelectedDomain,
});

  ConceptTree2DomainDrawingDataDic? domainDrawingDataDic;
  ConceptTree2NodeDrawingDataDic? nodeDrawingDataDic;
  DomainDrawingData? parentDomainDrawingData;
  NodeDrawingData? parentConceptDrawingData;
  DomainDrawingData? domainDrawingData;
  NodeDrawingData? nodeDrawingData;
  NodeAppearance? nodeAppearance;

  bool isInDomain = false;
  String curDomainNodeKey = "";
  bool isSelectedDomain = false;
  String selectedDomainNodeKey = "";

  void InitData(bool isInDomain,String curDomainNodeKey,bool isSelectedDomain,String selectedDomainNodeKey){
    if(isInDomain == false && isSelectedDomain){
      throw Exception("在一个概念中不能存在域");
    }
    this.isInDomain = isInDomain;
    this.curDomainNodeKey = curDomainNodeKey;
    this.isSelectedDomain = isSelectedDomain;
    this.selectedDomainNodeKey = selectedDomainNodeKey;

    if(isInDomain){
      parentDomainDrawingData = domainDrawingDataDic?.GetDomainDrawingData(curDomainNodeKey);
      if(parentDomainDrawingData == null){
        throw Exception("GetNodeColor无法找到parentDomainDrawingData");
      }
    }
    else{
      parentConceptDrawingData = nodeDrawingDataDic?.GetNodeDrawingData(curDomainNodeKey);
      if(parentConceptDrawingData == null){
        throw Exception("GetNodeColor无法找到parentNodeDrawingData");
      }
    }
    if(isSelectedDomain){
      domainDrawingData = domainDrawingDataDic?.GetDomainDrawingData(selectedDomainNodeKey);
      if(domainDrawingData == null){
        throw Exception("GetNodeColor无法找到domainDrawingData");
      }
      nodeAppearance = domainDrawingData!.nodeAppearance;
    }
    else{
      nodeDrawingData = nodeDrawingDataDic?.GetNodeDrawingData(selectedDomainNodeKey);
      if(nodeDrawingData == null){
        throw Exception("GetNodeColor无法找到nodeDrawingData");
      }
      nodeAppearance = nodeDrawingData!.nodeAppearance;

    }

  }

  Color getNodeColor(BuildContext context){
    NodeAppearance nodeAppearance = this.nodeAppearance?? ( isSelectedDomain?domainDrawingData!.nodeAppearance:nodeDrawingData!.nodeAppearance);
    // 1. 自身颜色最高
    if (nodeAppearance.nodeColor != null) return nodeAppearance.nodeColor!;

    // 2. 父节点指定的颜色（子节点颜色）
    Color? parentProvidedColor;
    if(parentDomainDrawingData !=null){
      parentProvidedColor = isSelectedDomain ? parentDomainDrawingData!.defaultDomainNodeColor:parentDomainDrawingData!.defaultConceptNodeColor;
    }
    else if(parentConceptDrawingData != null){
      parentProvidedColor = parentConceptDrawingData!.defaultConceptNodeColor;
    }
    else{
      throw Exception("GetNodeColor父渲染物都为null，获取颜色前请尝试InitData");
    }
    if (parentProvidedColor != null) return parentProvidedColor;

    // 3. 主题初始颜色最低 ,用户几乎没法修改这个颜色。
    final extensions = Theme.of(context).extension<NodeColorsExtension>();
    return isSelectedDomain
        ? (extensions?.defaultDomainNodeColor ?? Theme.of(context).colorScheme.error)
        : (extensions?.defaultConceptNodeColor ?? Theme.of(context).colorScheme.error);
  }
  Color getFontColor(BuildContext context){
    NodeAppearance nodeAppearance = this.nodeAppearance??( isSelectedDomain?domainDrawingData!.nodeAppearance:nodeDrawingData!.nodeAppearance);
    // 1. 自身颜色最高
    if (nodeAppearance.fontColor != null) return nodeAppearance.fontColor!;

    // 2. 父节点指定的颜色（子节点颜色）
    Color? parentProvidedColor;
    if(parentDomainDrawingData !=null){
      parentProvidedColor = isSelectedDomain ? parentDomainDrawingData!.defaultDomainFontColor:parentDomainDrawingData!.defaultConceptFontColor;
    }
    else if(parentConceptDrawingData != null){
      parentProvidedColor = parentConceptDrawingData!.defaultConceptFontColor;
    }
    else{
      throw Exception("GetFontColor父渲染物都为null，获取颜色前请尝试InitData");
    }
    if (parentProvidedColor != null) return parentProvidedColor;

    // 3. 主题初始颜色最低 ,用户几乎没法修改这个颜色。
    final extensions = Theme.of(context).extension<NodeColorsExtension>();
    return isSelectedDomain
        ? (extensions?.defaultDomainFontColor ?? Theme.of(context).colorScheme.error)
        : (extensions?.defaultConceptFontColor ?? Theme.of(context).colorScheme.error);
  }

  static Color GetDefaultNodeColor(bool isDomain,Color? defaultColor,BuildContext context){
    final extensions = Theme.of(context).extension<NodeColorsExtension>();
    return defaultColor?? (isDomain
        ? (extensions?.defaultDomainNodeColor ?? Theme.of(context).colorScheme.error)
        : (extensions?.defaultConceptNodeColor ?? Theme.of(context).colorScheme.error));
  }
  static Color GetDefaultFontColor(bool isDomain,Color? defaultColor,BuildContext context){
    final extensions = Theme.of(context).extension<NodeColorsExtension>();
    return defaultColor?? (isDomain
        ? (extensions?.defaultDomainFontColor ?? Theme.of(context).colorScheme.error)
        : (extensions?.defaultConceptFontColor ?? Theme.of(context).colorScheme.error));
  }

  static Color FromDic({
    required ConceptTree2DomainDrawingDataDic domainDrawingDataDic,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDataDic,
    required bool isInDomain,
    required String curDomainNodeKey,
    required bool isSelectedDomain,
    required String selectedDomainNodeKey
  }){

    if(isInDomain){

    }
    return Colors.blue;
  }
}