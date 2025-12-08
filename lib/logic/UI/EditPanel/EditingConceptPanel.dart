import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditingConceptPanel extends StatefulWidget {
  EditingConceptPanel({super.key});

  @override
  State<EditingConceptPanel> createState() => _EditingConceptPanelState();
}

class _EditingConceptPanelState extends State<EditingConceptPanel> {
  final TextEditingController controller = TextEditingController.fromValue(
      TextEditingValue(
      ),
  );

  final TextEditingController aliasController = TextEditingController();
  //bool isNameChanged = false;


  @override
  Widget build(BuildContext context) {
    GlobalStateModel stateModel = context.watch<GlobalStateModel>();
    SelectionViewData selection = context.watch<SelectionViewData>();
    ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();

    //初始化controller
    controller.text = selection.SelectedConceptNode!.name;
    aliasController.text = selection.SelectedConceptNode!.alias;

    return Container(
      color: Colors.blue[100],
      child: ListView(
        children: [
          Center(child: Text("概念信息")),

          TextField(
            controller: controller,
            decoration: InputDecoration(
              //border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.dashboard_customize_rounded),
              hintText: "请输入概念名",
              labelText: "概念名",
              helperText: "概念名区别不同概念，同概念名的概念相同",
              errorText: null,

            ),
            onChanged: (value){
              //风险判断。
              //设置节点名和别名。
              //设置渲染物体。

            },
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
              errorText:null,
            ),

          ),
          if(true)
            OutlinedButton(
              onPressed: (){
                bool hasSameConcept = false;
                bool needChoseChildren = false;

                String newDomainNodeKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain,controller.text,aliasController.text);
                //风险判断。
                //新命名的概念名已经存在域中。
                //如果当前节点没有子物体。直接成为引用。
                //如果当前节点有子物体，选择保留当前子节点，还是成为引用。
                if(aliasController.text.length == 0){
                  if(treeModel.ContainConceptNode(newDomainNodeKey)){
                    //存在同概念名节点，观察双方子节点数量。
                    hasSameConcept = true;

                  }
                }
                else{
                  if(treeModel.ContainConceptNode(newDomainNodeKey)){
                    //同一域中不能存在概念名和别名都相同的节点。
                  }
                }
                String name = selection.SelectedConceptNode!.name;
                String alias = selection.SelectedConceptNode!.alias;
                String domainNodeKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, name, alias);

                NodeDrawingData? lastDrawingData = nodeDrawingDataDic.GetNodeDrawingData(domainNodeKey);
                if(lastDrawingData == null){
                  print("错误，概念编辑面板找不到修改前的渲染数据");
                  return;
                }


                //设置节点名和别名。
                selection.SelectedConceptNode!.name = controller.text;
                selection.SelectedConceptNode!.alias = aliasController.text;

                //设置渲染物体。
                NodeDrawingData newDrawingData = lastDrawingData!.Clone();
                newDrawingData.text = controller.text;

                if(hasSameConcept == false) {
                  nodeDrawingDataDic.putIfAbsent(newDomainNodeKey, ()=>newDrawingData);
                }
                else if(needChoseChildren == false){
                  print("存在重名概念，将自身设置成引用");//这里还是有问题。
                  selection.SelectedConceptNode!.children.clear();
                }

                treeModel.GenerateDic(selection.currentDomain);

                print("打印节点字典"+treeModel.PrintDic());
                if(!treeModel.ContainConceptNode(domainNodeKey)) {
                  nodeDrawingDataDic.remove(domainNodeKey);
                }
              },
              child: Text("修改概念名")
            ),


        ],
      ),
    );
  }
}
