import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeleteNodeLogic {
  static void deleteSelectedNode(BuildContext context) {
    final selection = context.read<SelectionViewData>();
    final treeModel = context.read<ConceptTreeModel>();
    final nodeDrawingDataDic = context.read<ConceptTree2NodeDrawingDataDic>();
    final domainDrawingDataDic = context.read<ConceptTree2DomainDrawingDataDic>();
    final nodeViewDataDic = context.read<ConceptTree2NodeViewDataDic>();
    final globalState = context.read<GlobalStateModel>();
    final addressBar = context.read<AddressBarModel>();

    final commandManager = context.read<CommandManagerForProvider>();

    if (!selection.IsSelecting) return;

    final String parentKey = selection.CurrentDomainNodeKey;
    final bool isParentDomain = selection.IsInDomain;

    // 1. 确定要删除的节点类型和父级
    if (selection.IsSelectedDomain) {
      final domainToDelete = selection.SelectedDomain!;
      final String domainKey = domainToDelete.GetDomainNodeKey();
      final parentDomain = treeModel.GetDomainTree(selection.currentDomain);
      if (parentDomain == null) return;

      final int index = parentDomain.FindDomainIndex(domainToDelete)!;
      final parentDrawingData = domainDrawingDataDic.GetDomainDrawingData(parentKey)!;
      final pos = parentDrawingData.childrenDomainPos[index];

      void doDeleteTree(){
        //先移除tree。
        treeModel.RemoveDomainFromDomain(selection.currentDomain, domainToDelete);
      }
      doDeleteTree();
      // 备份自身及所有子孙的数据
      final backup = _BackupSubtree(domainToDelete,treeModel, nodeDrawingDataDic, domainDrawingDataDic, nodeViewDataDic);
      // 定义执行函数
      void doDeleteDic() {
        parentDrawingData.RemoveAtDomainDrawingDataSqueeze(index);
        _RemoveSubtreeFromDics(domainToDelete,treeModel, nodeDrawingDataDic, domainDrawingDataDic, nodeViewDataDic);
        selection.CancelSelection();
      }

      // 定义撤销函数
      void undoDelete() {
        treeModel.InsertDomainInDomain(selection.currentDomain, domainToDelete, index);
        parentDrawingData.InsertDomainDrawingDataSqueeze(index, pos);
        _RestoreSubtreeToDics(backup, nodeDrawingDataDic, domainDrawingDataDic, nodeViewDataDic);
      }

      // 先执行，再入栈
      doDeleteDic();
      commandManager.PushCommand(commandManager.editInstance, Command(
        function: (){doDeleteTree();doDeleteDic();},
        undoFunction: undoDelete,
      ));

    } else if (selection.IsSelectedConceptNode) {
      final conceptToDelete = selection.SelectedConceptNode!;
      final String conceptKey = conceptToDelete.GetDomainNodeKey();
      
      int index;
      NodeDrawingData parentDrawingData;
      if (isParentDomain) {
        final parent = treeModel.GetDomainTree(parentKey)!;
        index = parent.FindConceptIndex(conceptToDelete)!;
        parentDrawingData = domainDrawingDataDic.GetDomainDrawingData(parentKey)!;
      } else {
        final parent = treeModel.GetConceptNodeByDic(parentKey)!;
        index = parent.FindIndex(conceptToDelete)!;
        parentDrawingData = nodeDrawingDataDic.GetNodeDrawingData(parentKey)!;
      }
      
      final pos = parentDrawingData.childrenNodePos[index];

      void doDeleteTree(){
        if (isParentDomain) {
          treeModel.RemoveConceptFromDomain(parentKey, conceptToDelete);
        } else {
          treeModel.RemoveConceptFromConcept(parentKey, conceptToDelete);
        }
        print("执行tree删除，key$parentKey");
      }

      doDeleteTree();

      final backup = _BackupSubtree(conceptToDelete,treeModel, nodeDrawingDataDic, domainDrawingDataDic, nodeViewDataDic);
      print("备份长度：${backup.length},keys:${backup.keys}");
      // 定义执行函数
      void doDeleteDic() {
        parentDrawingData.RemoveAtNodeDrawingDataSqueeze(index);
        _RemoveSubtreeFromDics(conceptToDelete,treeModel, nodeDrawingDataDic, domainDrawingDataDic, nodeViewDataDic);

        selection.CancelSelectionAndJumpOutParent(
          selectedNode: conceptToDelete,
          parent: conceptToDelete.parent,
          globalState: globalState,
          addressBar: addressBar,
          treeModel: treeModel,
          nodeDrawingDataDic: nodeDrawingDataDic,
          domainDrawingDataDic: domainDrawingDataDic,
          viewDrawingDataDic: nodeViewDataDic,
        );

        //selection.CancelSelectionAndJumpOutParent(parent, addressBar, globalState, treeModel);
        print("执行Dic删除。nodeDrawingDataDic:${nodeDrawingDataDic.toString()},domainDrawingDataDic:${domainDrawingDataDic.toString()}");
      }

      // 定义撤销函数
      void undoDelete() {
        if (isParentDomain) {
          treeModel.InsertConceptInDomain(parentKey, conceptToDelete, index);
        } else {
          treeModel.InsertConceptInConceptNode(parentKey, conceptToDelete, index);
        }
        print("执行tree恢复，key$parentKey");
        parentDrawingData.InsertNodeDrawingDataSqueeze(index, pos);
        print("在位置$index，插入pos$pos");
        _RestoreSubtreeToDics(backup, nodeDrawingDataDic, domainDrawingDataDic, nodeViewDataDic);
        print("执行Dic取消。nodeDrawingDataDic:${nodeDrawingDataDic.toString()},domainDrawingDataDic:${domainDrawingDataDic.toString()}");

        selection.SelectAndFocusNode(
          selectedNode: conceptToDelete,
          parent: conceptToDelete.parent!,
          globalState: globalState,
          addressBar: addressBar,
          treeModel: treeModel,
          nodeDrawingDataDic: nodeDrawingDataDic,
          domainDrawingDataDic: domainDrawingDataDic,
          viewDrawingDataDic: nodeViewDataDic,
        );
      }

      // 先执行，再入栈
      doDeleteDic();
      commandManager.PushCommand(commandManager.editInstance, Command(
        function: (){doDeleteTree();doDeleteDic();},
        undoFunction: undoDelete,
      ));

    }
  }

  // 递归备份子树所有节点的绘图和视图数据
  static Map<String, _NodeDataBackup> _BackupSubtree(NodeTree root,ConceptTreeModel treeModel, ConceptTree2NodeDrawingDataDic nDic, ConceptTree2DomainDrawingDataDic dDic, ConceptTree2NodeViewDataDic vDic) {
    Map<String, _NodeDataBackup> backup = {};
    _RecursiveBackup(root,treeModel, backup, nDic, dDic, vDic);
    return backup;
  }

  static void _RecursiveBackup(NodeTree node,ConceptTreeModel treeModel ,Map<String, _NodeDataBackup> backup, ConceptTree2NodeDrawingDataDic nDic, ConceptTree2DomainDrawingDataDic dDic, ConceptTree2NodeViewDataDic vDic) {
    final key = node.GetDomainNodeKey();
    if(!treeModel.ContainConceptNode(key)){
      print("备份drawingData数据。尝试通过key:${key},从字典：${nDic.toString()}获取drawingData");
      backup[key] = _NodeDataBackup(
        nodeDrawingData: nDic.GetNodeDrawingData(key),
        domainDrawingData: dDic.GetDomainDrawingData(key),
        nodeViewData: vDic.GetNodeViewData(key),
      );
    }

    if (node is ConceptNodeTree) {
      for (var child in node.children) {
        _RecursiveBackup(child,treeModel, backup, nDic, dDic, vDic);
      }
    } else if (node is DomainTree) {
      for (var child in node.children) {
        _RecursiveBackup(child,treeModel, backup, nDic, dDic, vDic);
      }
      for (var child in node.conceptNodeTree) {
        _RecursiveBackup(child,treeModel, backup, nDic, dDic, vDic);
      }
    }
  }

  // 递归从字典中移除子树
  static void _RemoveSubtreeFromDics(NodeTree node,ConceptTreeModel treeModel, ConceptTree2NodeDrawingDataDic nDic, ConceptTree2DomainDrawingDataDic dDic, ConceptTree2NodeViewDataDic vDic) {
    final key = node.GetDomainNodeKey();
    if(!treeModel.ContainConceptNode(key)) {
      nDic.remove(key);
      dDic.remove(key);
      vDic.remove(key);
    }
    if (node is ConceptNodeTree) {
      for (var child in node.children) _RemoveSubtreeFromDics(child,treeModel, nDic, dDic, vDic);
    } else if (node is DomainTree) {
      for (var child in node.children) _RemoveSubtreeFromDics(child,treeModel, nDic, dDic, vDic);
      for (var child in node.conceptNodeTree) _RemoveSubtreeFromDics(child,treeModel, nDic, dDic, vDic);
    }
  }

  // 递归恢复字典数据
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
