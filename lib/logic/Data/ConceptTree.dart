

//域树。节点树。
import 'package:flutter/material.dart';

abstract class NodeTree{
  bool get IsInDomain;
  String name = "";
  String GetDomainKey();
  String GetDomainNodeKey();


}

class ConceptNodeTree extends NodeTree{
  List<ConceptNodeTree> children = [];
  String name = "NewConcept";
  String alias = "";
  String domainKey = "root";

  int? FindIndex(ConceptNodeTree child){
    for(int i =0;i<children.length;i++){
      if(children[i] == child) {
        return i;
      }
    }
    return null;
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
}

class DomainTree extends NodeTree{
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
  GenerateDic({String domainKey = "root"}){
    DomainTree? tree =GetDomainTree(domainKey); //rootTree?.Find(domain);
    print("findNull${tree}");
    if(tree == null) return;
    domainNodeKey2ConceptTree.clear();
    print("getTree${tree.GetDomainKey()}");
    _GenerateDicDomain(tree.GetDomainKey(),tree);
    notifyListeners();
  }
  _GenerateDicDomain(String domainKey,DomainTree domainTree){
    for(int i = 0;i<domainTree.conceptNodeTree.length;i++){
      _GenerateDicNode(domainKey, domainTree.conceptNodeTree[i]);
    }
    for(int i =0;i<domainTree.children.length;i++){
      _GenerateDicDomain(AppendDomainKey(domainKey, domainTree.children[i].name),domainTree.children[i]);
    }
  }
  _GenerateDicNode(String domainKey,ConceptNodeTree nodeTree){
    String key = GenerateDomainNodeKey(domainKey, nodeTree.name, nodeTree.alias);
    if(domainNodeKey2ConceptTree.containsKey(key)){
      return;
    }
    domainNodeKey2ConceptTree[key] = nodeTree;
    for(int i =0;i<nodeTree.children.length;i++){
      _GenerateDicNode(domainKey, nodeTree.children[i]);
    }
  }

  static const String AppendOperator = "/_/";//把_/设置为禁用组合。
  static const List<String> ErrorPatten = ["_/","/_","/_/"];
  static String GenerateDomainNodeKey(String domain,String name,String alias){
    return domain+AppendOperator+AppendOperator+name+AppendOperator+alias;
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

    for(int i = 0;i<tree.children.length;i++){
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
    return true;
  }
  bool AddNewConceptInDomain(String domainKey,ConceptNodeTree newTree){
    DomainTree? domain = GetDomainTree(domainKey);
    if(domain == null) {
      return false;
    }
    newTree.domainKey = domainKey;
    domain.conceptNodeTree.add(newTree);
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
    concept.children.add(newTree);
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

  String PrintTree(){
    if(rootTree == null){
      return "";
    }
    return _PrintDomainTreeCor(rootTree!,0);
  }
  String _PrintDomainTreeCor(DomainTree domainTree,int layer){

    String res =  "rootDomain:"+domainTree.name;
    res += "\r\n"+ Layer2Indentation(layer)+ "childDomain:";
    for(int i = 0; i< domainTree.children.length;i++){
      res +=" ";
      res += _PrintDomainTreeCor(domainTree.children[i],layer +1);
    }
    res += "\r\n" + Layer2Indentation(layer)+ "childNode:";
    for(int i =0;i<domainTree.conceptNodeTree.length;i++){
      res += " ";
      res += _PrintNodeTreeCor(domainTree.conceptNodeTree[i],layer + 1);
    }
    return res;
  }
  String _PrintNodeTreeCor(ConceptNodeTree nodeTree,int layer){
    String res = "rootNode:"+nodeTree.name;

    res += "\r\n" + Layer2Indentation(layer)+ "childNode:";
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

}