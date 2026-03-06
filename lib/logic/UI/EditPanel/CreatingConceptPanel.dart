import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeConflictCheck.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodeInfo/GetNodePosition.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreatingConceptPanel extends StatefulWidget {
  const CreatingConceptPanel({super.key});

  @override
  State<CreatingConceptPanel> createState() => _CreatingConceptPanelState();
}

class _CreatingConceptPanelState extends State<CreatingConceptPanel> {
  //final String preText = ;
  final TextEditingController controller = TextEditingController.fromValue(TextEditingValue(
    //预文本。
    // text: "",
    // selection: TextSelection.fromPosition(TextPosition(
    //   affinity: TextAffinity.downstream,
    //   offset: "preText".length,
    // ))
  ));
  bool CheckEmpty(String value){
    return value.length == 0;
  }



  bool hasError = true;

  String? nameError = "概念名不能为空";

  String? aliasError = null;

  final TextEditingController aliasController = TextEditingController();

  ConceptErrorCheck errorCheckHelper = ConceptErrorCheck();


  void nameErrorCheck(ConceptTreeModel treeModel,SelectionViewData selection,String textValue,String alias){
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
  void aliasErrorCheck(ConceptTreeModel treeModel,SelectionViewData selection,String textValue,String alias){
    String? errorText = errorCheckHelper.AliasErrorCheck(treeModel, selection, textValue, alias);
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



  @override
  Widget build(BuildContext context) {

    GlobalStateModel stateModel = context.watch<GlobalStateModel>();
    SelectionViewData selection = context.watch<SelectionViewData>();
    ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.read<ConceptTree2NodeDrawingDataDic>();
    ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();
    CommandManagerForProvider commandManager = context.read<CommandManagerForProvider>();
    AddressBarModel addressBar = context.read<AddressBarModel>();


    FocusNodeHelper focusNodeHelper = FocusNodeHelper.lateInit(context);




    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(

        children: [
          Text("新建概念"),

          TextField(

            controller: controller,
            decoration: InputDecoration(
              //border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.dashboard_customize_rounded),
              hintText: "请输入概念名",
              labelText: "请输入概念名",
              helperText: "概念名区别不同概念，同概念名的概念相同",
              errorText: nameError,

            ),
            //onTap: (){nameErrorCheck(treeModel,selection,controller.text,aliasController.text);},
            onChanged: (value){nameErrorCheck(treeModel, selection, value, aliasController.text);},
          ),
          TextField(
            controller: aliasController,
            decoration: InputDecoration(
              //border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.nest_cam_wired_stand),
              hintText: "请输入别名",
              labelText: "概念的别名,默认为空",
              helperText: "取不同别名以区别同名概念",
              errorText:aliasError,
            ),
            //onTap: (){nameErrorCheck(treeModel,selection,controller.text,aliasController.text);},
            onChanged: (value){
              aliasErrorCheck(treeModel, selection, controller.text, value);
            }
            ,
          ),
          OutlinedButton(onPressed:hasError?null: (){


            ConceptNodeTree node2Add = ConceptNodeTree()..name = controller.text..alias = aliasController.text;
            NodeDrawingData newDrawingData =NodeDrawingData(nodeAppearance: NodeAppearance())..text = controller.text;
            NodeViewData newViewData = NodeViewData();
            String newKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, controller.text, aliasController.text);
            final String parentKey = selection.IsInDomain ? selection.currentDomain : selection.CurrentDomainNodeKey;
            final bool isParentDomain = selection.IsInDomain;

            void doCreate() {
              if (isParentDomain) {
                if(!treeModel.AddNewConceptInDomain(parentKey, node2Add)){
                  throw Exception("错误：找不到当前界面的domainTree");
                  return;
                }
                domainDrawingDataDic.GetDomainDrawingData(parentKey)?.AddNodeDrawingData();
              } else {
                if(!treeModel.AddNewConceptInConceptNode(parentKey, node2Add)){
                  throw Exception("错误：找不到当前界面的nodeTree");
                  return;
                }
                nodeDrawingDataDic.GetNodeDrawingData(parentKey)?.AddNodeDrawingData();
              }
              nodeDrawingDataDic.putIfAbsent(newKey, () => newDrawingData);
              viewDataDic.putIfAbsent(newKey, () => newViewData);

              selection.SelectAndFocusNode(
                  selectedNode: node2Add,
                  parent: node2Add.parent!,
                  globalState: stateModel,
                  addressBar: addressBar,
                  treeModel: treeModel,
                  nodeDrawingDataDic: nodeDrawingDataDic,
                  domainDrawingDataDic: domainDrawingDataDic,
                  viewDrawingDataDic: viewDataDic,
              );

            }

            void undoCreate() {
              if (isParentDomain) {
                treeModel.RemoveConceptFromDomain(parentKey, node2Add);
                domainDrawingDataDic.GetDomainDrawingData(parentKey)?.RemoveAtNodeDrawingDataSqueeze(
                    treeModel.GetDomainTree(parentKey)!.conceptNodeTree.length // 此时节点已删，需注意索引
                );
              } else {
                treeModel.RemoveConceptFromConcept(parentKey, node2Add);
                nodeDrawingDataDic.GetNodeDrawingData(parentKey)?.RemoveAtNodeDrawingDataSqueeze(
                    treeModel.GetConceptNodeByDic(parentKey)!.children.length
                );
              }
              if(!treeModel.ContainConceptNode(newKey)){
                nodeDrawingDataDic.remove(newKey);
                viewDataDic.remove(newKey);
              }
              selection.CancelSelectionAndJumpOutParent(
                selectedNode: node2Add,
                parent: node2Add.parent!,
                globalState: stateModel,
                addressBar: addressBar,
                treeModel: treeModel,
                nodeDrawingDataDic: nodeDrawingDataDic,
                domainDrawingDataDic: domainDrawingDataDic,
                viewDrawingDataDic: viewDataDic,
              );
              //selection.CancelSelectionAndJumpOutParent(node2Add.parent!, addressBar, stateModel, treeModel);
            }

            // 执行并存入指令栈
            doCreate();
            commandManager.PushCommand(commandManager.editInstance, Command(
              function: doCreate,
              undoFunction: undoCreate,
            ));

            controller.clear();
            aliasController.clear();

            //一开始就进行字符判断。更新状态。
            nameErrorCheck(treeModel, selection, "", "");
            aliasErrorCheck(treeModel, selection, "", "");

            //选中新创建的节点。
            stateModel.State = GlobalState.editingConcept;
            selection.SelectedConceptNode = node2Add;

            //聚焦对象。
            Size allSize = newDrawingData.nodeAppearance.nodeSize * newDrawingData.nodeAppearance.emptySize;
            focusNodeHelper.Init(selection.IsInDomain, selection.currentDomain, selection.CurrentDomainNodeKey,allSize );
            focusNodeHelper.FocusNode(node2Add, null);

          }, child: Text("新建概念")),
        ],
      ),
    );
  }
}
