import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
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
    ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();

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

                  String newDomainNodeKey = ConceptTreeModel.AppendDomainKey(selection.currentDomain, controller.text);
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

                  //设置节点名和别名。
                  selection.SelectedDomain!.name = controller.text;
                  //selection.SelectedConceptNode!.alias = aliasController.text;
                  // if(hasSameDomain == false) {
                  //
                  // }
                  // else if(needChoseChildren == false){
                  //   print("存在重名概念，将自身设置成引用");//这里还是有问题。
                  //   selection.SelectedConceptNode!.children.clear();
                  // }

                  //设置渲染物体。
                  DomainDrawingData newDrawingData = lastDrawingData.Clone();
                  newDrawingData.text = controller.text;

                  NodeViewData newViewData = lastViewData.Clone();
                  domainDrawingDataDic.putIfAbsent(newDomainNodeKey, ()=>newDrawingData);
                  viewDataDic.putIfAbsent(newDomainNodeKey, ()=>newViewData);

                  treeModel.GenerateDic();

                  domainDrawingDataDic.remove(domainNodeKey);
                  viewDataDic.remove(domainNodeKey);

                  //遍历这个域内的所有子树，并且修改Dic。
                  print("交换ddomainDrawingDatat");
                  domainDrawingDataDic.ChangeKeys((key){
                    String? res = ConceptTreeModel.replaceDomainKey(key, domainNodeKey, controller.text);
                    return res?? key;
                  });
                  print("交换nodenDrawingDatat");

                  nodeDrawingDataDic.ChangeKeys((key){
                    String? res = ConceptTreeModel.replaceDomainKey(key, domainNodeKey, controller.text);
                    return res?? key;
                  });
                  print("交换viewDatat");
                  viewDataDic.ChangeKeys((key){
                    String? res = ConceptTreeModel.replaceDomainKey(key, domainNodeKey, controller.text);
                    return res?? key;
                  });

                  // print("打印节点字典"+treeModel.PrintDic());
                  // if(!treeModel.ContainDomain(domainNodeKey)) {
                  //
                  // }

                },
                child: Text("修改域名")
            ),


        ],
      ),
    );
  }
}
