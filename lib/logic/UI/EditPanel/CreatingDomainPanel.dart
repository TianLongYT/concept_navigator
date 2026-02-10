import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodePosition.dart';
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

  void _CheckTextField(String value) {
    if (value.length == 0) {
      hasError = true;
      setState(() {
        nameError = "域名不能为空";
      });
    }
    else if (CheckContainList(value, ConceptTreeModel.ErrorPatten)) {
      hasError = true;
      setState(() {
        nameError = "命名中不能连续出现'/'和'_'字符";
      });
    }//同一层级中不能出现相同的域。

    else {
      hasError = false;

      setState(() {
        nameError = null;
      });
    }
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
  @override
  Widget build(BuildContext context) {
    GlobalStateModel stateModel = context.watch<GlobalStateModel>();
    SelectionViewData selection = context.watch<SelectionViewData>();
    ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    //ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();

    FocusNodeHelper focusNodeHelper = FocusNodeHelper.lateInit(context);

    return Container(
      color: Colors.blue[100],
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
            onTap: (){_CheckTextField(controller.text);},
            onChanged:(value){
              _CheckTextField(value);
              //同层级不能出现相同域。

              DomainTree? curDomain = treeModel.GetDomainTree(selection.currentDomain);
              if(curDomain == null)
                return;
              for(int i = 0;i<curDomain.children.length;i++){
                if(value == curDomain.children[i].name){

                  hasError = true;
                  setState(() {
                    nameError = "同一层级不能出现相同的域";
                  });
                  return;
                }
              }
              },
          ),

          OutlinedButton(onPressed: (){
            if(hasError)
              return;

            DomainTree domain2Add = DomainTree()..name = controller.text;
            DomainDrawingData newDrawingData = DomainDrawingData(nodeAppearance: NodeAppearance())..text = controller.text;

            treeModel.AddNewDomainInDomain(selection.currentDomain, domain2Add);


            domainDrawingDataDic.GetDomainDrawingData(selection.currentDomain)?.AddDomainDrawingData();
            domainDrawingDataDic.putIfAbsent(ConceptTreeModel.AppendDomainKey( selection.currentDomain, domain2Add.name), ()=>
            newDrawingData);
            viewDataDic.putIfAbsent(ConceptTreeModel.AppendDomainKey( selection.currentDomain, domain2Add.name), ()=>NodeViewData());

            controller.clear();

            //一开始就进行字符判断。
            _CheckTextField("");

            //选中新创建的节点。
            stateModel.State = GlobalState.selectedDomain;
            selection.SelectedDomain = domain2Add;
            //聚焦新节点
            Size allSize = newDrawingData.nodeAppearance.nodeSize * newDrawingData.nodeAppearance.emptySize;
            focusNodeHelper.Init(selection.IsInDomain, selection.currentDomain, selection.CurrentDomainNodeKey, allSize);
            focusNodeHelper.FocusNode(null, domain2Add);

          }, child: Text("新建域")),
        ],
      ),
    );
  }
}
