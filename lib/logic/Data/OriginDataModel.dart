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

  /// 根据 OriginDataModel 重建 APP 的 5 项核心数据。
  /// 此方法会自动补充缺失的渲染、视图及修饰词数据。
  void applyOriginData({
    required ConceptTreeModel treeModel,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDic,
    required ConceptTree2DomainDrawingDataDic domainDrawingDic,
    required ConceptTree2NodeViewDataDic nodeViewDic,
    required ConceptTree2ConceptDecorationDic decorationDic,
  }) {
    // 0. 清理旧数据，防止字典冲突或数据残留
    nodeDrawingDic.data = {};
    domainDrawingDic.data = {};
    nodeViewDic.data = {};
    decorationDic.clear();
    // 1. 初始化逻辑树根节点名
    treeModel.rootTree = DomainTree()..name = originDomainTree.domain;
    
    // 2. 递归构建树结构并填充字典
    _buildDomainRecursive(
      origin: originDomainTree,
      target: treeModel.rootTree!,
      treeModel: treeModel,
      nodeDrawingDic: nodeDrawingDic,
      domainDrawingDic: domainDrawingDic,
      nodeViewDic: nodeViewDic,
      decorationDic: decorationDic,
    );

    // 3. 最终生成查找字典并通知更新
    treeModel.GenerateDic();
    //treeModel.notifyListeners();
    nodeDrawingDic.repaint();
    domainDrawingDic.repaint();
    nodeViewDic.repaint();
    decorationDic.repaint();
  }

  void _buildDomainRecursive({
    required OriginDataDomain origin,
    required DomainTree target,
    required ConceptTreeModel treeModel,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDic,
    required ConceptTree2DomainDrawingDataDic domainDrawingDic,
    required ConceptTree2NodeViewDataDic nodeViewDic,
    required ConceptTree2ConceptDecorationDic decorationDic,
  }) {
    String domainKey = target.GetDomainKey();
    //throw Exception("递归构建domainDrawingData");
    // 初始化 Domain 渲染与视图数据 (putIfAbsent 保证不覆盖已有数据)
    final domainDrawingData = domainDrawingDic.putIfAbsent(domainKey, () => DomainDrawingData(nodeAppearance: NodeAppearance())..text = target.name);
    nodeViewDic.putIfAbsent(domainKey, () => NodeViewData());

    // 构建子域
    for (var originChild in origin.children) {
      var targetChild = DomainTree()
        ..name = originChild.domain
        ..parent = target;
      target.children.add(targetChild);
      domainDrawingData.AddDomainDrawingData();
      _buildDomainRecursive(
        origin: originChild,
        target: targetChild,
        treeModel: treeModel,
        nodeDrawingDic: nodeDrawingDic,
        domainDrawingDic: domainDrawingDic,
        nodeViewDic: nodeViewDic,
        decorationDic: decorationDic,
      );
    }

    // 构建概念
    for (var originConcept in origin.conceptNodeTree) {
      var targetConcept = ConceptNodeTree()
        ..name = originConcept.concept
        ..parent = target
        ..domainKey = domainKey;
      target.conceptNodeTree.add(targetConcept);
      domainDrawingData.AddNodeDrawingData();
      _buildConceptRecursive(
        origin: originConcept,
        target: targetConcept,
        domainKey: domainKey,
        treeModel: treeModel,
        nodeDrawingDic: nodeDrawingDic,
        nodeViewDic: nodeViewDic,
        decorationDic: decorationDic,
      );
    }
  }

  void _buildConceptRecursive({
    required OriginDataConcept origin,
    required ConceptNodeTree target,
    required String domainKey,
    required ConceptTreeModel treeModel,
    required ConceptTree2NodeDrawingDataDic nodeDrawingDic,
    required ConceptTree2NodeViewDataDic nodeViewDic,
    required ConceptTree2ConceptDecorationDic decorationDic,
  }) {
    String nodeKey = ConceptTreeModel.GenerateDomainNodeKey(domainKey, target.name, target.alias);

    // 1. 初始化 Concept 渲染数据
    final nodeDrawingData = nodeDrawingDic.putIfAbsent(nodeKey, () => NodeDrawingData(nodeAppearance: NodeAppearance())..text = target.name);
    
    // 2. 初始化视角数据
    nodeViewDic.putIfAbsent(nodeKey, () => NodeViewData());

    // 3. 初始化修饰词字典：将 OriginData 的 List 转为 Map 状态
    if (origin.modifiers.isNotEmpty) {
      decorationDic.putIfAbsent(nodeKey, () {
        var dec = ConceptDecoration(modifiers: origin.modifiers.toSet());
        return dec;
      });
      // 同步到绘图数据的临时集合中以供显示
      nodeDrawingDic.GetNodeDrawingData(nodeKey)?.decoration.addAll(origin.modifiers);
    }

    // 4. 处理子概念
    for (var originChild in origin.children) {
      var targetChild = ConceptNodeTree()
        ..name = originChild.concept
        ..parent = target
        ..domainKey = domainKey;
      target.children.add(targetChild);
      nodeDrawingData.AddNodeDrawingData();
      _buildConceptRecursive(
        origin: originChild,
        target: targetChild,
        domainKey: domainKey,
        treeModel: treeModel,
        nodeDrawingDic: nodeDrawingDic,
        nodeViewDic: nodeViewDic,
        decorationDic: decorationDic,
      );
    }
  }

  /// 从当前内存状态构建 OriginDataModel
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
