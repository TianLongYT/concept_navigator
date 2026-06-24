import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:flutter/material.dart';

class AddressBarModel extends ChangeNotifier{
  //给地址栏用的数据结构，临时数据，不用储存。
  List<String> domainAddresses = ["root"];
  List<String> conceptAddresses = [];

  List<String> conceptAliasAddresses = [];
  List<ConceptNodeTree> conceptTreeAddress = [];

  void AddConceptAddress(ConceptNodeTree concept){
    conceptAddresses.add(concept.name);
    conceptAliasAddresses.add(concept.alias);
    conceptTreeAddress.add(concept);
  }
  void AddDomainAddress(DomainTree domain){
    domainAddresses.add(domain.name);
  }

  void updateAddressBar(NodeTree node, ConceptTreeModel treeModel) {
    domainAddresses.clear();
    conceptAddresses.clear();
    conceptAliasAddresses.clear();
    conceptTreeAddress.clear();

    if (node is DomainTree) {
      List<DomainTree> domains = [];
      DomainTree? temp = node;
      while (temp != null) {
        domains.insert(0, temp);
        temp = temp.parent;
      }
      for (var domain in domains) {AddDomainAddress(domain);}

    } else if (node is ConceptNodeTree) {
      DomainTree? domain = treeModel.GetDomainTree(node.domainKey);
      List<DomainTree> domains = [];
      DomainTree? tempD = domain;
      while (tempD != null) {
        domains.insert(0, tempD);
        tempD = tempD.parent;
      }
      for (var domain in domains) {AddDomainAddress(domain);}

      List<ConceptNodeTree> concepts = [];
      NodeTree? tempN = node;
      while(tempN!=null && tempN is ConceptNodeTree){
        concepts.insert(0,tempN);
        tempN = tempN.parent;
      }
      for (var concept in concepts) {AddConceptAddress(concept);}
    }
  }

}