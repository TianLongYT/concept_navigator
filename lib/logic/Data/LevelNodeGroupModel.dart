import 'package:concept_navigator/MTools/MMath.dart';
import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:flutter/material.dart';



class NodeDrawingData extends ChangeNotifier{
  //自身绘制数据
  //节点绘制模板和层级设置
  NodeAppearance nodeAppearance;

  DecoratorAppearance decoratorAppearance;
  //节点文字
  String text = "new concept";
  //修饰词。
  Set<String> decoration = {};

  //子物体相对位置。
  List<Int2> childrenNodePos = [];//节点树与节点位置一一对应。

  //排列模式
  SortingMode sortingMode = SortingMode.grid;
  //网格排列模式
  //当前节点组最大x，最大y。
  int maxX = 4;
  //珠串排列模式

  //子节点默认颜色。
  Color? defaultConceptNodeColor;
  Color? defaultConceptFontColor;



  NodeDrawingData Clone(){
    return NodeDrawingData(nodeAppearance: this.nodeAppearance.Clone())//深拷贝一个Drawingdata,防止干扰之前的。
      ..text = text
      ..decoration = {...decoration}
      ..decoratorAppearance = decoratorAppearance.Clone()
      ..childrenNodePos = [...childrenNodePos]
      ..sortingMode = sortingMode
      ..maxX = maxX;
  }
  Int2 calLastNodeInt2(){
    int num = 0;
    if(childrenNodePos.isNotEmpty){
      var lastdata = childrenNodePos.last;
      num = lastdata.x % maxX + lastdata.y * maxX +1;
    }
    return Int2(sortingMode == SortingMode.grid?num %maxX:num,sortingMode == SortingMode.grid?num~/maxX:0);
  }
  //和节点群相关的一系列排版。
  AddNodeDrawingData(){


    childrenNodePos.add(calLastNodeInt2());

    notifyListeners();
    //print("addNode+ $num ");
  }
  RemoveAtNodeDrawingData(int index){

    Int2 pos = childrenNodePos[index];
    int num = pos.x % maxX + pos.y* maxX;
    print("removeNode+$num");

    childrenNodePos.removeAt(index);
    notifyListeners();
  }
  RemoveAtNodeDrawingDataSqueeze(int index){

    Int2 pos = childrenNodePos[index];
    int num = pos.x % maxX + pos.y* maxX;
    print("removeNode+$num");

    // 核心修改：后方节点坐标前移
    // 从 index + 1 开始，把坐标赋给 index
    for (int i = childrenNodePos.length - 1; i > index ; i--) {
      childrenNodePos[i] = childrenNodePos[i-1];
    }
    childrenNodePos.removeAt(index);
    notifyListeners();
  }
  InsertNodeDrawingData(int index, Int2 pos){
    childrenNodePos.insert(index, pos);
    notifyListeners();
  }
  InsertNodeDrawingDataSqueeze(int index, Int2 pos){

    // 核心修改：后方节点坐标前移
    // 从 index + 1 开始，把坐标赋给 index
    if(childrenNodePos.isNotEmpty){
      for (int i = index; i < childrenNodePos.length - 1; i++) {
        childrenNodePos[i] = childrenNodePos[i + 1];
      }
      childrenNodePos[childrenNodePos.length - 1] = calLastNodeInt2();
    }
    childrenNodePos.insert(index, pos);

    notifyListeners();
  }
  _ResortNode(){

    childrenNodePos.forEach((drawingData){
      drawingData.x = drawingData.x % maxX + drawingData.y * maxX;
      drawingData.y = 0;
    });

    if(sortingMode == SortingMode.grid){
      childrenNodePos.forEach((drawingData){
        drawingData.y = drawingData.x ~/ maxX;
        drawingData.x = drawingData.x % maxX;
      });
    }
  }
  ResortNode(List<ConceptNodeTree> nodeTree){
    //移动节点后，根据相对位置的num值，重新排列节点树。合理表示层级关系。


  }

  ChangeMode(SortingMode sortingMode){
    this.sortingMode = sortingMode;

    _ResortNode();
    notifyListeners();
  }


  NodeDrawingData(
      {required this.nodeAppearance
      }): decoratorAppearance = DecoratorAppearance();

  void repaint() {
    notifyListeners();
  }
  @override
  String toString(){
    return "childNodePos:"+childrenNodePos.toString();
  }


  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'decoration': decoration.toList(),
      'decoratorAppearance': decoratorAppearance.toJson(),
      'childrenNodePos': childrenNodePos.map((e) => {'x': e.x, 'y': e.y}).toList(),
      'sortingMode': sortingMode.index,
      'maxX': maxX,
      'appearance': nodeAppearance.toJson(),
      'defaultConceptNodeColor': defaultConceptNodeColor?.value,
      'defaultConceptFontColor': defaultConceptFontColor?.value,
      'isDomain': false,
    };
  }

  static NodeDrawingData fromJson(Map<String, dynamic> json) {
    NodeDrawingData data;
    var appearance = NodeAppearance.fromJson(json['appearance']);
    if (json['isDomain'] == true) {
      data = DomainDrawingData(nodeAppearance: appearance);
      (data as DomainDrawingData).childrenDomainPos = (json['childrenDomainPos'] as List).map((e) => Int2(e['x'] as int, e['y'] as int)).toList();
      data.domainSortingMode = SortingMode.values[json['domainSortingMode'] ?? 0];
      data.domainMaxX = json['domainMaxX'] ?? 4;
      data.defaultDomainNodeColor = json['defaultDomainNodeColor'] != null ? Color(json['defaultDomainNodeColor'] as int) : null;
      data.defaultDomainFontColor = json['defaultDomainFontColor'] != null ? Color(json['defaultDomainFontColor'] as int) : null;
    } else {
      data = NodeDrawingData(nodeAppearance: appearance);
    }
    data.text = json['text'] ?? "";
    data.decoration = Set<String>.from(json['decoration'] ?? []);
    
    if (json['decoratorAppearance'] != null) {
      data.decoratorAppearance = DecoratorAppearance.fromJson(json['decoratorAppearance']);
    }

    data.childrenNodePos = (json['childrenNodePos'] as List).map((e) => Int2(e['x'] as int, e['y'] as int)).toList();
    data.sortingMode = SortingMode.values[json['sortingMode'] ?? 0];
    data.maxX = json['maxX'] ?? 4;
    data.defaultConceptNodeColor = json['defaultConceptNodeColor'] != null ? Color(json['defaultConceptNodeColor'] as int) : null;
    data.defaultConceptFontColor = json['defaultConceptFontColor'] != null ? Color(json['defaultConceptFontColor'] as int) : null;
    return data;
  }

}
class DomainDrawingData extends NodeDrawingData{
  //自身绘制数据
  //节点绘制模板和层级设置
  //NodeAppearance domainAppearance;//可以换成域绘制数据。
  //节点文字
  //String text = "new domain";
  //子物体相对位置。
  //Map<String,Offset> childrenNodePos = {};
  //Map<String,Offset> childrenDomainPos = {};
  //子物体相对位置。
  List<Int2> childrenDomainPos = [];//节点树与节点位置一一对应。
  SortingMode domainSortingMode = SortingMode.grid;
  int domainMaxX = 4;
  //子节点默认颜色。
  Color? defaultDomainNodeColor;
  Color? defaultDomainFontColor;


  DomainDrawingData({ required super.nodeAppearance});

  DomainDrawingData Clone(){
    return DomainDrawingData(
        nodeAppearance: nodeAppearance.Clone())
      ..text = text
      ..decoration = {...decoration}
      ..decoratorAppearance = decoratorAppearance.Clone()
      ..childrenNodePos = [...childrenNodePos]
      ..sortingMode = sortingMode
      ..maxX = maxX
      ..childrenDomainPos = [...childrenDomainPos]
      ..domainSortingMode = domainSortingMode
      ..domainMaxX = domainMaxX;

  }

  @override AddNodeDrawingData() {
    // TODO: implement AddNodeDrawingData
    return super.AddNodeDrawingData();
  }
  Int2 callLastDomainInt2(){
    int num = 0;
    if(childrenDomainPos.isNotEmpty){
      var lastdata = childrenDomainPos.last;
      num = lastdata.x % maxX + lastdata.y * maxX +1;
    }
    return Int2(domainSortingMode == SortingMode.grid?num %maxX:num,domainSortingMode == SortingMode.grid?num~/maxX:0);
  }
  AddDomainDrawingData(){

    childrenDomainPos.add(callLastDomainInt2());

    notifyListeners();
    print("addDomain+ ${callLastDomainInt2()} ");
  }

  RemoveAtDomainDrawingData(int index){
    childrenDomainPos.removeAt(index);
    notifyListeners();
  }
  RemoveAtDomainDrawingDataSqueeze(int index){
    // 核心修改：后方节点坐标前移
    // 从 index + 1 开始，把坐标赋给 index
    for (int i = childrenDomainPos.length - 1; i > index ; i--) {
      childrenDomainPos[i] = childrenDomainPos[i-1];
    }
    childrenDomainPos.removeAt(index);
    notifyListeners();
  }
  InsertDomainDrawingData(int index, Int2 pos){
    childrenDomainPos.insert(index, pos);
    notifyListeners();
  }
  InsertDomainDrawingDataSqueeze(int index, Int2 pos){

    // 核心修改：后方节点坐标前移
    // 从 index + 1 开始，把坐标赋给 index
    if(childrenDomainPos.isNotEmpty){
      for (int i = index; i < childrenDomainPos.length - 1; i++) {
        childrenDomainPos[i] = childrenDomainPos[i + 1];
      }
      childrenDomainPos[childrenDomainPos.length - 1] = callLastDomainInt2();
    }

    childrenDomainPos.insert(index, pos);
    notifyListeners();
  }

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json['isDomain'] = true;
    json['childrenDomainPos'] = childrenDomainPos.map((e) => {'x': e.x, 'y': e.y}).toList();
    json['domainSortingMode'] = domainSortingMode.index;
    json['domainMaxX'] = domainMaxX;
    json['defaultDomainNodeColor'] = defaultDomainNodeColor?.value;
    json['defaultDomainFontColor'] = defaultDomainFontColor?.value;
    return json;
  }
  @override
  String toString() {
    return "domainPos:${childrenDomainPos.toString()}" + super.toString();
  }
}

enum SortingMode{
  none,//空样式，或原样显示。
  grid,
  horizontal,
  vertical
}

class NodeViewData extends ChangeNotifier{

  Offset _lastViewPos = Offset.zero;
  double _lastScale = 0;

  //视角位置，摄像机位置。
  double viewPosX = 0;
  double viewPosY = 0;

  NodeViewData Clone(){
    return NodeViewData()
      .._lastViewPos = _lastViewPos
      .._lastScale = _lastScale
      ..viewPosX = viewPosX
      ..viewPosY=viewPosY;
  }

  CurViewPos() => Offset(viewPosX, viewPosY);
  SaveCurData(){
    _lastViewPos = Offset(viewPosX,viewPosY);
    _lastScale = this.scale;
  }

  MoveScaleView(Offset delta,double scale){
    viewPosX += delta.dx;
    viewPosY += delta.dy;
    this.scale = _lastScale * scale;
    //notifyListeners();
  }

  UploadDataCommand(CommandManagerForProvider commandManager,ConceptTree2NodeViewDataDic viewDataDic){
    Offset curViewPos = Offset(viewPosX,viewPosY);
    double curScale = scale;
    Offset lastViewPos = _lastViewPos;
    double lastScale = _lastScale;
    commandManager.naviInstance.PushCommand(Command(//commandManager.naviInstance,
        function: (){
          viewPosX = curViewPos.dx;
          viewPosY = curViewPos.dy;
          scale = curScale;
          viewDataDic.repaint();

        },
        undoFunction: (){
          viewPosX = lastViewPos.dx;
          viewPosY = lastViewPos.dy;
          scale = lastScale;
          viewDataDic.repaint();
          print("undo${lastViewPos}");
        })
    );
  }


//scale,缩放比例
  double scale = 1.0;

  MoveScale(double scale){
    this.scale = scale;
  }

  Map<String, dynamic> toJson() {
    return {
      'viewPosX': viewPosX,
      'viewPosY': viewPosY,
      'scale': scale,
    };
  }

  static NodeViewData fromJson(Map<String, dynamic> json) {
    return NodeViewData()
      ..viewPosX = (json['viewPosX'] ?? 0.0).toDouble()
      ..viewPosY = (json['viewPosY'] ?? 0.0).toDouble()
      ..scale = (json['scale'] ?? 1.0).toDouble();
  }


}
