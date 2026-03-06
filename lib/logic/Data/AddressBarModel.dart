import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:flutter/material.dart';

class AddressBarModel extends ChangeNotifier{
  //给地址栏用的数据结构，临时数据，不用储存。
  List<String> domainAddresses = ["root"];
  List<String> conceptAddresses = [];

  List<String> conceptAliasAddresses = [];

  void AddConceptAddress(ConceptNodeTree concept){
    conceptAddresses.add(concept.name);
    conceptAliasAddresses.add(concept.alias);
  }
  void AddDomainAddress(DomainTree domain){
    domainAddresses.add(domain.name);
  }

  void updateAddressBar(NodeTree node, ConceptTreeModel treeModel) {
    domainAddresses.clear();
    conceptAddresses.clear();
    conceptAliasAddresses.clear();

    if (node is DomainTree) {
      List<String> domains = [];
      DomainTree? temp = node;
      while (temp != null) {
        domains.insert(0, temp.name);
        temp = temp.parent;
      }
      domainAddresses = domains;
    } else if (node is ConceptNodeTree) {
      DomainTree? domain = treeModel.GetDomainTree(node.domainKey);
      List<String> domains = [];
      DomainTree? tempD = domain;
      while (tempD != null) {
        domains.insert(0, tempD.name);
        tempD = tempD.parent;
      }
      domainAddresses = domains;
      NodeTree? tempN = node;
      while(tempN!=null && tempN is ConceptNodeTree){
        AddConceptAddress(tempN);
        tempN = tempN.parent;
      }
    }
  }

}