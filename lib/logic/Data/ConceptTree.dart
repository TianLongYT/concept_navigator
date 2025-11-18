

//域树。节点树。
import 'package:flutter/material.dart';

class ConceptNodeTree{
  List<ConceptNodeTree> children = [];
  String name = "NewConcept";
  String alias = "";

}

class DomainTree{
  List<DomainTree> children = [];
  List<ConceptNodeTree> conceptNodeTree = [];
  String name = "NewDomain";

  DomainTree? Find(String domain){
    if(name == domain)
      return this;
    else{
      DomainTree? result = null;
      for(int i = 0;i<children.length;i++){
        result = children[i].Find(domain);
        if(result != null)
          return result;
      }
      return result;
    }

  }
}

class ConceptTreeModel extends ChangeNotifier{
  DomainTree? rootTree;//从文件读取。
  //显示字典。
  Map<String,ConceptNodeTree> domainNodeKey2ConceptTree = {};
  ConceptTreeModel({required this.rootTree}){GenerateDic("root");}

  GenerateDic(String domain){
    DomainTree? tree = rootTree?.Find(domain);
    if(tree == null) return;
    _GenerateDicDomain(tree);

  }
  _GenerateDicDomain(DomainTree domainTree){
    for(int i = 0;i<domainTree.conceptNodeTree.length;i++){
      _GenerateDicNode(domainTree.name, domainTree.conceptNodeTree[i]);
    }
    for(int i =0;i<domainTree.children.length;i++){
      _GenerateDicDomain(domainTree.children[i]);
    }
  }
  _GenerateDicNode(String domain,ConceptNodeTree nodeTree){
    String key = GenerateDomainNodeKey(domain, nodeTree.name, nodeTree.alias);
    if(domainNodeKey2ConceptTree.containsKey(key)){
      return;
    }
    domainNodeKey2ConceptTree[key] = nodeTree;
    for(int i =0;i<nodeTree.children.length;i++){
      _GenerateDicNode(domain, nodeTree.children[i]);
    }
  }
  static String GenerateDomainNodeKey(String domain,String name,String alias){
    return domain+name+alias;
  }

  ConceptNodeTree? GetConceptNodeByDic(String domainNodeKey){
    if(domainNodeKey2ConceptTree.containsKey(domainNodeKey)){
      return domainNodeKey2ConceptTree[domainNodeKey];
    }
    return null;

  }
}