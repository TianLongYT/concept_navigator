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

}