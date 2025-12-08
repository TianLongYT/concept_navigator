
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/CreatingDomainPanel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/EditingConceptPanel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


//执行创建检查。
//命名修改窗口。错误检查。
class EditorPanel extends StatefulWidget {
  EditorPanel({super.key});

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {
  //final String preText = ;
  final TextEditingController controller = TextEditingController.fromValue(TextEditingValue(
    //预文本。
    // text: "",
    // selection: TextSelection.fromPosition(TextPosition(
    //   affinity: TextAffinity.downstream,
    //   offset: "preText".length,
    // ))
  ));

  bool hasError = true;

  String? nameError = "概念名不能为空";
  String? aliasError = null;

  final TextEditingController aliasController = TextEditingController();

  void _CheckTextField(String value){
    if(CheckEmpty(value) == true){
      hasError = true;
      setState(() {
        nameError = "概念名不能为空";
      });
    }
    else if(CheckContainList(value, ConceptTreeModel.ErrorPatten)){
      hasError = true;
      setState(() {
        nameError = "命名中不能连续出现'/'和'_'字符";


      });
    }
    else{
      hasError = false;

      setState(() {
        nameError = null;

      });
    }
  }
  void _CheckAliasTextField(ConceptTreeModel treeModel,SelectionViewData selection,String value){
    //同一域内不允许出现名字和别名都相同的概念。
    if(value.length != 0){
      if(treeModel.ContainConceptNode(ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, controller.text, aliasController.text))){
        hasError = true;
        setState(() {
          aliasError = "同一域内不允许出现名字和别名都相同的概念";

        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    GlobalStateModel stateModel = context.watch<GlobalStateModel>();
    SelectionViewData selection = context.watch<SelectionViewData>();
    ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();


    switch(stateModel.State) {
      case GlobalState.creatingNode:
        return Container(
          color: Colors.white,
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
                onTap: (){_CheckTextField(controller.text);},
                onChanged: _CheckTextField,
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

                onChanged: (value){
                  _CheckAliasTextField(treeModel,selection,value);
                }
                ,
              ),
              OutlinedButton(onPressed: (){
                if(hasError)
                  return;

                ConceptNodeTree node2Add = ConceptNodeTree()..name = controller.text..alias = aliasController.text;
                if(selection.IsInDomain){
                  DomainTree? domainTree = treeModel.GetDomainTree(selection.currentDomain);
                  if(domainTree == null){
                    print("错误：找不到当前界面的domainTree");
                    return;
                  }
                  domainTree.conceptNodeTree.add(node2Add);
                  treeModel.GenerateDic(selection.currentDomain);
                  print("节点树字典"+treeModel.PrintDic());

                  domainDrawingDataDic.GetDomainDrawingData(selection.currentDomain)?.AddNodeDrawingData();
                  nodeDrawingDataDic.putIfAbsent( ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, controller.text, aliasController.text), ()=>
                      NodeDrawingData(nodeAppearance: NodeAppearance())..text = controller.text);
                  viewDataDic.putIfAbsent( ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, controller.text,  aliasController.text), ()=>NodeViewData());

                }
                else{
                  ConceptNodeTree? nodeTree = treeModel.GetConceptNodeByDic(selection.CurrentDomainNodeKey);
                  if(nodeTree == null) {
                    print("错误：找不到当前界面的nodeTree");
                    return;
                  }
                  nodeTree.children.add(node2Add);
                  treeModel.GenerateDic(selection.currentDomain);
                  print("节点树字典"+treeModel.PrintDic());
                  //查找并添加绘制物
                  nodeDrawingDataDic.GetNodeDrawingData(selection.CurrentDomainNodeKey)?.AddNodeDrawingData();
                  nodeDrawingDataDic.putIfAbsent( ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, controller.text, aliasController.text), ()=>
                      NodeDrawingData(nodeAppearance: NodeAppearance())..text =  controller.text);
                  viewDataDic.putIfAbsent( ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, controller.text,  aliasController.text), ()=>NodeViewData());

                }
                controller.clear();
                aliasController.clear();

                //一开始就进行字符判断。
                _CheckTextField("");
                _CheckAliasTextField(treeModel,selection,"");

                //选中新创建的节点。
                stateModel.State = GlobalState.selectedNode;
                selection.SelectedConceptNode = node2Add;

              }, child: Text("新建概念")),
            ],
          ),
        );
      case GlobalState.creatingDomain:
        return CreatingDomainPanel();
      case GlobalState.selectedNode:

        return EditingConceptPanel();
      case GlobalState.selectedDomain:
        controller.text = selection.SelectedDomain!.name;

        return Container(
          color: Colors.blue[200],
          child: ListView(
            children: [
              Center(child: Text("域信息")),

              TextField(
                controller: controller,
                onEditingComplete: ()=>{

                },
              )
            ],
          ),
        );
      default :
        return Placeholder();
    }

  }

  bool CheckEmpty(String value){
    return value.length == 0;
  }

  bool CheckContain(String input,String pattern){
    return RegExp(pattern).hasMatch(input);
  }

  bool CheckContainList(String input,List<String> patterns){
    bool res = false;
    patterns.forEach((element){
      if(CheckContain(input, element)){
        res = true;
      }
    });
    return res;
  }
}
