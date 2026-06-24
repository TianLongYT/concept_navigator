import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ConceptDecoration.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeConflictCheck.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'UsePathAsAliasComponent.dart'; // 引入公共组件

class ConceptRenameComponent extends StatefulWidget {
  ConceptRenameComponent({super.key,});


  @override
  State<ConceptRenameComponent> createState() => _ConceptRenameComponentState();
}

class _ConceptRenameComponentState extends State<ConceptRenameComponent> {
  late SelectionViewData selection;
  final TextEditingController controller = TextEditingController();
  final TextEditingController aliasController = TextEditingController();

  // 用于追踪模型状态，检测撤销/重做
  String? _lastSyncName;
  String? _lastSyncAlias;

  bool _autoAlias = false;
  bool hasNoChange = true;
  bool hasError = false;

  String? nameError = null;
  String? aliasError = null;

  ConceptErrorCheck errorCheckHelper = ConceptErrorCheck();

  void nameErrorCheck(ConceptTreeModel treeModel,SelectionViewData selection,String textValue,String alias){
    if(! calHasChange(selection,textValue,alias)){
      setState(() {
        hasError = false;
        aliasError = null;
        nameError = null;
        hasNoChange = true;
      });
      return;
    }
    hasNoChange = false;
    String? errorText = errorCheckHelper.NameErrorCheck(treeModel, selection, textValue, alias);
    if(errorText != null){
      setState(() {
        hasError = true;
        nameError = errorText;
      });
    }
    else{
      setState(() {
        hasError = false;
        nameError = null;
        aliasError = null;
      });
    }
  }
  void aliasErrorCheck(ConceptTreeModel treeModel,SelectionViewData selection,String name,String textValue){
    if(! calHasChange(selection,name,textValue)){
      setState(() {
        hasError = false;
        aliasError = null;
        nameError = null;
        hasNoChange = true;
      });
      return;
    }
    hasNoChange=false;
    String? errorText = errorCheckHelper.AliasErrorCheck(treeModel, selection, name, textValue);
    if(errorText != null){
      setState(() {
        hasError = true;
        aliasError = errorText;
      });
    }
    else{
      setState(() {
        hasError = false;
        aliasError = null;
        nameError = null;
      });
    }
  }
  bool calHasChange(SelectionViewData selection,String name,String alias){
    return selection.SelectedConceptNode!.name != name || selection.SelectedConceptNode!.alias != alias || selection.SelectedConceptNode!.autoAlias != _autoAlias;
  }
  void OnSelectionChange(){
    if(!selection.IsSelectedConceptNode){
      return;
    }
    //初始化controller
    _syncFromModel();
  }
  @override
  void initState() {
    selection = context.read<SelectionViewData>();
    selection.state.addListener(OnSelectionChange);
    _syncFromModel();
    super.initState();
  }
  @override
  void dispose() {
    super.dispose();

    //selection = context.read<SelectionViewData>();
    selection.state.removeListener(OnSelectionChange);
  }

  void _syncFromModel() {
    final node = selection.SelectedConceptNode;
    if (node != null) {
      controller.text = node.name;
      aliasController.text = node.alias;
      _lastSyncName = node.name;
      _lastSyncAlias = node.alias;
      _autoAlias = node.autoAlias;
    }
  }

  @override
  Widget build(BuildContext context) {
    ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    GlobalStateModel globalState = context.read<GlobalStateModel>();
    AddressBarModel addressBar = context.read<AddressBarModel>();
    ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.read<ConceptTree2DomainDrawingDataDic>();
    ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();
    ConceptTree2ConceptDecorationDic decorationDic = context.watch<ConceptTree2ConceptDecorationDic>();
    CommandManagerForProvider commandManager = context.read<CommandManagerForProvider>();

    // 检测撤销/重做引起的模型变化
    final selectedNode = selection.SelectedConceptNode;
    if (selectedNode != null) {
      if (selectedNode.name != _lastSyncName || selectedNode.alias != _lastSyncAlias) {
        // 发现模型值与最后同步值不一致，说明发生了 Undo/Redo
        _lastSyncName = selectedNode.name;
        _lastSyncAlias = selectedNode.alias;

        // 更新输入框（仅在内容不同时更新，防止光标跳动）
        if (controller.text != selectedNode.name) {
          setState(() {
            controller.text = selectedNode.name;
          });
        }
        if (aliasController.text != selectedNode.alias) {
          setState(() {
            aliasController.text = selectedNode.alias;
          });
        }

        // 同步路径勾选状态
        _autoAlias = selectedNode.autoAlias;

        // 重置错误状态
        hasNoChange = true;
        hasError = false;
        nameError = null;
        aliasError = null;
      }
    }

    return Column(
      children: [
        //Center(child: Text("概念信息")),

        TextField(
          controller: controller,
          decoration: InputDecoration(
            //border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.dashboard_customize_rounded),
            hintText: "请输入概念名",
            labelText: "概念名",
            helperText: "概念名区别不同概念，同概念名的概念相同",
            errorText: nameError,

          ),
          //onTap: (){nameErrorCheck(treeModel,selection,controller.text,aliasController.text);},
          onChanged: (value){
            nameErrorCheck(treeModel, selection, value, aliasController.text);
          },
        ),

        UsePathAsAliasComponent(
          value: _autoAlias,
          onChanged: (bool value) {
            setState(() {
              _autoAlias = value;

              if (selectedNode != null) {
                // 计算预览的自动Alias。
                if(value){
                  aliasController.value = TextEditingValue(text: treeModel.getAutoAlias(selectedNode));
                }
                else{
                  aliasController.value = TextEditingValue(text: "");

                }
                //print("selectedNode alias ${selectedNode.alias},controller alias ${aliasController.text}");

              }
              aliasErrorCheck(treeModel, selection, controller.text, aliasController.text);
            });
          },
        ),

        TextField(
            controller: aliasController,
            enabled: !_autoAlias,
            decoration: InputDecoration(
              //border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.nest_cam_wired_stand),
              hintText: "请输入别名",
              labelText: "别名",
              helperText: "取不同别名以区别同名概念",
              errorText:aliasError,
            ),
            //onTap: (){nameErrorCheck(treeModel,selection,controller.text,aliasController.text);},
            onChanged: (value){
              aliasErrorCheck(treeModel, selection, controller.text, value);
            }

        ),
        if(true)
          OutlinedButton(
              onPressed:hasError||hasNoChange?null: (){
                bool hasSameConcept = false;
                bool chosenReference = false;

                ConceptNodeTree? selectedConceptNode = selection.SelectedConceptNode;
                if(selectedConceptNode == null){
                  throw Exception("当前节点没有选中ConceptNode");
                }
                String oldName = selection.SelectedConceptNode!.name;
                String oldAlias = selection.SelectedConceptNode!.alias;
                bool oldAutoAlias = selection.SelectedConceptNode!.autoAlias;

                String newName = controller.text;
                String newAlias = aliasController.text;
                bool newAutoAlias = _autoAlias;

                String oldDomainNodeKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, oldName, oldAlias);
                String newDomainNodeKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, newName, newAlias);

                if(!newAutoAlias && newAlias.isEmpty){
                  if(treeModel.ContainConceptNode(newDomainNodeKey)){
                    hasSameConcept = true;
                    if(selectedConceptNode.children.isNotEmpty){
                      chosenReference = true;
                    }
                  }
                }


                NodeDrawingData? lastDrawingData = nodeDrawingDataDic.GetNodeDrawingData(oldDomainNodeKey);
                if(lastDrawingData == null){
                  print("错误，概念编辑面板找不到修改前的渲染数据");
                  return;
                }
                NodeViewData? lastViewData = viewDataDic.GetNodeViewData(oldDomainNodeKey);
                if(lastViewData == null){
                  print("EditingConceptPanel找不到当前修改节点的NodeViewData");
                  return;
                }
                ConceptDecoration? lastDecoration = decorationDic.getDecoration(oldDomainNodeKey);
                bool hasDecoration = true;
                if(lastDecoration == null){
                  print("EditingConceptPanel找不到当前修改节点的ConceptDecoration");
                  hasDecoration = false;
                }

                List<ConceptNodeTree> childrenBackup = [];
                if(hasSameConcept){
                  childrenBackup = selectedConceptNode.children;
                }

                void doRename() {
                  selectedConceptNode.name = newName;
                  selectedConceptNode.alias = newAlias;
                  selectedConceptNode.autoAlias = newAutoAlias;
                  treeModel.GenerateDic();

                  // 获取最终生成的别名
                  String actualNewAlias = selectedConceptNode.alias;
                  String actualNewKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, newName, actualNewAlias);
                  aliasController.text = actualNewAlias;

                  if(hasSameConcept == false) {
                    NodeDrawingData newDrawingData = lastDrawingData.Clone();
                    newDrawingData.text = newName;

                    NodeViewData newViewData = lastViewData.Clone();
                    ConceptDecoration? newDecoration = lastDecoration?.clone();

                    nodeDrawingDataDic.putIfAbsent(actualNewKey, () => newDrawingData);
                    viewDataDic.putIfAbsent(actualNewKey, () => newViewData);
                    if(hasDecoration){
                      decorationDic.putIfAbsent(actualNewKey, () => newDecoration!);
                    }

                    if(!treeModel.ContainConceptNode(oldDomainNodeKey)) {
                      nodeDrawingDataDic.remove(oldDomainNodeKey);
                      viewDataDic.remove(oldDomainNodeKey);
                      if(hasDecoration){
                        decorationDic.remove(oldDomainNodeKey);
                      }
                    }
                  }
                  else{
                    if(chosenReference){
                      selectedConceptNode.children.clear();
                    }
                  }

                  selection.SelectAndFocusNode(
                    selectedNode: selectedConceptNode,
                    parent: selectedConceptNode.parent!,
                    globalState: globalState,
                    addressBar: addressBar,
                    treeModel: treeModel,
                    nodeDrawingDataDic: nodeDrawingDataDic,
                    domainDrawingDataDic: domainDrawingDataDic,
                    viewDrawingDataDic: viewDataDic,
                  );
                }

                void undoRename() {
                   selectedConceptNode.name = oldName;
                   selectedConceptNode.alias = oldAlias;
                   selectedConceptNode.autoAlias = oldAutoAlias;
                   treeModel.GenerateDic();

                   String actualNewAlias = oldAlias; // 撤回时使用旧别名
                   String actualNewKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, oldName, actualNewAlias);

                   if(hasSameConcept == false) {
                     nodeDrawingDataDic.putIfAbsent(oldDomainNodeKey, () => lastDrawingData);
                     viewDataDic.putIfAbsent(oldDomainNodeKey, () => lastViewData);
                     if(hasDecoration){
                       decorationDic.putIfAbsent(oldDomainNodeKey, () => lastDecoration!);
                     }

                     // 清理可能存在的重命名后的 Key
                     String renameAlias = newAlias;
                     String renameKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, newName, renameAlias);
                     if(!treeModel.ContainConceptNode(renameKey)) {
                       nodeDrawingDataDic.remove(renameKey);
                       viewDataDic.remove(renameKey);
                       if(hasDecoration){
                         decorationDic.remove(renameKey);
                       }
                     }
                   } else if(chosenReference) {
                     selectedConceptNode.children.addAll(childrenBackup);
                   }

                   selection.SelectAndFocusNode(
                     selectedNode: selectedConceptNode,
                     parent: selectedConceptNode.parent!,
                     globalState: globalState,
                     addressBar: addressBar,
                     treeModel: treeModel,
                     nodeDrawingDataDic: nodeDrawingDataDic,
                     domainDrawingDataDic: domainDrawingDataDic,
                     viewDrawingDataDic: viewDataDic,
                   );
                }

                doRename();
                commandManager.PushCommand(commandManager.editInstance, Command(
                  function: doRename,
                  undoFunction: undoRename,
                ));
              },
              child: Text("修改概念名")
          ),
      ],
    );
  }
}
