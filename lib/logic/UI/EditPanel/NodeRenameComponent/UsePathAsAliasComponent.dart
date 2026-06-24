import 'dart:io';

import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A reusable widget for the "Use path as alias" checkbox.
class UsePathAsAliasComponent extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const UsePathAsAliasComponent({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: const Text("自动获取别名", style: TextStyle(fontSize: 14)),
      value: value,
      onChanged: (bool? newValue) {
        onChanged(newValue ?? false);
      },
      controlAffinity: ListTileControlAffinity.leading, // Checkbox on the left
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}

/// Calculates the full path of the current view's parent node.
String getCurrentViewNodePath(SelectionViewData selection, ConceptTreeModel treeModel) {
  String separator = kIsWeb ? "/" : Platform.pathSeparator;
  //String separator = ConceptTreeModel.AppendOperator;
  
  // Start with the domain path,
  List<String> domainParts = ConceptTreeModel.SplitDomainKey(selection.currentDomain);

  List<String> usefulDomainParts = domainParts.isNotEmpty ? domainParts.sublist(0) : [];
  
  List<String> pathParts = [...usefulDomainParts];

  // If we are inside a concept, append its name and all parent concept names
  if (!selection.IsInDomain) {
    ConceptNodeTree? parent = treeModel.GetConceptNodeByDic(selection.CurrentDomainNodeKey);
    List<String> conceptPathParts = [];
    while (parent != null) {
      conceptPathParts.insert(0, parent.name);
      // Traverse up to find all parent concepts until we hit a domain
      parent = parent.parent is ConceptNodeTree ? parent.parent as ConceptNodeTree : null;
    }
    pathParts.addAll(conceptPathParts);
  }
  
  if (pathParts.isEmpty) return "";
  // Return the path joined by separators, with a trailing separator as requested.
  return pathParts.join(separator) + separator;
}
