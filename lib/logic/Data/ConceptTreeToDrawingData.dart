
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:flutter/material.dart';

class ConceptTree2NodeDrawingDataDic extends ChangeNotifier{
  Map<String,NodeDrawingData> _name2NodeDrawingData = {"root":NodeDrawingData(nodeAppearance: NodeAppearance())..AddNodeDrawingData()};
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

}
class ConceptTree2NodeViewDataDic extends ChangeNotifier{
  Map<String,NodeViewData> _name2NodeViewData = {"root":NodeViewData()};
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
}
// class ConceptTree2DomainDrawingDataDic extends ChangeNotifier{
//   Map<String,DomainDrawingData> name2DomainDrawingData = {};
// }