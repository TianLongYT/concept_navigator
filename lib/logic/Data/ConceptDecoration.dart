import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:flutter/material.dart';

/// 一个概念可以有多个修饰词。使用 Map 确保每个修饰词在当前概念中唯一。
class ConceptDecoration {
  // 存储状态：key 为修饰词内容，value 表示是否激活（非激活状态可用于提示或暂存）。
  Map<String, bool> modifiers;
  ConceptDecoration clone(){
    return ConceptDecoration(modifiers: modifiers.keys.toSet());
  }

  ConceptDecoration({Set<String>? modifiers})
      : modifiers = modifiers == null
            ? {}
            : {for (var item in modifiers) item: true};

  // 内部构造函数，用于数据持久化还原
  ConceptDecoration._(this.modifiers);

  void add(String modifier) => modifiers.putIfAbsent(modifier, () => true);
  void remove(String modifier) => modifiers.remove(modifier);

  void setEnable(String modifier,{bool enable = true}){
    if(modifiers.containsKey(modifier)){
      modifiers[modifier] = enable;
    }
  }

  void addAll(ConceptDecoration decoration) => modifiers.addAll(decoration.modifiers);

  ConceptDecoration difference(ConceptDecoration decoration) {
    return ConceptDecoration(
        modifiers: modifiers.keys.toSet().difference(decoration.modifiers.keys.toSet()));
  }

  Map<String, dynamic> toJson() {
    return {
      // 直接存储 Map，Map<String, bool> 是 JSON 原生支持的
      'modifiers': modifiers,
    };
  }

  factory ConceptDecoration.fromJson(Map<String, dynamic> json) {
    var raw = json['modifiers'];
    if (raw is Map) {
      // 还原 Map 状态
      return ConceptDecoration._(Map<String, bool>.from(raw));
    } else if (raw is List) {
      // 兼容旧版本的 List/Set 格式，默认全部设为激活
      return ConceptDecoration(modifiers: Set<String>.from(raw));
    }
    return ConceptDecoration();
  }

  @override
  String toString() {
    return 'ConceptDecoration{modifiers: $modifiers}';
  }
}

class ConceptTree2ConceptDecorationDic extends ChangeNotifier {
  Map<String, ConceptDecoration> _name2Decoration = {};

  Map<String, ConceptDecoration> get data => _name2Decoration;
  set data(Map<String, ConceptDecoration> value) {
    _name2Decoration = value;
    notifyListeners();
  }

  ConceptDecoration? getDecoration(String domainNodeKey) {
    return _name2Decoration[domainNodeKey];
  }
  ConceptDecoration putIfAbsent(String domainNodeKey,ConceptDecoration Function() ifAbsent ){
    return _name2Decoration.putIfAbsent(domainNodeKey, ifAbsent);
  }
  void remove(String domainNodeKey){
    _name2Decoration.remove(domainNodeKey);
  }

  void addModifier(String domainNodeKey, String modifier, ConceptTreeModel treeModel) {
    if (modifier.isEmpty) return;
    _name2Decoration.putIfAbsent(domainNodeKey, () => ConceptDecoration()).add(modifier);
    notifyListeners();
  }

  void removeModifier(String domainNodeKey, String modifier, ConceptTreeModel treeModel) {
    _name2Decoration[domainNodeKey]?.remove(modifier);

    // 清理空数据
    if (_name2Decoration[domainNodeKey]?.modifiers.isEmpty ?? false) {
      _name2Decoration.remove(domainNodeKey);
    }
    notifyListeners();
  }
  void setEnable(String domainNodeKey,String modifier,{bool enable = true}){
    _name2Decoration[domainNodeKey]?.setEnable(modifier,enable: enable);
  }

  /// 搜索提示：获取所有同名概念已使用的修饰词。
  Map<ConceptStatus, ConceptDecoration> getSearchHints(ConceptTreeModel treeModel) {
    Map<ConceptStatus, ConceptDecoration> hints = {};

    _name2Decoration.forEach((key, decoration) {
      try {
        var node = treeModel.GetConceptNodeByDic(key);
        var status = node?.getStatus(treeModel) ?? ConceptStatus.normal;
        if (status == ConceptStatus.template || status == ConceptStatus.templateReference) {
          hints.putIfAbsent(ConceptStatus.template, () => ConceptDecoration()).addAll(decoration);
        } else if (status == ConceptStatus.instance) {
          ConceptDecoration subDecoration = decoration;
          if (hints.containsKey(ConceptStatus.template)) {
            subDecoration = decoration.difference(hints[ConceptStatus.template]!);
          }
          hints.putIfAbsent(status, () => ConceptDecoration()).addAll(subDecoration);
        } else {
          // 记录 normal 等其他状态
          hints.putIfAbsent(status, () => ConceptDecoration()).addAll(decoration);
        }
      } catch (e) {
        // 忽略无法解析的旧 Key
      }
    });
    return hints;
  }

  /// 将实例（Variant）的修饰词保存到模板。
  void saveInstanceToTemplate(String instanceNodeKey, ConceptTreeModel treeModel) {
    var node = treeModel.GetConceptNodeByDic(instanceNodeKey);
    if (node == null || node.getStatus(treeModel) != ConceptStatus.instance) return;

    var template = treeModel.getFirstOccurrenceOfName(node.domainKey, node.name);
    if (template == null) return;

    var instanceDec = _name2Decoration[instanceNodeKey];
    if (instanceDec == null) return;

    String templateKey = template.GetDomainNodeKey();
    _name2Decoration.putIfAbsent(templateKey, () => ConceptDecoration()).addAll(instanceDec);

    notifyListeners();
  }

  /// 将实例的修饰词重置为模板内容。
  void restoreInstanceFromTemplate(String instanceNodeKey, ConceptTreeModel treeModel) {
    var node = treeModel.GetConceptNodeByDic(instanceNodeKey);
    if (node == null || node.getStatus(treeModel) != ConceptStatus.instance) return;

    var template = treeModel.getFirstOccurrenceOfName(node.domainKey, node.name);
    if (template == null) return;

    var templateDec = _name2Decoration[template.GetDomainNodeKey()];
    if (templateDec == null) {
      _name2Decoration.remove(instanceNodeKey);
    } else {
      _name2Decoration[instanceNodeKey] = ConceptDecoration.fromJson(templateDec.toJson());
    }
    notifyListeners();
  }

  // 辅助方法：生成整张表的 JSON (用于外部持久化)
  Map<String, dynamic> toJson() {
    return _name2Decoration.map((key, value) => MapEntry(key, value.toJson()));
  }

  // 辅助方法：从 JSON 还原整张表
  void fromJson(Map<String, dynamic> json) {
    _name2Decoration = json.map((key, value) => MapEntry(key, ConceptDecoration.fromJson(value)));
    notifyListeners();
  }

  void setData(Map<String, ConceptDecoration> newData, ConceptTreeModel treeModel) {
    _name2Decoration = newData;
    notifyListeners();
  }

  void clear() {
    _name2Decoration.clear();
    notifyListeners();
  }
  void repaint(){
    notifyListeners();
  }
  @override
  String toString() {
    String res = "";
    _name2Decoration.forEach((key, value) {
      res += "key:$key value:$value\n";
    });
    return res;
  }
}
