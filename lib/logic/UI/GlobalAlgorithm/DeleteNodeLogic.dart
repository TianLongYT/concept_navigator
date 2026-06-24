import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ClipboardModel.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart'; // 引入以使用 NodeAppearance
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeleteNodeLogic {
  static void deleteSelectedNode(BuildContext context) {
    final selection = context.read<SelectionViewData>();
    if (!selection.IsSelecting) return;

    final treeModel = context.read<ConceptTreeModel>();
    final nodeDrawingDataDic = context.read<ConceptTree2NodeDrawingDataDic>();
    final domainDrawingDataDic = context.read<ConceptTree2DomainDrawingDataDic>();
    final nodeViewDataDic = context.read<ConceptTree2NodeViewDataDic>();
    final globalState = context.read<GlobalStateModel>();
    final addressBar = context.read<AddressBarModel>();
    final commandManager = context.read<CommandManagerForProvider>();

    NodeTree nodeToDelete = selection.IsSelectedDomain ? selection.SelectedDomain! : selection.SelectedConceptNode!;
    // 从 selection 获取当前视图的容器节点作为父节点
    NodeTree parentNode = selection.IsInDomain ? selection.currentDomainTree! : selection.currentConceptTree!;

    Command deleteCmd = getDeleteNodeCommand(
      nodeToDelete: nodeToDelete,
      parentNode: parentNode,
      treeModel: treeModel,
      nodeDrawingDataDic: nodeDrawingDataDic,
      domainDrawingDataDic: domainDrawingDataDic,
      nodeViewDataDic: nodeViewDataDic,
      selection: selection,
      globalState: globalState,
      addressBar: addressBar,
    );

    deleteCmd.function();
    commandManager.PushCommand(commandManager.editInstance, deleteCmd);
  }

  /// 提取出的核心删除逻辑，供删除功能和剪切粘贴功能复用
  static Command getDeleteNodeCommand({
    required NodeTree nodeToDelete,
    required NodeTree parentNode,
    required ConceptTreeModel treeModel,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDataDic,
    required ConceptTree2DomainDrawingDataDic domainDrawingDataDic,
    required ConceptTree2NodeViewDataDic nodeViewDataDic,
    required SelectionViewData selection,
    required GlobalStateModel globalState,
    required AddressBarModel addressBar,
  }) {
    final String parentKey = parentNode is DomainTree 
        ? parentNode.GetDomainKey() 
        : (parentNode as ConceptNodeTree).GetDomainNodeKey();
    final bool isParentDomain = parentNode is DomainTree;

    if (nodeToDelete is DomainTree) {
      final domainToDelete = nodeToDelete;
      final int index = (parentNode as DomainTree).FindDomainIndex(domainToDelete)!;
      final parentDrawingData = domainDrawingDataDic.GetDomainDrawingData(parentKey)!;
      final pos = parentDrawingData.childrenDomainPos[index];

      void doDelete() {
        treeModel.RemoveDomainFromDomain(parentKey, domainToDelete);
        parentDrawingData.RemoveAtDomainDrawingDataSqueeze(index);
        _RemoveSubtreeFromDics(domainToDelete, treeModel, nodeDrawingDataDic, domainDrawingDataDic, nodeViewDataDic);
        if (selection.SelectedDomain == domainToDelete) {
          selection.CancelSelection();
          globalState.State = GlobalState.normal;
        }
      }

      final backup = _BackupSubtree(domainToDelete, treeModel, nodeDrawingDataDic, domainDrawingDataDic, nodeViewDataDic);

      void undoDelete() {
        treeModel.InsertDomainInDomain(parentKey, domainToDelete, index);
        parentDrawingData.InsertDomainDrawingDataSqueeze(index, pos);
        _RestoreSubtreeToDics(backup, nodeDrawingDataDic, domainDrawingDataDic, nodeViewDataDic);
      }

      return Command(function: doDelete, undoFunction: undoDelete);
    } else {
      final conceptToDelete = nodeToDelete as ConceptNodeTree;
      int index;
      NodeDrawingData parentDrawingData;
      if (isParentDomain) {
        index = (parentNode as DomainTree).FindConceptIndex(conceptToDelete)!;
        parentDrawingData = domainDrawingDataDic.GetDomainDrawingData(parentKey)!;
      } else {
        index = (parentNode as ConceptNodeTree).FindIndex(conceptToDelete)!;
        parentDrawingData = nodeDrawingDataDic.GetNodeDrawingData(parentKey)!;
      }
      final pos = parentDrawingData.childrenNodePos[index];

      void doDelete() {
        if (isParentDomain) {
          treeModel.RemoveConceptFromDomain(parentKey, conceptToDelete);
        } else {
          treeModel.RemoveConceptFromConcept(parentKey, conceptToDelete);
        }
        parentDrawingData.RemoveAtNodeDrawingDataSqueeze(index);
        _RemoveSubtreeFromDics(conceptToDelete, treeModel, nodeDrawingDataDic, domainDrawingDataDic, nodeViewDataDic);

        if (selection.SelectedConceptNode == conceptToDelete) {
          selection.CancelSelectionAndJumpOutParent(
            selectedNode: conceptToDelete,
            parent: parentNode,
            globalState: globalState,
            addressBar: addressBar,
            treeModel: treeModel,
            nodeDrawingDataDic: nodeDrawingDataDic,
            domainDrawingDataDic: domainDrawingDataDic,
            viewDrawingDataDic: nodeViewDataDic,
          );
        }
      }

      final backup = _BackupSubtree(conceptToDelete, treeModel, nodeDrawingDataDic, domainDrawingDataDic, nodeViewDataDic);

      void undoDelete() {
        if (isParentDomain) {
          treeModel.InsertConceptInDomain(parentKey, conceptToDelete, index);
        } else {
          treeModel.InsertConceptInConceptNode(parentKey, conceptToDelete, index);
        }
        parentDrawingData.InsertNodeDrawingDataSqueeze(index, pos);
        _RestoreSubtreeToDics(backup, nodeDrawingDataDic, domainDrawingDataDic, nodeViewDataDic);

        selection.SelectAndFocusNode(
          selectedNode: conceptToDelete,
          parent: parentNode,
          globalState: globalState,
          addressBar: addressBar,
          treeModel: treeModel,
          nodeDrawingDataDic: nodeDrawingDataDic,
          domainDrawingDataDic: domainDrawingDataDic,
          viewDrawingDataDic: nodeViewDataDic,
        );
      }

      return Command(function: doDelete, undoFunction: undoDelete);
    }
  }

  static void copySelectedNode(BuildContext context) {
    final selection = context.read<SelectionViewData>();
    if (!selection.IsSelecting) return;
    final clipboard = context.read<ClipboardModel>();
    NodeTree node = selection.IsSelectedDomain ? selection.SelectedDomain! : selection.SelectedConceptNode!;
    NodeTree parentNode = selection.IsInDomain ? selection.currentDomainTree! : selection.currentConceptTree!;
    clipboard.copy(node, parentNode);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已复制到剪切板")));
  }

  static void cutSelectedNode(BuildContext context) {
    final selection = context.read<SelectionViewData>();
    if (!selection.IsSelecting) return;
    final clipboard = context.read<ClipboardModel>();
    NodeTree node = selection.IsSelectedDomain ? selection.SelectedDomain! : selection.SelectedConceptNode!;
    NodeTree parentNode = selection.IsInDomain ? selection.currentDomainTree! : selection.currentConceptTree!;
    clipboard.cut(node, parentNode);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已剪切到剪切板")));
  }

  static void pasteNode(BuildContext context, {bool? forceCopy}) {
    final clipboard = context.read<ClipboardModel>();
    if (clipboard.data == null) return;

    final selection = context.read<SelectionViewData>();
    final treeModel = context.read<ConceptTreeModel>();
    final nodeDrawingDataDic = context.read<ConceptTree2NodeDrawingDataDic>();
    final domainDrawingDataDic = context.read<ConceptTree2DomainDrawingDataDic>();
    final nodeViewDataDic = context.read<ConceptTree2NodeViewDataDic>();
    final globalState = context.read<GlobalStateModel>();
    final addressBar = context.read<AddressBarModel>();
    final commandManager = context.read<CommandManagerForProvider>();

    final clipboardData = clipboard.data!;
    
    // 3. 不允许在概念内创建域
    if (!selection.IsInDomain && clipboardData.node is DomainTree) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("错误：不允许在概念内粘贴域")));
      return;
    }

    bool isCopy = forceCopy ?? !clipboardData.isCut;

    NodeTree nodeToInsert;
    Command? cutDeleteCmd;

    if (!isCopy) {
      nodeToInsert = clipboardData.node;
      cutDeleteCmd = getDeleteNodeCommand(
        nodeToDelete: nodeToInsert,
        parentNode: clipboardData.parentNode,
        treeModel: treeModel,
        nodeDrawingDataDic: nodeDrawingDataDic,
        domainDrawingDataDic: domainDrawingDataDic,
        nodeViewDataDic: nodeViewDataDic,
        selection: selection,
        globalState: globalState,
        addressBar: addressBar,
      );
    } else {
      nodeToInsert = clipboardData.node is ConceptNodeTree 
          ? ConceptNodeTree.fromJson(clipboardData.node.toJson())
          : DomainTree.fromJson(clipboardData.node.toJson());
    }

    final NodeTree targetParentNode = selection.IsInDomain ? selection.currentDomainTree! : selection.currentConceptTree!;
    final String targetParentKey = targetParentNode.GetDomainNodeKey();
    final bool isTargetDomain = selection.IsInDomain;

    void doPaste() {
      if (cutDeleteCmd != null) cutDeleteCmd.function();

      if (nodeToInsert is ConceptNodeTree) {
        if (isTargetDomain) {
          treeModel.AddNewConceptInDomain(targetParentKey, nodeToInsert);
          domainDrawingDataDic.GetDomainDrawingData(targetParentKey)?.AddNodeDrawingData();
        } else {
          treeModel.AddNewConceptInConceptNode(targetParentKey, nodeToInsert);
          nodeDrawingDataDic.GetNodeDrawingData(targetParentKey)?.AddNodeDrawingData();
        }
      } else if (nodeToInsert is DomainTree) {
        treeModel.AddNewDomainInDomain(targetParentKey, nodeToInsert);
        domainDrawingDataDic.GetDomainDrawingData(targetParentKey)?.AddDomainDrawingData();
      }

      _RecursiveRestoreDrawingData(nodeToInsert, treeModel, nodeDrawingDataDic, domainDrawingDataDic, nodeViewDataDic);
      
      selection.SelectAndFocusNode(
        selectedNode: nodeToInsert,
        parent: targetParentNode,
        globalState: globalState,
        addressBar: addressBar,
        treeModel: treeModel,
        nodeDrawingDataDic: nodeDrawingDataDic,
        domainDrawingDataDic: domainDrawingDataDic,
        viewDrawingDataDic: nodeViewDataDic,
      );
      if(!isCopy) clipboard.clear();
      globalState.State = GlobalState.normal;
    }

    void undoPaste() {
      if (nodeToInsert is ConceptNodeTree) {
        if (isTargetDomain) {
          treeModel.RemoveConceptFromDomain(targetParentKey, nodeToInsert);
          domainDrawingDataDic.GetDomainDrawingData(targetParentKey)?.RemoveAtNodeDrawingDataSqueeze(
            treeModel.GetDomainTree(targetParentKey)!.conceptNodeTree.length
          );
        } else {
          treeModel.RemoveConceptFromConcept(targetParentKey, nodeToInsert);
          nodeDrawingDataDic.GetNodeDrawingData(targetParentKey)?.RemoveAtNodeDrawingDataSqueeze(
            treeModel.GetConceptNodeByDic(targetParentKey)!.children.length
          );
        }
      } else if (nodeToInsert is DomainTree) {
        treeModel.RemoveDomainFromDomain(targetParentKey, nodeToInsert);
        domainDrawingDataDic.GetDomainDrawingData(targetParentKey)?.RemoveAtDomainDrawingDataSqueeze(
          treeModel.GetDomainTree(targetParentKey)!.children.length
        );
      }
      _RemoveSubtreeFromDics(nodeToInsert, treeModel, nodeDrawingDataDic, domainDrawingDataDic, nodeViewDataDic);

      if (cutDeleteCmd != null) cutDeleteCmd.undoFunction();

      selection.CancelSelectionAndJumpOutParent(
        selectedNode: nodeToInsert,
        parent: targetParentNode,
        globalState: globalState,
        addressBar: addressBar,
        treeModel: treeModel,
        nodeDrawingDataDic: nodeDrawingDataDic,
        domainDrawingDataDic: domainDrawingDataDic,
        viewDrawingDataDic: nodeViewDataDic,
      );
    }

    doPaste();
    commandManager.PushCommand(commandManager.editInstance, Command(function: doPaste, undoFunction: undoPaste));
  }

  static void _RecursiveRestoreDrawingData(NodeTree node, ConceptTreeModel treeModel, ConceptTree2NodeDrawingDataDic nDic, ConceptTree2DomainDrawingDataDic dDic, ConceptTree2NodeViewDataDic vDic) {
    final key = node.GetDomainNodeKey();
    if (node is ConceptNodeTree) {
      nDic.putIfAbsent(key, () => NodeDrawingData(nodeAppearance: NodeAppearance())..text = node.name);
      vDic.putIfAbsent(key, () => NodeViewData());
      for (var child in node.children) _RecursiveRestoreDrawingData(child, treeModel, nDic, dDic, vDic);
    } else if (node is DomainTree) {
      dDic.putIfAbsent(key, () => DomainDrawingData(nodeAppearance: NodeAppearance())..text = node.name);
      vDic.putIfAbsent(key, () => NodeViewData());
      for (var child in node.children) _RecursiveRestoreDrawingData(child, treeModel, nDic, dDic, vDic);
      for (var child in node.conceptNodeTree) _RecursiveRestoreDrawingData(child, treeModel, nDic, dDic, vDic);
    }
  }

  static Map<String, _NodeDataBackup> _BackupSubtree(NodeTree root, ConceptTreeModel treeModel, ConceptTree2NodeDrawingDataDic nDic, ConceptTree2DomainDrawingDataDic dDic, ConceptTree2NodeViewDataDic vDic) {
    Map<String, _NodeDataBackup> backup = {};
    _RecursiveBackup(root, treeModel, backup, nDic, dDic, vDic);
    return backup;
  }

  static void _RecursiveBackup(NodeTree node, ConceptTreeModel treeModel, Map<String, _NodeDataBackup> backup, ConceptTree2NodeDrawingDataDic nDic, ConceptTree2DomainDrawingDataDic dDic, ConceptTree2NodeViewDataDic vDic) {
    final key = node.GetDomainNodeKey();
    backup[key] = _NodeDataBackup(
      nodeDrawingData: nDic.GetNodeDrawingData(key),
      domainDrawingData: dDic.GetDomainDrawingData(key),
      nodeViewData: vDic.GetNodeViewData(key),
    );
    if (node is ConceptNodeTree) {
      for (var child in node.children) _RecursiveBackup(child, treeModel, backup, nDic, dDic, vDic);
    } else if (node is DomainTree) {
      for (var child in node.children) _RecursiveBackup(child, treeModel, backup, nDic, dDic, vDic);
      for (var child in node.conceptNodeTree) _RecursiveBackup(child, treeModel, backup, nDic, dDic, vDic);
    }
  }

  static void _RemoveSubtreeFromDics(NodeTree node, ConceptTreeModel treeModel, ConceptTree2NodeDrawingDataDic nDic, ConceptTree2DomainDrawingDataDic dDic, ConceptTree2NodeViewDataDic vDic) {
    final key = node.GetDomainNodeKey();
    nDic.remove(key);
    dDic.remove(key);
    vDic.remove(key);
    if (node is ConceptNodeTree) {
      for (var child in node.children) _RemoveSubtreeFromDics(child, treeModel, nDic, dDic, vDic);
    } else if (node is DomainTree) {
      for (var child in node.children) _RemoveSubtreeFromDics(child, treeModel, nDic, dDic, vDic);
      for (var child in node.conceptNodeTree) _RemoveSubtreeFromDics(child, treeModel, nDic, dDic, vDic);
    }
  }

  static void _RestoreSubtreeToDics(Map<String, _NodeDataBackup> backup, ConceptTree2NodeDrawingDataDic nDic, ConceptTree2DomainDrawingDataDic dDic, ConceptTree2NodeViewDataDic vDic) {
    backup.forEach((key, data) {
      if (data.nodeDrawingData != null) nDic.putIfAbsent(key, () => data.nodeDrawingData!);
      if (data.domainDrawingData != null) dDic.putIfAbsent(key, () => data.domainDrawingData!);
      if (data.nodeViewData != null) vDic.putIfAbsent(key, () => data.nodeViewData!);
    });
  }
}

class _NodeDataBackup {
  final NodeDrawingData? nodeDrawingData;
  final DomainDrawingData? domainDrawingData;
  final NodeViewData? nodeViewData;
  _NodeDataBackup({this.nodeDrawingData, this.domainDrawingData, this.nodeViewData});
}
