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

class ConceptRenameComponent extends StatefulWidget {
  ConceptRenameComponent({super.key,});


  @override
  State<ConceptRenameComponent> createState() => _ConceptRenameComponentState();
}

class _ConceptRenameComponentState extends State<ConceptRenameComponent> {
  late SelectionViewData selection;
  final TextEditingController controller = TextEditingController();

  final TextEditingController aliasController = TextEditingController();

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
    return selection.SelectedConceptNode!.name != name || selection.SelectedConceptNode!.alias != alias;
  }
  @override
  void initState() {
    selection = context.read<SelectionViewData>();
    selection.state.addListener((){
      if(!selection.IsSelectedConceptNode){
        return;
      }
      //初始化controller
      controller.text = selection.SelectedConceptNode!.name;
      aliasController.text = selection.SelectedConceptNode!.alias;
    });
    controller.text = selection.SelectedConceptNode!.name;
    aliasController.text = selection.SelectedConceptNode!.alias;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    GlobalStateModel globalState = context.read<GlobalStateModel>();
    AddressBarModel addressBar = context.read<AddressBarModel>();
    ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.read<ConceptTree2DomainDrawingDataDic>();
    ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();
    CommandManagerForProvider commandManager = context.read<CommandManagerForProvider>();

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
          // onChanged: (value){
          //   //风险判断。
          //   //设置节点名和别名。
          //   //设置渲染物体.
          // },
        )
        ,
        TextField(
            controller: aliasController,
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
                String newName = controller.text;
                String newAlias = aliasController.text;
                String oldDomainNodeKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, oldName, oldAlias);
                String newDomainNodeKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, newName, newAlias);

                //风险判断。
                //新命名的概念名已经存在域中。
                //如果当前节点没有子物体。直接成为引用。
                //如果当前节点有子物体，选择保留当前子节点，还是成为引用。
                if(aliasController.text.length == 0){
                  if(treeModel.ContainConceptNode(newDomainNodeKey)){
                    //存在同概念名节点，观察双方子节点数量。
                    hasSameConcept = true;
                    if(selectedConceptNode.children.isNotEmpty){
                      //弹窗，选择是成为引用，还是才成为新的根节点。
                      chosenReference = true;
                    }
                  }
                }
                else{
                  if(treeModel.ContainConceptNode(newDomainNodeKey)){
                    //同一域中不能存在概念名和别名都相同的节点。在UI层解决,hasError。
                    return;
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

                List<ConceptNodeTree> childrenBackup = [];
                if(hasSameConcept){
                  childrenBackup = selectedConceptNode.children;
                }

                void doRename() {
                  //设置节点名和别名。
                  selectedConceptNode.name = newName;
                  selectedConceptNode.alias = newAlias;
                  treeModel.GenerateDic();
                  if(hasSameConcept == false) {
                    //将要成为的节点中，没有出现相同节点。直接完成交换即可。
                    //设置渲染物体。
                    NodeDrawingData newDrawingData = lastDrawingData.Clone();
                    newDrawingData.text = newName;

                    NodeViewData newViewData = lastViewData.Clone();
                    nodeDrawingDataDic.putIfAbsent(newDomainNodeKey, () => newDrawingData);
                    viewDataDic.putIfAbsent(newDomainNodeKey, () => newViewData);

                    if(!treeModel.ContainConceptNode(oldDomainNodeKey)) {
                      nodeDrawingDataDic.remove(oldDomainNodeKey);
                      viewDataDic.remove(oldDomainNodeKey);
                    }
                  }
                  else{
                    if(chosenReference){
                      //选择成为引用。清除子节点。
                      print("存在重名概念，将自身设置成引用");
                      selectedConceptNode.children.clear();
                    }
                    else{
                      print("将自身设置成根节点");
                      //重新构建字典,将children移动到根部位置。？？？或者可以自由设置根部位置。确保非根部的children为空就行。

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
                void undoRename(){
                  //设置节点名和别名。
                  selectedConceptNode.name = oldName;
                  selectedConceptNode.alias = oldAlias;
                  treeModel.GenerateDic();

                  if(hasSameConcept == false) {
                    //将要成为的节点中，没有出现相同节点。直接完成交换即可。
                    //设置渲染物体。
                    if(!treeModel.ContainConceptNode(newDomainNodeKey)) {
                      nodeDrawingDataDic.remove(newDomainNodeKey);
                      viewDataDic.remove(newDomainNodeKey);
                    }

                    nodeDrawingDataDic.putIfAbsent(oldDomainNodeKey, () => lastDrawingData);
                    viewDataDic.putIfAbsent(oldDomainNodeKey, () => lastViewData);
                  }
                  else{
                    if(chosenReference){
                      //选择成为引用。清除子节点。
                      print("存在重名概念，将自身设置成引用");
                      selectedConceptNode.children = childrenBackup;
                    }
                    else{
                      print("将自身设置成根节点");
                      //重新构建字典,将children移动到根部位置。？？？或者可以自由设置根部位置。确保非根部的children为空就行。

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

                doRename();
                print("打印节点字典"+treeModel.PrintDic());
                commandManager.PushCommand(commandManager.editInstance, Command(
                  function: () => doRename(),
                  undoFunction: () => undoRename(),
                ));

              },
              child: Text("修改概念名")
          ),
      ],
    );
  }
}
