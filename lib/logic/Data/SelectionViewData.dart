import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodeInfo/GetNodePosition.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//选择绘制的组。
class SelectionViewData extends ChangeNotifier {
  String currentDomain = "root";
  String currentConceptNodeName = "";
  String currentConceptNodeAlias = "";
  //DomainTree? _selectedDomain;
  //ConceptNodeTree? _selectedConceptNode;
  final _state = ValueNotifier<SelectionState>(SelectionState.none());

  ValueListenable<SelectionState> get state => _state;
  DomainTree? get SelectedDomain => _state.value.selectedDomain;
  ConceptNodeTree? get SelectedConceptNode =>_state.value.selectedConcept;

  DomainTree? _tmpSelectedDomain;
  DomainTree? get TmpSelectedDomain => _tmpSelectedDomain;
  set TmpSelectedDomain(DomainTree? value){
    if(_tmpSelectedDomain != value){
      _tmpSelectedDomain = value;
      notifyListeners();
    }
    if(value != null)
      _tmpSelectedConcept = null;
  }
  ConceptNodeTree? _tmpSelectedConcept;
  ConceptNodeTree? get TmpSelectedConceptNode =>_tmpSelectedConcept;
  set TmpSelectedConceptNode(ConceptNodeTree? value){
    if(_tmpSelectedConcept != value){
      _tmpSelectedConcept = value;
      notifyListeners();
    }
    if(value != null)
      _tmpSelectedDomain = null;
  }


  String get CurrentDomainNodeKey => IsInDomain? currentDomain : ConceptTreeModel.GenerateDomainNodeKey(currentDomain, currentConceptNodeName, currentConceptNodeAlias);
  bool get IsInDomain => currentConceptNodeName == "";

  bool get IsSelecting => _state.value.selectedDomain != null || _state.value.selectedConcept != null;
  bool get IsSelectedDomain => _state.value.selectedDomain!=null;
  bool get IsSelectedConceptNode => _state.value.selectedConcept != null;

  set SelectedDomain(DomainTree? value){
    if(_state.value.selectedDomain != value){
      SelectionState newState;
      if(value != null){
        newState = SelectionState.domain(value);
      }
      else{
        newState = _state.value.clearDomain();
      }
      if (newState != _state.value) {
        _state.value = newState; // 触发监听器，并传递新状态
      }
      notifyListeners();
    }
  }
  set SelectedConceptNode(ConceptNodeTree? value){
    if(_state.value.selectedConcept != value){
      SelectionState newState;
      if(value != null){
        newState = SelectionState.conceptNode(value);
      }
      else{
        newState = _state.value.clearConcept();
      }
      if (newState != _state.value) {
        _state.value = newState; // 触发监听器，并传递新状态
      }
      notifyListeners();
    }
  }

  void CancelSelection(){
    SelectionState newState = SelectionState.none();
    if (newState != _state.value) {
      _state.value = newState; // 触发监听器，并传递新状态
    }
    notifyListeners();
  }
  void _JumpToNode(NodeTree parent,AddressBarModel addressBar,ConceptTreeModel treeModel){
    if (parent is DomainTree) {
      currentDomain = parent.GetDomainKey();
      currentConceptNodeName = "";
      currentConceptNodeAlias = "";
    } else if (parent is ConceptNodeTree) {
      currentDomain = parent.domainKey;
      currentConceptNodeName = parent.name;
      currentConceptNodeAlias = parent.alias;
    }
    addressBar.updateAddressBar(parent, treeModel);
  }
  void _SelectNode(NodeTree selectedNode,GlobalStateModel globalState){
    if (selectedNode is DomainTree) {
      SelectedDomain = selectedNode;
      globalState.State = GlobalState.editingDomain;
    } else if (selectedNode is ConceptNodeTree) {
      SelectedConceptNode = selectedNode;
      globalState.State = GlobalState.editingConcept;
    }
  }
  void _CancleSelection(GlobalStateModel globalState){
    CancelSelection();
    globalState.State = GlobalState.normal;
  }
  void _FocusNode(NodeTree selectedNode,ConceptTreeModel treeModel,ConceptTree2NodeDrawingDataDic nodeDrawingDataDic,ConceptTree2DomainDrawingDataDic domainDrawingDataDic,ConceptTree2NodeViewDataDic viewDrawingDataDic,){
    final nodeHelper = FocusNodeHelper.noContext(IsInDomain,currentDomain,CurrentDomainNodeKey, treeModel: treeModel, domainDrawingDataDic: domainDrawingDataDic, nodeDrawingDataDic: nodeDrawingDataDic, viewDrawingDataDic: viewDrawingDataDic);
    if (selectedNode is DomainTree) {
      nodeHelper.FocusNode(null, selectedNode);
    } else if (selectedNode is ConceptNodeTree) {
      nodeHelper.FocusNode(selectedNode, null);
    }
  }
  void SelectAndFocusNode({
    required NodeTree selectedNode,
    required NodeTree parent,
    required GlobalStateModel globalState,
    required AddressBarModel addressBar,
    required ConceptTreeModel treeModel,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDataDic,
    required ConceptTree2DomainDrawingDataDic domainDrawingDataDic,
    required ConceptTree2NodeViewDataDic viewDrawingDataDic,
  }){
    _JumpToNode(parent,addressBar,treeModel);
    _SelectNode(selectedNode,globalState);
    _FocusNode(selectedNode,treeModel,nodeDrawingDataDic,domainDrawingDataDic,viewDrawingDataDic);
  }

  void CancelSelectionAndJumpOutParent({
    required NodeTree selectedNode,
    required NodeTree parent,
    required GlobalStateModel globalState,
    required AddressBarModel addressBar,
    required ConceptTreeModel treeModel,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDataDic,
    required ConceptTree2DomainDrawingDataDic domainDrawingDataDic,
    required ConceptTree2NodeViewDataDic viewDrawingDataDic,
  }){
    _JumpToNode(parent,addressBar,treeModel);
    _CancleSelection(globalState);
    //_FocusNode(selectedNode,treeModel,nodeDrawingDataDic,domainDrawingDataDic,viewDrawingDataDic);
  }


}

class SelectionState {
  final DomainTree? _selectedDomain;
  final ConceptNodeTree? _selectedConceptNode;

  const SelectionState._(this._selectedDomain, this._selectedConceptNode)
      : assert(_selectedDomain == null || _selectedConceptNode == null,
  'Cannot select both domain and concept node');

  factory SelectionState.domain(DomainTree domain) =>
      SelectionState._(domain, null);

  factory SelectionState.conceptNode(ConceptNodeTree node) =>
      SelectionState._(null, node);

  factory SelectionState.none() => const SelectionState._(null, null);

  SelectionState copyWith({
    DomainTree? domain,
    ConceptNodeTree? concept,
  }) {
    final newDomain = domain ?? _selectedDomain;
    final newConcept = concept ?? _selectedConceptNode;
    if (newDomain != null && newConcept != null) {
      throw ArgumentError('Cannot set both domain and concept node');
    }
    return SelectionState._(newDomain, newConcept);
  }
  SelectionState clearDomain(){
    return SelectionState._(null, _selectedConceptNode);
  }
  SelectionState clearConcept(){
    return SelectionState._(_selectedDomain, null);
  }
  DomainTree? get selectedDomain =>_selectedDomain;
  ConceptNodeTree? get selectedConcept =>_selectedConceptNode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SelectionState &&
              runtimeType == other.runtimeType &&
              _selectedDomain == other._selectedDomain &&
              _selectedConceptNode == other._selectedConceptNode;

  @override
  int get hashCode => _selectedDomain.hashCode ^ _selectedConceptNode.hashCode;
}