import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:flutter/material.dart';

//选择绘制的组。
class SelectionViewData extends ChangeNotifier {
  String currentDomain = "root";
  String currentConceptNodeName = "";
  String currentConceptNodeAlias = "";
  DomainTree? _selectedDomain;
  DomainTree? get SelectedDomain => _selectedDomain;
  ConceptNodeTree? _selectedConceptNode;
  ConceptNodeTree? get SelectedConceptNode =>_selectedConceptNode;

  String get CurrentDomainNodeKey => IsInDomain? currentDomain : ConceptTreeModel.GenerateDomainNodeKey(currentDomain, currentConceptNodeName, currentConceptNodeAlias);
  bool get IsInDomain => currentConceptNodeName == "";

  bool get IsSelecting => _selectedDomain != null || _selectedConceptNode != null;
  bool get IsSelectedDomain => _selectedDomain!=null;
  bool get IsSelectedConceptNode => _selectedConceptNode != null;

  set SelectedDomain(DomainTree? value){
    if(_selectedDomain != value){
      _selectedDomain = value;
      notifyListeners();
    }
    if(value != null)
      _selectedConceptNode = null;
  }
  set SelectedConceptNode(ConceptNodeTree? value){
    if(_selectedConceptNode != value){
      _selectedConceptNode = value;
      notifyListeners();
    }
    if(value != null)
      _selectedDomain = null;
  }

  void CancelSelection(){
    _selectedDomain = null;
    _selectedConceptNode = null;
    notifyListeners();
  }
}
//选择某个节点。