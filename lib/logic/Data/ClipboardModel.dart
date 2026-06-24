import 'package:flutter/material.dart';
import 'ConceptTree.dart';

enum ClipboardType { copy, cut }

class ClipboardData {
  final NodeTree node;
  final ClipboardType type;
  // 记录来源父节点，用于剪切后的逻辑处理
  final NodeTree parentNode;

  ClipboardData({
    required this.node,
    required this.type,
    required this.parentNode,
  });

  bool get isCut => type == ClipboardType.cut;
}

class ClipboardModel extends ChangeNotifier {
  ClipboardData? _data;

  ClipboardData? get data => _data;

  void copy(NodeTree node, NodeTree parentNode) {
    // 复制时进行深拷贝
    NodeTree clonedNode;
    if (node is ConceptNodeTree) {
      clonedNode = ConceptNodeTree.fromJson(node.toJson());
    } else if (node is DomainTree) {
      clonedNode = DomainTree.fromJson(node.toJson());
    } else {
      return;
    }

    _data = ClipboardData(
      node: clonedNode,
      type: ClipboardType.copy,
      parentNode: parentNode,
    );
    notifyListeners();
  }

  void cut(NodeTree node, NodeTree parentNode) {
    // 剪切直接引用原节点
    _data = ClipboardData(
      node: node,
      type: ClipboardType.cut,
      parentNode: parentNode,
    );
    notifyListeners();
  }

  void clear() {
    _data = null;
    notifyListeners();
  }
}
