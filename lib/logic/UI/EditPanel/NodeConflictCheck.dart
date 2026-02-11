import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';

// abstract class NodeErrorCheck{
//   String? NameErrorCheck();
// }
class StringConflictCheck{
  static bool CheckContain(String input,String pattern){
    return RegExp(pattern).hasMatch(input);
  }

  static bool CheckContainList(String input,List<String> patterns){
    bool res = false;
    patterns.forEach((element){
      if(CheckContain(input, element)){
        res = true;
      }
    });
    return res;
  }
}
class ConceptErrorCheck{
  //命名规范。概念名，不能空值，不能非法字符。别名不能非法字符。
  //定义规范。同一域中，不能出现概念名和别名都相同的概念。


  String? NameErrorCheck(ConceptTreeModel treeModel,SelectionViewData selection,String textValue,String alias){
    if(textValue.length == 0){
      return "概念名不能为空";
    }
    if(StringConflictCheck.CheckContainList(textValue, ConceptTreeModel.ErrorPatten)){
      return "命名中不能连续出现'/'和'_'字符";
    }
    if(treeModel.ContainConceptNode(ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, textValue, alias))){
      return "同一域内不允许出现名字和别名都相同的概念";
    }
    return null;
  }
  String? AliasErrorCheck(ConceptTreeModel treeModel,SelectionViewData selection,String name,String textValue){
    if(StringConflictCheck.CheckContainList(name, ConceptTreeModel.ErrorPatten)){
      return "命名中不能连续出现'/'和'_'字符";
    }
    if(treeModel.ContainConceptNode(ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, name, textValue))){
      return "同一域内不允许出现名字和别名都相同的概念";
    }
    return null;
  }
}
class DomainErrorCheck{
  //命名规范。不能为空值，不能含有非法字符。
  //定义规范。同层级不能出现同名域。"域名不能为空"

  String? NameErrorCheck(ConceptTreeModel treeModel,SelectionViewData selection,String textValue) {
    if(textValue.length == 0){
      return "概念名不能为空";
    }
    if(StringConflictCheck.CheckContainList(textValue, ConceptTreeModel.ErrorPatten)){
      return "命名中不能连续出现'/'和'_'字符";
    }
    //同层级不能出现相同域。

    DomainTree? curDomain = treeModel.GetDomainTree(selection.currentDomain);
    if(curDomain == null){
      throw Exception("DomainErrorCheck <- creatingPanel/EditPanel 没找到当前主界面的域树");
    }

    for(int i = 0;i<curDomain.children.length;i++){
      if(textValue == curDomain.children[i].name){
        return "同一层级不能出现相同的域";
      }
    }
    return null;

  }

}