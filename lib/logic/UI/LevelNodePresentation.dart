//仅负责呈现视觉效果。不负责处理点击关系。
import 'package:concept_navigator/MTools/UI/DebugUI.dart';
import 'package:concept_navigator/MTools/UI/TextHeight/GetTextHeight.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodeInfo/GetNodeColor.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/LevelNodePanel.dart';
import 'package:concept_navigator/logic/UI/NodePresentation.dart';
import 'package:flutter/material.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/NodePainter.dart';

class LevelNodePresentation extends StatefulWidget {
  LevelNodePresentation({super.key,double scale = 1.0,required this.isDomain,required this.parentDomainDrawingData,required this.parentConceptDrawingData,required this.drawingData, required this.nodeTree,required this.domainTree}) :
        painter =  NodePainter(drawingData: drawingData),_scale = scale;
  final bool isDomain;
  final NodeDrawingData? parentConceptDrawingData;//仅仅传入父节点绘制物的推荐颜色。
  final DomainDrawingData? parentDomainDrawingData;
  final NodeDrawingData drawingData;
  final ConceptNodeTree? nodeTree;
  final DomainTree? domainTree;
  final NodePainter? painter;
  final double _scale;



  @override
  State<LevelNodePresentation> createState() => _LevelNodePresentationState();
}

class _LevelNodePresentationState extends State<LevelNodePresentation> {
  bool showingLevel = false;
  double width =100;
  double height = 100;
  @override
  void initState() {
    super.initState();
    showingLevel = false;
  }
  //int level;


  @override
  Widget build(BuildContext context) {
    NodeColorHelper colorHelper = NodeColorHelper.byDrawingData(
      parentDomainDrawingData: widget.parentDomainDrawingData,
      parentConceptDrawingData: widget.parentConceptDrawingData,
      nodeAppearance: widget.drawingData.nodeAppearance,
      isSelectedDomain: widget.isDomain,
    );

    Color nodeColor = colorHelper.getNodeColor(context);
    Color fontColor = colorHelper.getFontColor(context);


    //bool showingLevel = false;
    width = widget.drawingData.nodeAppearance.nodeSize.width * widget._scale;
    height = widget.drawingData.nodeAppearance.nodeSize.height * widget._scale;
    print("nodeSize.H ${height},scale ${widget._scale}");

    if(height>widget.drawingData.nodeAppearance.minChildNodeSize){
      //return DebugUI.pointer();
      showingLevel = true;
    }
    else {
      showingLevel = false;
    }

    //showingLevel = false;

    TextStyle textStyle = TextStyle(
      color: fontColor,
      inherit: false,
      fontSize: 14,//动态计算
    );
    const double BORDER = 2.0;
    //获取字体的高度
    const double EDGEINSETS = 6.0;
    double singleLineTextHeight = TextSizeHelper.GetTextHeight(maxLines: 1, text: widget.drawingData.text, style: textStyle);
    double fullLineTextHeight = TextSizeHelper.GetTextHeight( maxWidth: width,text: widget.drawingData.text , style: textStyle);
    double nextWidgetTop = singleLineTextHeight + 2 * EDGEINSETS;
    double centerFontTop = height*0.5 - fullLineTextHeight*0.5 - EDGEINSETS;
    //centerFontTop = height * 0.5 - EDGEINSETS;
    centerFontTop = centerFontTop>0? centerFontTop:0;
    print("FullLineTextH${fullLineTextHeight}");

    String domainKey = widget.isDomain? widget.domainTree!.GetDomainKey():"";
    if(widget.isDomain){
      print("domainKeyR${domainKey}");
    }
    return Container(
      // 设置节点的大小
      width: width,
      height: height,

      // 圆角矩形装饰
      decoration: BoxDecoration(
        color: nodeColor,//Colors.green.blend(), Theme.of(context).colorScheme.surface),
        borderRadius: BorderRadius.circular(height * 0.1),
        border: Border.all(width: BORDER,
            strokeAlign: BorderSide.strokeAlignOutside,
            color: Theme.of(context).colorScheme.outline,
        ),
      ),

      // 裁剪超出圆角矩形的内容
      clipBehavior: Clip.hardEdge,


      // 内容居中
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
            //mainAxisAlignment: /*showingLevel? MainAxisAlignment.start :*/ MainAxisAlignment.center,
            //crossAxisAlignment: CrossAxisAlignment.start,
            //verticalDirection: VerticalDirection.down,
            children: [

              //if(showingLevel) FlutterLogo(size: 50,),
              // AnimatedContainer(
              //
              //   alignment: showingLevel
              //       ? Alignment.topCenter
              //       : Alignment.center,
              //   child:
                AnimatedPositioned(

                  duration: Duration(milliseconds: 300),
                  top: showingLevel?0:centerFontTop,//*0.5 - textHeight *0.5,
                  //child:DebugUI.pointer(),
                  child: SizedBox(
                    height: fullLineTextHeight + 2 * EDGEINSETS,
                    width: width,
                    // child: Container(
                    //   color: Colors.black45,
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(EDGEINSETS),
                    //     child: Container(
                    //       color: Colors.black,
                    //     ),
                    //   ),
                    // ),
                    child: Padding(

                      //duration: Duration(milliseconds: 500),
                      //curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(EDGEINSETS),

                      child: Text(

                        widget.drawingData.text,
                        // 自动换行
                        softWrap: true,
                        maxLines: showingLevel ? 1 : null,
                        // 超出上下边缘时剪切
                        overflow: TextOverflow.clip,
                        // 末端文字居中
                        textAlign: TextAlign.center,
                        // 文字样式
                        style: textStyle,
                        // style: TextStyle(
                        //   color: drawingData.nodeAppearance.fontColor,
                        //   fontSize: 14,//动态计算
                        //),
                      ),
                    ),

                  ),
                ),

              //),
              //if(showingLevel)
                // AnimatedOpacity(
                //   duration: Duration(milliseconds: 500),
                //   opacity: showingLevel? 1.0 : 0.0,
                //   child:
                  AnimatedPositioned(
                    top: showingLevel ? nextWidgetTop : height,
                      duration: Duration(milliseconds: 200),
                      child: AnimatedOpacity(
                        opacity: showingLevel?1:0,
                        duration: Duration(milliseconds: 1000),
                        child: Container(
                          width: width,
                          height: showingLevel? height - nextWidgetTop : 0,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              border: Border.all(
                                  width: 1.0,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                  color: Theme.of(context).colorScheme.outline
                              ),
                            ),
                            //duration: Duration(milliseconds: 300),
                            child: showingLevel? Padding(
                              padding: EdgeInsets.all(0.05 * (height - nextWidgetTop)),
                              child: LevelNodePanel(
                                  isInDomain: widget.isDomain,
                                  currentDomainKey: widget.isDomain? domainKey : widget.nodeTree!.domainKey,
                                  currentDomainNodeKey: widget.isDomain? domainKey :  ConceptTreeModel.GenerateDomainNodeKey(widget.nodeTree!.domainKey,widget. nodeTree!.name, widget.nodeTree!.alias),
                              ),
                            ):null,
                        ),
                      ),
                  )
              ,

              // if(showingLevel)
              // Expanded(
              //     child: DebugUI.pointer(size: Size(500,500),)),

            ]
        ),
      ),
    );
    return Container(
      // 设置节点的大小
      width: width,
      height: height,

      // 圆角矩形装饰
      decoration: BoxDecoration(
        color: widget.drawingData.nodeAppearance.nodeColor,
        borderRadius: BorderRadius.circular(height * 0.1),
        border: Border.all(width: 2.0),
      ),

      // 裁剪超出圆角矩形的内容
      clipBehavior: Clip.hardEdge,

      // 内容居中
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            widget.drawingData.text+"................................._____--------",
            // 自动换行
            softWrap: true,
            // 超出上下边缘时剪切
            overflow: TextOverflow.visible,
            // 文字居中
            textAlign: TextAlign.center,
            // 文字样式
            style: TextStyle(
              color: widget.drawingData.nodeAppearance.fontColor,
              fontSize: 14,//动态计算
            ),
          ),
        ),
      ),
    );
    // return CustomPaint(
    //     size: drawingData.nodeAppearance.nodeSize,
    //     painter: painter!,
    // );
  }
}

