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
  //节点文字
  String text = "new concept";

  //子物体相对位置。
  List<Int2> childrenNodePos = [];//节点树与节点位置一一对应。

  //排列模式
  SortingMode sortingMode = SortingMode.grid;
  //网格排列模式
  //当前节点组最大x，最大y。
  int maxX = 4;
  //珠串排列模式

  NodeDrawingData Clone(){
    return NodeDrawingData(nodeAppearance: this.nodeAppearance)//深拷贝一个Drawingdata,防止干扰之前的。
      ..text = text
      ..childrenNodePos = childrenNodePos
      ..sortingMode = sortingMode
      ..maxX = maxX;
  }

  //和节点群相关的一系列排版。
  AddNodeDrawingData(){

    int num = 0;
    if(childrenNodePos.isNotEmpty){
      var lastdata = childrenNodePos.last;
      num = lastdata.x % maxX + lastdata.y * maxX +1;
    }
    childrenNodePos.add(Int2(sortingMode == SortingMode.grid?num %maxX:num,sortingMode == SortingMode.grid?num~/maxX:0));

    notifyListeners();
    print("addNode+ $num ");
  }
  RemoveAtNodeDrawingData(int index){
    Int2 pos = childrenNodePos[index];
    int num = pos.x % maxX + pos.y* maxX;
    print("removeNode+$num");

    childrenNodePos.removeAt(index);
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
      });



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

  DomainDrawingData({ required super.nodeAppearance});

  @override AddNodeDrawingData() {
    // TODO: implement AddNodeDrawingData
    return super.AddNodeDrawingData();
  }
  AddDomainDrawingData(){
    int num = 0;
    if(childrenDomainPos.isNotEmpty){
      var lastdata = childrenDomainPos.last;
      num = lastdata.x % maxX + lastdata.y * maxX +1;
    }
    childrenDomainPos.add(Int2(domainSortingMode == SortingMode.grid?num %maxX:num,domainSortingMode == SortingMode.grid?num~/maxX:0));

    notifyListeners();
    print("addDomain+ $num ");
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
    commandManager.PushCommand(Command(
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


}