import 'package:concept_navigator/logic/Data/ConceptDecoration.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:flutter/material.dart';

class OriginDataDomain {
  String domain = "newDomain";
  List<OriginDataDomain> children = [];
  List<OriginDataConcept> conceptNodeTree = [];

  OriginDataDomain({required this.domain});

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      'children': children.map((e) => e.toJson()).toList(),
      'conceptNodeTree': conceptNodeTree.map((e) => e.toJson()).toList(),
    };
  }

  factory OriginDataDomain.fromJson(Map<String, dynamic> json) {
    var d = OriginDataDomain(domain: json['domain'] ?? "newDomain");
    if (json['children'] != null) {
      d.children = (json['children'] as List).map((e) => OriginDataDomain.fromJson(e)).toList();
    }
    if (json['conceptNodeTree'] != null) {
      d.conceptNodeTree = (json['conceptNodeTree'] as List).map((e) => OriginDataConcept.fromJson(e)).toList();
    }
    return d;
  }
}

class OriginDataConcept {
  String concept = "newConcept";
  List<String> modifiers = [];
  List<OriginDataConcept> children = [];

  OriginDataConcept({required this.concept});

  Map<String, dynamic> toJson() {
    return {
      'concept': concept,
      'modifiers': modifiers,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }

  factory OriginDataConcept.fromJson(Map<String, dynamic> json) {
    var c = OriginDataConcept(concept: json['concept'] ?? "newConcept");
    c.modifiers = List<String>.from(json['modifiers'] ?? []);
    if (json['children'] != null) {
      c.children = (json['children'] as List).map((e) => OriginDataConcept.fromJson(e)).toList();
    }
    return c;
  }
}

class OriginDataModel {
  late OriginDataDomain originDomainTree;

  OriginDataModel({required this.originDomainTree});

  OriginDataModel.fromJson(Map<String, dynamic> json) {
    originDomainTree = OriginDataDomain.fromJson(json['originDomainTree']);
  }

  Map<String, dynamic> toJson() {
    return {
      'originDomainTree': originDomainTree.toJson(),
    };
  }

  /// 根据 OriginDataModel 重建 APP 的核心数据。
  void applyOriginData({
    required ConceptTreeModel treeModel,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDic,
    required ConceptTree2DomainDrawingDataDic domainDrawingDic,
    required ConceptTree2NodeViewDataDic nodeViewDic,
    required ConceptTree2ConceptDecorationDic decorationDic,
  }) {
    // 0. 清理旧字典数据
    nodeDrawingDic.data = {};
    domainDrawingDic.data = {};
    nodeViewDic.data = {};
    decorationDic.clear();

    // 1. 第一步：仅构建逻辑树结构 (设置 autoAlias 为 true)
    treeModel.rootTree = DomainTree()..name = originDomainTree.domain;
    _buildLogicTreeRecursive(origin: originDomainTree, target: treeModel.rootTree!);

    // 2. 第二步：执行 GenerateDic()。
    // 这会触发 BFS 遍历，计算所有开启了 autoAlias 节点的真实 alias 并回填。
    treeModel.GenerateDic();

    // 3. 第三步：根据构建好的逻辑树（此时已拥有正确的 alias）初始化所有辅助字典
    _initDictionariesFromTree(
      root: treeModel.rootTree!,
      nodeDrawingDic: nodeDrawingDic,
      domainDrawingDic: domainDrawingDic,
      nodeViewDic: nodeViewDic,
      decorationDic: decorationDic,
      // 传入原始数据模型，以便恢复修饰词等信息
      originRoot: originDomainTree,
    );

    // 4. 通知各层级刷新绘制
    nodeDrawingDic.repaint();
    domainDrawingDic.repaint();
    nodeViewDic.repaint();
    decorationDic.repaint();
  }

  /// 递归构建纯逻辑树
  void _buildLogicTreeRecursive({
    required OriginDataDomain origin,
    required DomainTree target,
  }) {
    // 构建子域
    for (var originChild in origin.children) {
      var targetChild = DomainTree()
        ..name = originChild.domain
        ..parent = target;
      target.children.add(targetChild);
      _buildLogicTreeRecursive(origin: originChild, target: targetChild);
    }

    // 构建概念
    for (var originConcept in origin.conceptNodeTree) {
      var targetConcept = ConceptNodeTree()
        ..name = originConcept.concept
        ..autoAlias = true // 强制开启自动路径别名
        ..parent = target;
      target.conceptNodeTree.add(targetConcept);
      _buildLogicConceptRecursive(origin: originConcept, target: targetConcept);
    }
  }

  void _buildLogicConceptRecursive({
    required OriginDataConcept origin,
    required ConceptNodeTree target,
  }) {
    for (var originChild in origin.children) {
      var targetChild = ConceptNodeTree()
        ..name = originChild.concept
        ..autoAlias = true
        ..parent = target;
      target.children.add(targetChild);
      _buildLogicConceptRecursive(origin: originChild, target: targetChild);
    }
  }

  /// 递归初始化字典 (此时 NodeTree 已经有了正确的 alias 和 domainKey)
  void _initDictionariesFromTree({
    required DomainTree root,
    required OriginDataDomain originRoot,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDic,
    required ConceptTree2DomainDrawingDataDic domainDrawingDic,
    required ConceptTree2NodeViewDataDic nodeViewDic,
    required ConceptTree2ConceptDecorationDic decorationDic,
  }) {
    String domainKey = root.GetDomainKey();

    // 1. 初始化当前 Domain 的字典
    final domainDrawing = domainDrawingDic.putIfAbsent(
      domainKey,
          () => DomainDrawingData(nodeAppearance: NodeAppearance())..text = root.name,
    );
    nodeViewDic.putIfAbsent(domainKey, () => NodeViewData());

    // 2. 处理子域
    for (int i = 0; i < root.children.length; i++) {
      domainDrawing.AddDomainDrawingData(); // 初始化子域在父级中的位置
      _initDictionariesFromTree(
        root: root.children[i],
        originRoot: originRoot.children[i],
        nodeDrawingDic: nodeDrawingDic,
        domainDrawingDic: domainDrawingDic,
        nodeViewDic: nodeViewDic,
        decorationDic: decorationDic,
      );
    }

    // 3. 处理当前域下的直属概念
    for (int i = 0; i < root.conceptNodeTree.length; i++) {
      var node = root.conceptNodeTree[i];
      var originNode = originRoot.conceptNodeTree[i];
      domainDrawing.AddNodeDrawingData(); // 初始化概念在父域中的位置
      _initDictionariesConceptRecursive(
        target: node,
        origin: originNode,
        nodeDrawingDic: nodeDrawingDic,
        nodeViewDic: nodeViewDic,
        decorationDic: decorationDic,
      );
    }
  }

  void _initDictionariesConceptRecursive({
    required ConceptNodeTree target,
    required OriginDataConcept origin,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDic,
    required ConceptTree2NodeViewDataDic nodeViewDic,
    required ConceptTree2ConceptDecorationDic decorationDic,
  }) {
    // 关键：此时 GetDomainNodeKey() 获取的是已经计算好的唯一 Key
    String nodeKey = target.GetDomainNodeKey();

    // 初始化概念绘图数据
    final nodeDrawing = nodeDrawingDic.putIfAbsent(
      nodeKey,
          () => NodeDrawingData(nodeAppearance: NodeAppearance())..text = target.name,
    );
    nodeViewDic.putIfAbsent(nodeKey, () => NodeViewData());

    // 恢复修饰词
    if (origin.modifiers.isNotEmpty) {
      decorationDic.putIfAbsent(nodeKey, () => ConceptDecoration(modifiers: origin.modifiers.toSet()));
      nodeDrawing.decoration.addAll(origin.modifiers);
    }

    // 递归处理子概念
    for (int i = 0; i < target.children.length; i++) {
      nodeDrawing.AddNodeDrawingData(); // 初始化子概念在父概念中的位置
      _initDictionariesConceptRecursive(
        target: target.children[i],
        origin: origin.children[i],
        nodeDrawingDic: nodeDrawingDic,
        nodeViewDic: nodeViewDic,
        decorationDic: decorationDic,
      );
    }
  }

  ///从当前内存状态构建 OriginDataModel
  static OriginDataModel fromAppState({
    required ConceptTreeModel treeModel,
    required ConceptTree2ConceptDecorationDic decorationDic,
  }) {
    if (treeModel.rootTree == null) {
      return OriginDataModel(originDomainTree: OriginDataDomain(domain: "root"));
    }
    return OriginDataModel(
      originDomainTree: _exportDomainRecursive(treeModel.rootTree!, decorationDic),
    );
  }

  static OriginDataDomain _exportDomainRecursive(DomainTree domain, ConceptTree2ConceptDecorationDic decorationDic) {
    var result = OriginDataDomain(domain: domain.name);

    for (var childDomain in domain.children) {
      result.children.add(_exportDomainRecursive(childDomain, decorationDic));
    }

    for (var concept in domain.conceptNodeTree) {
      result.conceptNodeTree.add(_exportConceptRecursive(concept, decorationDic));
    }

    return result;
  }

  static OriginDataConcept _exportConceptRecursive(ConceptNodeTree concept, ConceptTree2ConceptDecorationDic decorationDic) {
    var result = OriginDataConcept(concept: concept.name);

    // 获取修饰词
    String nodeKey = concept.GetDomainNodeKey();
    var dec = decorationDic.data[nodeKey];
    if (dec != null) {
      result.modifiers = dec.modifiers.keys.toList();
    }

    for (var childConcept in concept.children) {
      result.children.add(_exportConceptRecursive(childConcept, decorationDic));
    }

    return result;
  }
}
/*
///
 */