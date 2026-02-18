
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:flutter/material.dart';

class ConceptTree2NodeDrawingDataDic extends ChangeNotifier{
  Map<String,NodeDrawingData> _name2NodeDrawingData = {};
  void ChangeKeys(String Function(String) rule){
    _name2NodeDrawingData = {
      for(var entry in _name2NodeDrawingData.entries)
        rule(entry.key) : entry.value
    };
    notifyListeners();
  }
  NodeDrawingData? GetNodeDrawingData(String domainNodeNameKey){
    if(_name2NodeDrawingData.containsKey(domainNodeNameKey)){
      return _name2NodeDrawingData[domainNodeNameKey];
    }

    return null;
  }
  putIfAbsent(String key , NodeDrawingData Function() ifAbsent){
    _name2NodeDrawingData.putIfAbsent(key, ifAbsent);
    notifyListeners();
  }
  remove(String key){
    _name2NodeDrawingData.remove(key);
    notifyListeners();
  }
  repaint()=>notifyListeners();
  @override
  String toString(){
    String res = "";
    for(int i =0;i<_name2NodeDrawingData.length;i++){
      res += "key:${_name2NodeDrawingData.keys.toList()[i]} value:${_name2NodeDrawingData.values.toList()[i]}";
    }
        return res;
  }
}

class ConceptTree2DomainDrawingDataDic extends ChangeNotifier{
  Map<String,DomainDrawingData> _name2DomainDrawingData = {"root":DomainDrawingData(nodeAppearance: NodeAppearance())};
  void ChangeKeys(String Function(String) rule){
    _name2DomainDrawingData = {
      for(var entry in _name2DomainDrawingData.entries)
        rule(entry.key) : entry.value
    };
    notifyListeners();
  }
  DomainDrawingData? GetDomainDrawingData(String domainNameKey){
    if(_name2DomainDrawingData.containsKey(domainNameKey)){
      return _name2DomainDrawingData[domainNameKey];
    }

    return null;
  }
  putIfAbsent(String key , DomainDrawingData Function() ifAbsent){
    _name2DomainDrawingData.putIfAbsent(key, ifAbsent);
    notifyListeners();
  }
  remove(String key){
    _name2DomainDrawingData.remove(key);
    notifyListeners();
  }

}
class ConceptTree2NodeViewDataDic extends ChangeNotifier{
  Map<String,NodeViewData> _name2NodeViewData = {"root":NodeViewData()};
  void ChangeKeys(String Function(String) rule){
    _name2NodeViewData = {
      for(var entry in _name2NodeViewData.entries)
        rule(entry.key) : entry.value
    };
    notifyListeners();
  }
  NodeViewData? GetNodeViewData(String domainNodeNameKey){
    if(_name2NodeViewData.containsKey(domainNodeNameKey)){
      return _name2NodeViewData[domainNodeNameKey];
    }
    return null;
  }
  putIfAbsent(String key , NodeViewData Function() ifAbsent){
    _name2NodeViewData.putIfAbsent(key, ifAbsent);
    notifyListeners();
  }
  remove(String key){
    _name2NodeViewData.remove(key);
    notifyListeners();
  }
  repaint(){
    notifyListeners();
  }
}
// class ConceptTree2DomainDrawingDataDic extends ChangeNotifier{
//   Map<String,DomainDrawingData> name2DomainDrawingData = {};
// }