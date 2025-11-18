import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:flutter/material.dart';

//选择绘制的组。
class SelectionViewData extends ChangeNotifier {
  String currentDomain = "root";
  String currentConceptNodeName = "";
  String currentConceptNodeAlias = "";
  String? selectedDomain;
  ConceptNodeTree? selectedConceptNode;

  String get CurrentDomainNodeKey =>currentDomain + currentConceptNodeName + currentConceptNodeAlias;
}
//选择某个节点。