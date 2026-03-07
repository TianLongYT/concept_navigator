
//域树。节点树。
import 'dart:collection';

import 'package:flutter/material.dart';

abstract class NodeTree{
  bool get IsInDomain;
  String name = "";
  String GetDomainKey();
  String GetDomainNodeKey();

  Map<String, dynamic> toJson();
}

enum ConceptStatus {
  normal,            // 普通状态：不存在同名概念
  template,          // 模板状态：存在同名，别名为空，且是广度优先最先遍历到的
  templateReference, // 引用状态：存在同名，别名为空，但不是第一个
  instance           // 实例状态：存在同名，且别名不为空
}

class ConceptNodeTree extends NodeTree{
  // 显式添加默认构造函数，因为 factory fromJson 的存在会导致默认构造函数消失
  ConceptNodeTree();

  List<ConceptNodeTree> children = [];
  String name = "NewConcept";
  String alias = "";
  String domainKey = "root";
  NodeTree? parent = null;

  int? FindIndex(ConceptNodeTree child){
    for(int i =0;i<children.length;i++){
      if(children[i] == child) {
        return i;
      }
    }
    return null;
  }

  /// 获取当前节点的状态(需要遍历树，非常耗。看后续能否用数据额外记录)
  ConceptStatus getStatus(ConceptTreeModel model) {
    // 1. 获取当前域中所有同名节点
    List<ConceptNodeTree> sameNameNodes = model.getAllConceptNodesWithName(domainKey, name);
    
    if (sameNameNodes.length <= 1) {
      return ConceptStatus.normal;
    }

    if (alias.isNotEmpty) {
      return ConceptStatus.instance;
    } else {
      // 别名为空的情况，判断是否是第一个遍历到的
      ConceptNodeTree? firstOne = model.getFirstOccurrenceOfName(domainKey, name);
      if (firstOne == this) {
        return ConceptStatus.template;
      } else {
        return ConceptStatus.templateReference;
      }
    }
  }

  @override String toString() {
    return "name${name},alias${alias},children${children},childrenCount${children.length}";
  }

  @override
  String GetDomainKey() {
    return domainKey;
  }

  @override
  String GetDomainNodeKey() {
    return ConceptTreeModel.GenerateDomainNodeKey(domainKey, name, alias);
  }

  @override
  bool get IsInDomain => false;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'concept',
      'name': name,
      'alias': alias,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }

  factory ConceptNodeTree.fromJson(Map<String, dynamic> json,{NodeTree? parent}) {
    var node = ConceptNodeTree()
      ..name = json['name'] ?? ""
      ..alias = json['alias'] ?? "";
    if (json['children'] != null) {
      node.children = (json['children'] as List).map((e) => ConceptNodeTree.fromJson(e,parent: parent)).toList();
    }
    return node;
  }
}

class DomainTree extends NodeTree{
  // 显式添加默认构造函数
  DomainTree();

  DomainTree? parent = null;
  List<DomainTree> children = [];
  List<ConceptNodeTree> conceptNodeTree = [];
  String name = "NewDomain";

  DomainTree? Find(String domain){
    if(name == domain)
      return this;
    else{
      DomainTree? result;
      for(int i = 0;i<children.length;i++){
        result = children[i].Find(domain);
        if(result != null)
          return result;
      }
      return result;
    }

  }

  int? FindConceptIndex(ConceptNodeTree child){
    for(int i =0;i<conceptNodeTree.length;i++){
      if(conceptNodeTree[i] == child) {
        return i;
      }
    }
    return null;
  }
  int? FindDomainIndex(DomainTree child){
    for(int i =0;i<children.length;i++){
      if(children[i] == child) {
        return i;
      }
    }
    return null;
  }

  String GetDomainKey(){
    DomainTree? pointer = this;
    List<String> domainNameList = [];
    while(pointer != null){
      domainNameList.add(pointer.name);
      pointer = pointer.parent;
    }
    if(domainNameList.isEmpty){
      return "";
    }
    String res = domainNameList.last;
    for(int i = domainNameList.length - 2;i>=0;i--){
      res = ConceptTreeModel.AppendDomainKey(res, domainNameList[i]);
    }
    return res;
  }

  @override
  String GetDomainNodeKey() {
    return GetDomainKey();
  }

  @override
  bool get IsInDomain => true;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'domain',
      'name': name,
      'children': children.map((e) => e.toJson()).toList(),
      'conceptNodeTree': conceptNodeTree.map((e) => e.toJson()).toList(),
    };
  }

  factory DomainTree.fromJson(Map<String, dynamic> json, {DomainTree? parent}) {
    var domain = DomainTree()
      ..name = json['name'] ?? ""
      ..parent = parent;
    if (json['children'] != null) {
      domain.children = (json['children'] as List).map((e) => DomainTree.fromJson(e, parent: domain)).toList();
    }
    if (json['conceptNodeTree'] != null) {
      domain.conceptNodeTree = (json['conceptNodeTree'] as List).map((e) => ConceptNodeTree.fromJson(e,parent: domain)).toList();
    }
    return domain;
  }
}

class ConceptTreeModel extends ChangeNotifier{
  DomainTree? rootTree;//从文件读取。先正确创建再考虑存档问题。
  //显示字典。
  Map<String,ConceptNodeTree> domainNodeKey2ConceptTree = {};
  ConceptTreeModel({required this.rootTree}){
    if(rootTree == null)
      rootTree = DomainTree()..name = "root";//默认创建域树，域的根节点为root。
    GenerateDic();
  }
  //构建获取节点树字典
  GenerateDic({String? domainKey}){
    // 如果未提供 domainKey，默认从 rootTree 的根路径开始生成
    String key = domainKey ?? rootTree?.name ?? "root";
    DomainTree? startTree = GetDomainTree(key);
    print("findNull${startTree}");
    if(startTree == null) return;
    domainNodeKey2ConceptTree.clear();
    print("getTree${startTree.GetDomainKey()}");

    // 改为广度优先遍历 (BFS)，确保最先遍历到的（更高层级的）节点作为模板。
    Queue<Map<String, dynamic>> queue = Queue();
    queue.add({
      'node': startTree,
      'domainKey': startTree.GetDomainKey(),
    });

    while (queue.isNotEmpty) {
      var current = queue.removeFirst();
      var node = current['node'];
      String dKey = current['domainKey'];

      if (node is DomainTree) {
        // 先处理该域下的直属概念
        for (var concept in node.conceptNodeTree) {
          queue.add({
            'node': concept,
            'domainKey': dKey,
          });
        }
        // 再将子域加入队列
        for (var childDomain in node.children) {
          queue.add({
            'node': childDomain,
            'domainKey': AppendDomainKey(dKey, childDomain.name),
          });
        }
      } else if (node is ConceptNodeTree) {
        // 处理概念节点
        node.domainKey = dKey;
        String nodeKey = GenerateDomainNodeKey(dKey, node.name, node.alias);
        
        // 广度优先：如果字典中已存在该 key，则保留先遍历到的（通常是更高层级的）
        if (!domainNodeKey2ConceptTree.containsKey(nodeKey)) {
          domainNodeKey2ConceptTree[nodeKey] = node;
        }

        // 将子概念加入队列
        for (var child in node.children) {
          queue.add({
            'node': child,
            'domainKey': dKey,
          });
        }
      }
    }

    notifyListeners();
  }
  _GenerateDicDomain(String domainKey,DomainTree domainTree){
    for(int i = 0; i<domainTree.conceptNodeTree.length;i++){
      _GenerateDicNode(domainKey, domainTree.conceptNodeTree[i]);
    }
    for(int i =0;i<domainTree.children.length;i++){
      _GenerateDicDomain(AppendDomainKey(domainKey, domainTree.children[i].name),domainTree.children[i]);
    }
  }
  _GenerateDicNode(String domainKey,ConceptNodeTree nodeTree){
    nodeTree.domainKey = domainKey;
    String key = GenerateDomainNodeKey(domainKey, nodeTree.name, nodeTree.alias);
    if(domainNodeKey2ConceptTree.containsKey(key)){
      return;
    }
    domainNodeKey2ConceptTree[key] = nodeTree;
    for(int i =0;i<nodeTree.children.length;i++){
      _GenerateDicNode(domainKey, nodeTree.children[i]);
    }
  }

  void _RemoveNodeFromDic(String domainKey, ConceptNodeTree nodeTree) {
    String key = GenerateDomainNodeKey(domainKey, nodeTree.name, nodeTree.alias);
    domainNodeKey2ConceptTree.remove(key);
    for (var child in nodeTree.children) {
      _RemoveNodeFromDic(domainKey, child);
    }
  }

  /// 获取指定域中所有名称匹配的节点
  List<ConceptNodeTree> getAllConceptNodesWithName(String domainKey, String name) {
    List<ConceptNodeTree> result = [];
    DomainTree? domain = GetDomainTree(domainKey);
    if (domain == null) return result;

    void traverse(NodeTree node) {
      if (node is ConceptNodeTree && node.name == name) {
        result.add(node);
      }
      if (node is DomainTree) {
        for (var c in node.conceptNodeTree) traverse(c);
        for (var d in node.children) {
           // 注意：域划分了范围，同名概念可以在不同域。
           // 这里我们只在当前域内寻找。
           // 如果需要跨子域寻找，则取消 return 限制
        }
      } else if (node is ConceptNodeTree) {
        for (var c in node.children) traverse(c);
      }
    }
    
    // 在当前域及其子概念树中搜索
    for (var concept in domain.conceptNodeTree) traverse(concept);
    return result;
  }

  /// 广度优先遍历找到第一个出现的同名节点
  ConceptNodeTree? getFirstOccurrenceOfName(String domainKey, String name) {
    DomainTree? domain = GetDomainTree(domainKey);
    if (domain == null) return null;

    Queue<NodeTree> queue = Queue();
    for (var c in domain.conceptNodeTree) queue.add(c);

    while (queue.isNotEmpty) {
      NodeTree current = queue.removeFirst();
      if (current is ConceptNodeTree) {
        if (current.name == name && current.alias.isEmpty) return current;
        for (var child in current.children) queue.add(child);
      }
    }
    return null;
  }

  static const String AppendOperator = "/_/";//把_/设置为禁用组合。
  static const List<String> ErrorPatten = ["_/","/_","/_/"];
  static String GenerateDomainNodeKey(String domain,String name,String alias){
    return domain+AppendOperator+AppendOperator+name+AppendOperator+alias;
  }
  static String GenerateDomainNodeKeyNA(String domain,String nameAlias){
    return domain+AppendOperator+AppendOperator+nameAlias;
  }
  static List<String> SplitDomainNodeKeyOutNodeNameAlias(String domainNodeKey){
    List<String> tmpList = domainNodeKey.split(AppendOperator+AppendOperator);
    if(tmpList.length != 2){
      throw Exception("无法分离该domainNodeKey:$domainNodeKey");
    }
    return tmpList[1].split(AppendOperator);
  }
  static String AppendDomainKey(String domainKey,String domainOrdomainKey){
    return domainKey + AppendOperator + domainOrdomainKey;
  }
  static List<String> SplitDomainKey(String domainKey){
    return domainKey.split(AppendOperator);
  }
  static String DomainNodeKey2DomainKey(String domainNodeKey){
    return domainNodeKey.split(AppendOperator+AppendOperator).first;
  }
  static String RemoveAliasFromDomainNodeKey(String domainNodeKey) {
    List<String> tmpList = domainNodeKey.split(AppendOperator + AppendOperator);
    if (tmpList.length == 2) {
      String domain = tmpList[0];
      String name = tmpList[1].split(AppendOperator)[0];
      return domain + AppendOperator + AppendOperator + name;
    }
    return domainNodeKey;
  }
  static bool domainKeyContainEqual(String longDomainNodeKey,String shortDomainKey){
    assert(shortDomainKey.split(AppendOperator + AppendOperator).length != 1,
    "domainKeyContain传入的shortDomainkey必须是domainKey,而不能是domainNodeKey");
    List<String> tmpList = longDomainNodeKey.split(AppendOperator+AppendOperator);
    String longDomainKey = longDomainNodeKey;
    if(tmpList.length == 2){
      longDomainKey = tmpList.first;
    }
    List<String> keys1 = SplitDomainKey(longDomainKey);
    List<String> keys2 = SplitDomainKey(shortDomainKey);
    if(keys1.length < keys2.length){
      return false;
    }
    for(int i = 0; i<keys2.length;i++){
      if(keys1[i] != keys2[i]){
        return false;
      }
    }
    return true;
  }
  static String? replaceDomainKey(String longDomainNodeKey,String shortDomainKey,String newDomainName){
    assert(shortDomainKey.split(AppendOperator + AppendOperator).length == 1,
    "domainKeyContain传入的shortDomainkey必须是domainKey,而不能是domainNodeKey,shortDomainKey:$shortDomainKey,splitLength${shortDomainKey.split(AppendOperator + AppendOperator).length}");
    List<String> tmpList = longDomainNodeKey.split(AppendOperator+AppendOperator);
    String longDomainKey = longDomainNodeKey;
    String longDomainNameAlias = "";
    if(tmpList.length == 2){
      longDomainKey = tmpList.first;
      longDomainNameAlias = tmpList.last;
    }
    List<String> keys1 = SplitDomainKey(longDomainKey);
    List<String> keys2 = SplitDomainKey(shortDomainKey);
    print("longDomainNodeKey:$longDomainNodeKey,shrotDomainKey:$shortDomainKey,keys1:$keys1,keys2:$keys2,longDomainKey:$longDomainKey,longdomainNameAlias:$longDomainNameAlias");
    if(keys1.length < keys2.length){
      return null;
    }
    for(int i = 0;i<keys2.length;i++){
      if(keys1[i] != keys2[i]){
        print("交换失败,发现Keys1:${keys1[i]}!=${keys2[i]}");
        return null;
      }
    }
    print("成功交换，原本${keys1[keys2.length - 1]},换成${newDomainName},");
    keys1[keys2.length - 1] = newDomainName;
    String replacedDomainKey = keys1[0];
    for(int i = 1;i < keys1.length;i++){
      replacedDomainKey = AppendDomainKey(replacedDomainKey, keys1[i]);
    }
    if(longDomainNameAlias != ""){
      replacedDomainKey = GenerateDomainNodeKeyNA(replacedDomainKey, longDomainNameAlias);
    }

    return replacedDomainKey;
  }

  //通过字典获取节点树
  ConceptNodeTree? GetConceptNodeByDic(String domainNodeKey){
    if(domainNodeKey2ConceptTree.containsKey(domainNodeKey)){
      return domainNodeKey2ConceptTree[domainNodeKey];
    }
    return null;

  }

  //获取域树
  DomainTree? GetDomainTree(String domainKey){
    if(rootTree == null)
      return null;
    List<String> domainList = SplitDomainKey(domainKey);
    DomainTree? result = null;
    if(rootTree!.name == domainList[0])
      result = rootTree;
    for(int i = 1;i<domainList.length;i++){
      result = _GetDomainTreeCor(result!,domainList[i]);
      if(result == null)
        return result;
    }
    return result;
  }
  DomainTree? _GetDomainTreeCor(DomainTree tree,String domainName){

    for(int i = 0; i<tree.children.length;i++){
      if(tree.children[i].name == domainName)
        return tree.children[i];
    }
    return null;

  }
  //增减树
  bool AddNewDomainInDomain(String domainKey,DomainTree newTree){
    DomainTree? domain = GetDomainTree(domainKey);
    if(domain == null) {
      return false;
    }
    newTree.parent = domain;
    domain.children.add(newTree);
    GenerateDic();
    notifyListeners();
    return true;
  }
  bool AddNewConceptInDomain(String domainKey,ConceptNodeTree newTree){
    DomainTree? domain = GetDomainTree(domainKey);
    if(domain == null) {
      return false;
    }
    newTree.domainKey = domainKey;
    newTree.parent = domain;
    domain.conceptNodeTree.add(newTree);
    GenerateDic();
    notifyListeners();
    return true;
  }
  bool AddNewConceptInConceptNode(String domainNodeKey,ConceptNodeTree newTree){
    ConceptNodeTree? concept = GetConceptNodeByDic(domainNodeKey);
    if(concept == null){
      return false;
    }
    String domainKey = ConceptTreeModel.DomainNodeKey2DomainKey(domainNodeKey);
    if(domainKey != concept.domainKey){
      throw Exception("在概念中新增节点时，查询的节点与实际节点的domainKey不一致");
      return false;
    }

    newTree.domainKey = domainKey;
    newTree.parent = concept;
    concept.children.add(newTree);
    GenerateDic();
    notifyListeners();
    return true;
  }

  bool InsertDomainInDomain(String domainKey, DomainTree newTree, int index) {
    DomainTree? domain = GetDomainTree(domainKey);
    if (domain == null) return false;
    newTree.parent = domain;
    domain.children.insert(index, newTree);
    GenerateDic();
    notifyListeners();
    return true;
  }

  bool InsertConceptInDomain(String domainKey, ConceptNodeTree newTree, int index) {
    DomainTree? domain = GetDomainTree(domainKey);
    if (domain == null) return false;
    newTree.domainKey = domainKey;
    newTree.parent = domain;
    domain.conceptNodeTree.insert(index, newTree);
    GenerateDic();
    notifyListeners();
    return true;
  }

  bool InsertConceptInConceptNode(String domainNodeKey, ConceptNodeTree newTree, int index) {
    ConceptNodeTree? parent = GetConceptNodeByDic(domainNodeKey);
    if (parent == null) return false;
    String domainKey = ConceptTreeModel.DomainNodeKey2DomainKey(domainNodeKey);
    newTree.domainKey = domainKey;
    newTree.parent = parent;
    parent.children.insert(index, newTree);
    GenerateDic();
    notifyListeners();
    return true;
  }

  bool RemoveConceptFromDomain(String domainKey, ConceptNodeTree child) {
    DomainTree? domain = GetDomainTree(domainKey);
    if (domain == null) return false;
    int? index = domain.FindConceptIndex(child);
    if (index == null) return false;
    domain.conceptNodeTree.removeAt(index);
    GenerateDic();
    notifyListeners();
    return true;
  }

  bool RemoveConceptFromConcept(String domainNodeKey, ConceptNodeTree child) {
    ConceptNodeTree? parent = GetConceptNodeByDic(domainNodeKey);
    if (parent == null) return false;
    int? index = parent.FindIndex(child);
    if (index == null) return false;
    parent.children.removeAt(index);
    GenerateDic();
    notifyListeners();
    return true;
  }

  bool RemoveDomainFromDomain(String parentDomainKey, DomainTree child) {
    DomainTree? parent = GetDomainTree(parentDomainKey);
    if (parent == null) return false;
    int? index = parent.FindDomainIndex(child);
    if (index == null) return false;
    parent.children.removeAt(index);
    GenerateDic();
    notifyListeners();
    return true;
  }

  //重名检测，
  bool ContainDomain(String domainKey,String domainName){
    DomainTree? domainTree = GetDomainTree(domainKey);
    if(domainTree == null){
      print("错误：请输入正确的域键");
      return false;
    }
    if(domainTree.children.where((element)=>element.name == domainName).length != 0){
      return true;
    }
    return false;
  }
  bool ContainConceptNode(String domainNodeKey){
    return domainNodeKey2ConceptTree.containsKey(domainNodeKey);
  }
  bool ContainConceptNodeNameAlias(String domainNodeKey){
    var tmpList = SplitDomainNodeKeyOutNodeNameAlias(domainNodeKey);
    print("alias：${tmpList[1]}");
    if(tmpList[1] == ""){
      return false;
    }
    return domainNodeKey2ConceptTree.containsKey(domainNodeKey);
  }

  String PrintTree(){
    if(rootTree == null){
      return "";
    }
    return _PrintDomainTreeCor(rootTree!,0);
  }
  String _PrintDomainTreeCor(DomainTree domainTree,int layer){

    String res = "\r\n" + Layer2Indentation(layer)+  "rootDomain:"+domainTree.name;
    res += "\r\n"+ Layer2Indentation(layer+1)+ "childDomain:";
    for(int i = 0; i< domainTree.children.length;i++){
      res +=" ";
      res += _PrintDomainTreeCor(domainTree.children[i],layer +1);
    }
    res += "\r\n" + Layer2Indentation(layer+1)+ "childNode:";
    for(int i =0;i<domainTree.conceptNodeTree.length;i++){
      res += " ";
      res += _PrintNodeTreeCor(domainTree.conceptNodeTree[i],layer + 1);
    }
    return res;
  }
  String _PrintNodeTreeCor(ConceptNodeTree nodeTree,int layer){
    String res = "\r\n" + Layer2Indentation(layer)+"rootNode:"+nodeTree.name;

    res += "\r\n" + Layer2Indentation(layer+1)+ "childNode:";
    for(int i =0;i<nodeTree.children.length;i++){
      res += " ";
      res += _PrintNodeTreeCor(nodeTree.children[i],layer + 1);
    }
    return res;
  }
  String PrintDic(){
    String res = "";
    for(int i =0;i<domainNodeKey2ConceptTree.length;i++){
      res += "key:${domainNodeKey2ConceptTree.keys.toList()[i]} value:${domainNodeKey2ConceptTree.values.toList()[i]}";
    }
    return res;
  }
  static String Layer2Indentation(int layer,{int degree = 2}){

    return ' ' *(layer * degree);

  }

  Map<String, dynamic> toJson() {
    return {
      'rootTree': rootTree?.toJson(),
    };
  }

  static ConceptTreeModel fromJson(Map<String, dynamic> json) {
    return ConceptTreeModel(
      rootTree: json['rootTree'] != null ? DomainTree.fromJson(json['rootTree']) : null,
    );
  }

}
