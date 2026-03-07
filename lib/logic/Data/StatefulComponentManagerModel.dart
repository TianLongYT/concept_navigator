//Customizable可自定义的状态组件管理器公共数据。
//editingConceptPanel
import 'package:concept_navigator/MTools/MMath.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeAppearanceEditorComponent/NodeAppearanceEditorComponent.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeAppearanceEditorComponent/NodeGroupEditorComponent.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeDecorationEditorComponent/NodeDecorationEditorComponent.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeMoveComponent/NodeMoveComponent.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeRenameComponent/ConceptRenameComponent.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeRenameComponent/DomainRenameComponent.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeSearchComponent/NodeSearchComponent.dart';
import 'package:concept_navigator/logic/UI/EditPanel/StatefulComponent/StatefulComponents.dart';
import 'package:flutter/material.dart';


class StatefulComponentModel{
  String title;
  IconData icon;
  Widget child;

  StatefulComponentModel({
    required this.title,
    this.icon = Icons.rectangle_outlined,
    required this.child,
  });

  StatefulComponentModel.nodeMovingComponent():title = "节点移动",icon = Icons.move_down,child = ConceptMoveComponent();
  StatefulComponentModel.conceptRenamingComponent():title = "概念节点信息",icon = Icons.rectangle,child = ConceptRenameComponent();
  StatefulComponentModel.domainRenamingComponent(): title ="域节点信息",icon = Icons.rectangle_outlined,child = DomainRenameComponent();
  StatefulComponentModel.nodeAppearanceEditorComponent():title = "节点外观",icon = Icons.style,child = NodeAppearanceEditorComponent();
  StatefulComponentModel.nodeGroupEditorComponent():title = "节点组设置",icon = Icons.settings,child = NodeGroupEditorComponent();
  StatefulComponentModel.nodeSearchComponent():title = "节点查找",icon = Icons.settings,child = NodeSearchComponent();
  StatefulComponentModel.nodeDecorateComponent():title = "概念修饰词",icon = Icons.star_half_sharp,child = NodeDecorationEditorComponent();
}
class StatefulComponentManagerModel{
  List<StatefulComponentModel> components;
  //0正常状态，2集中状态。Focus。
  final List<int> _componentState;

  StatefulComponentManagerModel({
    required this.components,
    List<int>? componentState,

  }):_componentState = componentState ?? List.filled(components.length, 0);

  void setComponentState(int index,int state){
    _componentState[index] = state;
  }
  int getComponentState(int index) => _componentState[index];
  void swapComponent(int index1,int index2){
    MMath.swap(_componentState, index1, index2);
    MMath.swap(components, index1, index2);
  }
  bool containsState(int state){
    for(int cState in _componentState){
      if(cState == state){
        return true;
      }
    }
    return false;
  }
  void _addComponent(){

  }
  void _removeLastComponent(){

  }

}
class StatefulComponentManagerModelForProvider extends ChangeNotifier{

  StatefulComponentManagerModel editingConceptPanel;
  StatefulComponentManagerModel editingDomainPanel;
  StatefulComponentManagerModel editingParentConceptPanel;
  StatefulComponentManagerModel editingParentDomainPanel;

  StatefulComponentManagerModelForProvider({
    StatefulComponentManagerModel? editingConceptPanel,
    StatefulComponentManagerModel? editingDomainPanel,
    StatefulComponentManagerModel? editingParentConceptPanel,
    StatefulComponentManagerModel? editingParentDomainPanel,

  }):editingConceptPanel = editingConceptPanel?? StatefulComponentManagerModel(
      components: [
        StatefulComponentModel.conceptRenamingComponent(),
        StatefulComponentModel.nodeDecorateComponent(),
        StatefulComponentModel.nodeMovingComponent(),
        StatefulComponentModel.nodeAppearanceEditorComponent(),
      ]
  ),
        editingDomainPanel = editingDomainPanel?? StatefulComponentManagerModel(
            components: [
              StatefulComponentModel.domainRenamingComponent(),
              StatefulComponentModel.nodeAppearanceEditorComponent(),
              StatefulComponentModel.nodeMovingComponent(),
            ]
        ),
        editingParentConceptPanel = editingParentConceptPanel?? StatefulComponentManagerModel(
          components: [
            StatefulComponentModel.nodeSearchComponent(),
            StatefulComponentModel.nodeGroupEditorComponent(),

          ]
        ),

        editingParentDomainPanel = editingParentDomainPanel?? StatefulComponentManagerModel(
            components: [
              StatefulComponentModel.nodeSearchComponent(),
              StatefulComponentModel.nodeGroupEditorComponent(),
            ]
        )
  ;
  void setComponentState(StatefulComponentManagerModel model,int index,int state){
    model.setComponentState(index, state);
    notifyListeners();
  }

}
