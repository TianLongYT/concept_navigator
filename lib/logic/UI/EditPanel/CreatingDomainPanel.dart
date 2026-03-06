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

class CreatingDomainPanel extends StatefulWidget {
  CreatingDomainPanel({super.key});

  @override
  State<CreatingDomainPanel> createState() => _CreatingDomainPanelState();
}

class _CreatingDomainPanelState extends State<CreatingDomainPanel> {
  bool hasError = true;

  String? nameError = "域名不能为空";

  final TextEditingController controller = TextEditingController();

  DomainErrorCheck errorCheckHelper = DomainErrorCheck();


  void nameErrorCheck(ConceptTreeModel treeModel,SelectionViewData selection,String textValue){
    String? errorText = errorCheckHelper.NameErrorCheck(treeModel, selection, textValue);
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
      });
    }
  }
  //
  // void _CheckTextField(String value) {
  //   if (value.length == 0) {
  //     hasError = true;
  //     setState(() {
  //       nameError = "域名不能为空";
  //     });
  //   }
  //   else if (CheckContainList(value, ConceptTreeModel.ErrorPatten)) {
  //     hasError = true;
  //     setState(() {
  //       nameError = "命名中不能连续出现'/'和'_'字符";
  //     });
  //   }//同一层级中不能出现相同的域。
  //
  //   else {
  //     hasError = false;
  //
  //     setState(() {
  //       nameError = null;
  //     });
  //   }
  // }
  // bool CheckContain(String input,String pattern){
  //   return RegExp(pattern).hasMatch(input);
  // }
  //
  // bool CheckContainList(String input,List<String> patterns){
  //   bool res = false;
  //   patterns.forEach((element){
  //     if(CheckContain(input, element)){
  //       res = true;
  //     }
  //   });
  //   return res;
  // }
  @override
  Widget build(BuildContext context) {
    GlobalStateModel stateModel = context.watch<GlobalStateModel>();
    SelectionViewData selection = context.watch<SelectionViewData>();
    ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.read<ConceptTree2NodeDrawingDataDic>();
    ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();
    AddressBarModel addressBar = context.read<AddressBarModel>();

    CommandManagerForProvider commandManager = context.read<CommandManagerForProvider>();

    FocusNodeHelper focusNodeHelper = FocusNodeHelper.lateInit(context);

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(

        children: [
          Text("新建域"),

          TextField(

            controller: controller,
            decoration: InputDecoration(
              //border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.dashboard_customize_rounded),
              hintText: "请输入域名",
              labelText: "请输入域名",
              helperText: "使用域来给概念分类，不同域的概念无关",
              errorText: nameError,

            ),
            //onTap: (){_CheckTextField(controller.text);},
            onChanged:(value){
              nameErrorCheck(treeModel, selection, value);
            },
          ),

          OutlinedButton(onPressed:hasError?null: (){
            if(hasError)
              return;

            DomainTree domain2Add = DomainTree()..name = controller.text;
            DomainDrawingData newDrawingData = DomainDrawingData(nodeAppearance: NodeAppearance())..text = controller.text;
            NodeViewData newViewData = NodeViewData();
            String newKey = ConceptTreeModel.AppendDomainKey(selection.currentDomain, domain2Add.name);
            final String parentKey =  selection.currentDomain;
            void doCreate() {
              treeModel.AddNewDomainInDomain(parentKey, domain2Add);
              domainDrawingDataDic.GetDomainDrawingData(parentKey)?.AddDomainDrawingData();
              domainDrawingDataDic.putIfAbsent(newKey, () => newDrawingData);
              viewDataDic.putIfAbsent(newKey, () => newViewData);

              selection.SelectAndFocusNode(
                selectedNode: domain2Add,
                parent: domain2Add.parent!,
                globalState: stateModel,
                addressBar: addressBar,
                treeModel: treeModel,
                nodeDrawingDataDic: nodeDrawingDataDic,
                domainDrawingDataDic: domainDrawingDataDic,
                viewDrawingDataDic: viewDataDic,
              );
            }

            void undoCreate() {
              treeModel.RemoveDomainFromDomain(parentKey, domain2Add);
              domainDrawingDataDic.GetDomainDrawingData(parentKey)?.RemoveAtDomainDrawingDataSqueeze(
                  treeModel.GetDomainTree(parentKey)!.children.length
              );
              domainDrawingDataDic.remove(newKey);
              viewDataDic.remove(newKey);

              selection.CancelSelectionAndJumpOutParent(
                selectedNode: domain2Add,
                parent: domain2Add.parent!,
                globalState: stateModel,
                addressBar: addressBar,
                treeModel: treeModel,
                nodeDrawingDataDic: nodeDrawingDataDic,
                domainDrawingDataDic: domainDrawingDataDic,
                viewDrawingDataDic: viewDataDic,
              );
              //selection.CancelSelectionAndJumpOutParent(domain2Add.parent!, addressBar, stateModel, treeModel);

            }

            doCreate();
            commandManager.PushCommand(commandManager.editInstance, Command(
              function: doCreate,
              undoFunction: undoCreate,
            ));
            // treeModel.AddNewDomainInDomain(selection.currentDomain, domain2Add);
            //
            //
            // domainDrawingDataDic.GetDomainDrawingData(selection.currentDomain)?.AddDomainDrawingData();
            // domainDrawingDataDic.putIfAbsent(ConceptTreeModel.AppendDomainKey( selection.currentDomain, domain2Add.name), ()=>
            // newDrawingData);
            // viewDataDic.putIfAbsent(ConceptTreeModel.AppendDomainKey( selection.currentDomain, domain2Add.name), ()=>NodeViewData());

            controller.clear();

            //一开始就进行字符判断。
            nameErrorCheck(treeModel, selection, "");
            //
            // //选中新创建的节点。
            // stateModel.State = GlobalState.editingDomain;
            // selection.SelectedDomain = domain2Add;
            // //聚焦新节点
            // Size allSize = newDrawingData.nodeAppearance.nodeSize * newDrawingData.nodeAppearance.emptySize;
            // focusNodeHelper.Init(selection.IsInDomain, selection.currentDomain, selection.CurrentDomainNodeKey, allSize);
            // focusNodeHelper.FocusNode(null, domain2Add);

          }, child: Text("新建域")),
        ],
      ),
    );
  }
}
