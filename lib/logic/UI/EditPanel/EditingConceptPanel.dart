import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeConflictCheck.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeMoveComponent/NodeMoveComponent.dart';
import 'package:concept_navigator/logic/UI/EditPanel/StatefulComponent/StatefulComponents.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/DoubleActionButton.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/ScroallablePositionedList/ScrollablePositionedListExtension.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/ScroallablePositionedList/ScrollablePositionedListItem.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class EditingConceptPanel extends StatefulWidget {
  const EditingConceptPanel({super.key, this.needInit = false});
  final bool needInit;

  @override
  State<EditingConceptPanel> createState() => _EditingConceptPanelState();
}

class _EditingConceptPanelState extends State<EditingConceptPanel> {
  final TextEditingController controller = TextEditingController.fromValue(
      TextEditingValue(
      ),
  );

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

  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  final ItemScrollController scrollController = ItemScrollController();
  int centerIndex = 0;

  bool hasFocusState = false;
  void _hasFocusState(bool value) {
    setState(() {
      hasFocusState = value;
    });
  }

  @override
  void initState() {
    itemPositionsListener.itemPositions.addListener((){
      print("!!!??????itemPosition?${itemPositionsListener.itemPositions.value}");
      //计算中心序号
      double maxVisualSize = 0;
      int index = 0;
      for(var itemPosition in itemPositionsListener.itemPositions.value){
        double centerEdge = 0.5;
        if(itemPosition.itemLeadingEdge<centerEdge && itemPosition.itemTrailingEdge>centerEdge){
          index = itemPosition.index;
        }

        double leadEdge = itemPosition.itemLeadingEdge < 0? 0:itemPosition.itemLeadingEdge;
        double trailEdge = itemPosition.itemTrailingEdge > 1? 1:itemPosition.itemTrailingEdge;
        double maxEdge = trailEdge - leadEdge;
        if(maxEdge > maxVisualSize){
          maxVisualSize = maxEdge;
          index = itemPosition.index;
        }
      }
      //print("Cal!!!!$index");
      if(centerIndex != index){
        setState(() {
          centerIndex = index;
        });
      }
    });
    //itemPositionsListener.itemPositions.
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    GlobalStateModel stateModel = context.watch<GlobalStateModel>();
    SelectionViewData selection = context.watch<SelectionViewData>();
    ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();
    if(selection.IsSelecting == false){
      return Placeholder();
    }

    if(widget.needInit){
      //初始化controller
      controller.text = selection.SelectedConceptNode!.name;
      aliasController.text = selection.SelectedConceptNode!.alias;
    }

    //nameErrorCheck(treeModel, selection, controller.text, aliasController.text);
    //aliasErrorCheck(treeModel, selection, controller.text, aliasController.text);
    Widget conceptInfo = Column(
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
                NodeViewData? lastViewData = viewDataDic.GetNodeViewData(domainNodeKey);
                if(lastViewData == null){
                  print("EditingConceptPanel找不到当前修改节点的NodeViewData");
                  return;
                }



                //设置节点名和别名。
                selection.SelectedConceptNode!.name = controller.text;
                selection.SelectedConceptNode!.alias = aliasController.text;

                //设置渲染物体。
                NodeDrawingData newDrawingData = lastDrawingData.Clone();
                newDrawingData.text = controller.text;

                NodeViewData newViewData = lastViewData.Clone();

                if(hasSameConcept == false) {
                  nodeDrawingDataDic.putIfAbsent(newDomainNodeKey, ()=>newDrawingData);
                  viewDataDic.putIfAbsent(newDomainNodeKey, ()=>newViewData);
                }
                else if(needChoseChildren == false){
                  print("存在重名概念，将自身设置成引用");//这里还是有问题。
                  selection.SelectedConceptNode!.children.clear();
                }

                treeModel.GenerateDic();

                print("打印节点字典"+treeModel.PrintDic());
                if(!treeModel.ContainConceptNode(domainNodeKey)) {
                  nodeDrawingDataDic.remove(domainNodeKey);
                  viewDataDic.remove(domainNodeKey);
                }

              },
              child: Text("修改概念名")
          ),
      ],
    );
    final List<String> childrenTitle = [
      "概念信息",

    ];
    final List<Widget> children = [
      conceptInfo
      ,
      ConceptMoveComponent(needInit:  widget.needInit),
      ConceptMoveComponent(),
      ConceptMoveComponent(),
      ConceptMoveComponent(),
      DoubleActionButton(onLeftPressed: (){
        scrollController.scrollTo(
            index: 0,
            alignment: 0.1,
            duration: Duration(milliseconds: 300));
      },),
    ];

    // return ScrollablePositionedList.builder(itemCount: 10,
    //   itemPositionsListener: itemPositionsListener,
    //   itemBuilder: (BuildContext context, int index) {
    //   return FlutterLogo(size: 100,);
    // },  );
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: ScrollablePositionedList.builder(
        physics: hasFocusState? NeverScrollableScrollPhysics() : null,
        itemPositionsListener: itemPositionsListener,
        itemScrollController: scrollController,
        itemCount: children.length,
        itemBuilder: (BuildContext context, int index) {
          double state = centerIndex == index? 1:-1;
          //return FlutterLogo(size: 100,);

          return StlessScrollablePositionedListItem(
            index: index,
            controller : scrollController,
            needStopScroll: _hasFocusState,
            child: AnimatedStatefulComponent(
              componentTitle: childrenTitle[0],
              state: state,
              duration: Duration(milliseconds: 200),
              child: children[index],
            ),
          );
        },
      ),
    );
  }


}
