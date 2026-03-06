import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/AddressBarModel.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeConflictCheck.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DomainRenameComponent extends StatefulWidget {
  const DomainRenameComponent({super.key});

  @override
  State<DomainRenameComponent> createState() => _DomainRenameComponentState();
}

class _DomainRenameComponentState extends State<DomainRenameComponent> {
  late SelectionViewData selection;
  final TextEditingController controller = TextEditingController();
  bool hasNoChange = true;
  bool hasError = false;

  String? nameError = null;
  DomainErrorCheck errorCheckHelper = DomainErrorCheck();

  void nameErrorCheck(ConceptTreeModel treeModel,SelectionViewData selection,String textValue){
    if(! calHasChange(selection,textValue)){
      setState(() {
        hasError = false;
        nameError = null;
        hasNoChange = true;
      });
      return;
    }
    hasNoChange = false;
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
  bool calHasChange(SelectionViewData selection,String name){
    return selection.SelectedDomain!.name != name;
  }

  Map<K2, V> transformKeys<K1, K2, V>(
      Map<K1, V> map,
      K2 Function(K1) transform,
      ) {
    return {
      for (var entry in map.entries)
        transform(entry.key): entry.value
    };
  }
  @override
  void initState() {
    selection = context.read<SelectionViewData>();
    selection.state.addListener((){
      if(!selection.IsSelectedDomain){
        return;
      }
      //初始化controller
      controller.text = selection.SelectedDomain!.name;
    });
    controller.text = selection.SelectedDomain!.name;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    //GlobalStateModel stateModel = context.watch<GlobalStateModel>();
    ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    GlobalStateModel globalState = context.read<GlobalStateModel>();
    AddressBarModel addressBar = context.read<AddressBarModel>();
    ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();
    CommandManagerForProvider commandManager = context.read<CommandManagerForProvider>();

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Column(
        children: [
          Center(child: Text("域信息")),

          TextField(
            controller: controller,
            decoration: InputDecoration(
              //border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.dashboard_customize_rounded),
              hintText: "请输入域名",
              labelText: "域名",
              //helperText: "通过域来划分",
              errorText: nameError,

            ),
            onChanged: (value){
              //风险判断。
              //设置节点名和别名。
              //设置渲染物体。
              nameErrorCheck(treeModel, selection, value);
            },
          )
          ,

          if(true)
            OutlinedButton(
                onPressed:hasError||hasNoChange?null: (){
                  //bool hasSameDomain = false;
                  bool needChoseChildren = false;

                  DomainTree? selectedDomain = selection.SelectedDomain;
                  if(selectedDomain == null){
                    throw Exception("当前没有选中DomainTree");
                  }

                  String oldName = selectedDomain.name;
                  String newName = controller.text;

                  // 初始路径
                  String oldDomainNodeKey = selectedDomain.GetDomainNodeKey();

                  void doRename(String targetName, String fromPath, String toName){
                    //设置节点名和别名。
                    selectedDomain.name = targetName;

                    treeModel.GenerateDic();

                    DomainDrawingData? lastDrawingData = domainDrawingDataDic.GetDomainDrawingData(fromPath);
                    if(lastDrawingData == null){
                      print("错误，概念编辑面板找不到修改前的渲染数据");
                      return;
                    }
                    lastDrawingData.text = targetName;

                    //遍历这个域内的所有子树，并且修改Dic。
                    print("交换domainDrawingData");
                    domainDrawingDataDic.ChangeKeys((key){
                      String? res = ConceptTreeModel.replaceDomainKey(key, fromPath, toName);
                      return res?? key;
                    });

                    print("交换nodeDrawingData");
                    nodeDrawingDataDic.ChangeKeys((key){
                      String? res = ConceptTreeModel.replaceDomainKey(key, fromPath, toName);
                      return res?? key;
                    });

                    print("交换viewData");
                    viewDataDic.ChangeKeys((key){
                      String? res = ConceptTreeModel.replaceDomainKey(key, fromPath, toName);
                      return res?? key;
                    });

                    // 重新聚焦
                    selection.SelectAndFocusNode(
                      selectedNode: selectedDomain,
                      parent: selectedDomain.parent!,
                      globalState: globalState,
                      addressBar: addressBar,
                      treeModel: treeModel,
                      nodeDrawingDataDic: nodeDrawingDataDic,
                      domainDrawingDataDic: domainDrawingDataDic,
                      viewDrawingDataDic: viewDataDic,
                    );
                  }

                  // 计算更名后的路径以便重做/撤回
                  String newDomainNodeKey = ConceptTreeModel.replaceDomainKey(oldDomainNodeKey, oldDomainNodeKey, newName)!;

                  // 执行
                  doRename(newName, oldDomainNodeKey, newName);

                  // 入栈
                  commandManager.PushCommand(commandManager.editInstance, Command(
                    function: () => doRename(newName, oldDomainNodeKey, newName),
                    undoFunction: () => doRename(oldName, newDomainNodeKey, oldName),
                  ));

                  /*
                  //风险判断。
                  String domainNodeKey = selection.SelectedDomain!.GetDomainNodeKey();

                  DomainDrawingData? lastDrawingData = domainDrawingDataDic.GetDomainDrawingData(domainNodeKey);
                  if(lastDrawingData == null){
                    print("错误，概念编辑面板找不到修改前的渲染数据");
                    return;
                  }
                  NodeViewData? lastViewData = viewDataDic.GetNodeViewData(domainNodeKey);
                  if(lastViewData == null){
                    print("EditingConceptPanel找不到当前修改节点的NodeViewData");
                    return;
                  }

                  //设置渲染物体。
                  DomainDrawingData newDrawingData = lastDrawingData.Clone();
                  newDrawingData.text = controller.text;

                  NodeViewData newViewData = lastViewData.Clone();
                  domainDrawingDataDic.putIfAbsent(newDomainNodeKey, ()=>newDrawingData);
                  viewDataDic.putIfAbsent(newDomainNodeKey, ()=>newViewData);

                  treeModel.GenerateDic();

                  domainDrawingDataDic.remove(domainNodeKey);
                  viewDataDic.remove(domainNodeKey);
                  */

                },
                child: Text("修改域名")
            ),


        ],
      ),
    );
  }
}
