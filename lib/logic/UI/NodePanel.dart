import 'dart:async';

import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/UserSettingModel.dart';
import 'package:concept_navigator/logic/UI/AddressBar/AddressBar.dart';
import 'package:concept_navigator/logic/UI/EditPanel/EditorPanel.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/CustomGesture/PanGestureDetector.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/DeleteNodeLogic.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/GetNodeInfo/GetNodePosition.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/SaveLogic.dart';
import 'package:concept_navigator/logic/UI/LevelDomain.dart';
import 'package:concept_navigator/logic/UI/LevelNode.dart';
import 'package:concept_navigator/logic/UI/LevelNodePresentation.dart';
import 'package:concept_navigator/logic/UI/PopInspector.dart';
import 'package:concept_navigator/logic/UI/SelectorBox.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class Nodepanel extends StatefulWidget {
  const Nodepanel({super.key});

  @override
  State<Nodepanel> createState() => _NodepanelState();
}

class _NodepanelState extends State<Nodepanel> {
  //制作levelNode的排版功能。显示所有的levelNode。
  bool isScaling = false;
  bool _isManualPop = false; // 手动弹出状态

  // 用于滚轮缩放的防抖和状态记录
  bool _isScrollingWheel = false;
  Timer? _scrollWheelTimer;

  @override
  void initState() {
    super.initState();
    // 注册全局硬件按键监听，解决原本 Focus 机制在复杂 UI 下容易失效的问题
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void dispose() {
    // 销毁时务必移除监听，防止内存泄漏或逻辑冲突
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _scrollWheelTimer?.cancel();
    super.dispose();
  }

  // 全局快捷键处理器：直接处理底层硬件按键事件
  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    // 提前获取状态，此处不适合使用 context.watch
    final editingState = Provider.of<EditingStateModel>(context, listen: false);
    final globalState = Provider.of<GlobalStateModel>(context, listen: false);
    final selection = Provider.of<SelectionViewData>(context, listen: false);
    final commandManager = Provider.of<CommandManagerForProvider>(context, listen: false);

    // 安全检查：如果当前焦点在输入框（EditableText）中，则不拦截任何快捷键
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus.context?.widget is EditableText) {
      return false; 
    }
    
    // 如果正在进行某些特定的编辑操作（如重命名过程中），也跳过全局快捷键
    if (editingState.State != EditingState.none) {
      // 特殊处理：重命名状态下虽然不是输入框焦点，也可能正在编辑，不拦截
      if(editingState.State != EditingState.renamingNode) return false;
    }

    final isCtrl = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // 1. Delete 键：执行删除逻辑
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      if (selection.IsSelecting) {
        DeleteNodeLogic.deleteSelectedNode(context);
        return true; 
      }
    } 
    // 2. Ctrl + N：快速打开创建概念面板
    else if (isCtrl && !isShift && event.logicalKey == LogicalKeyboardKey.keyN) {
      globalState.State = GlobalState.creatingConcept;
      return true;
    } 
    // 3. Ctrl + M：快速打开创建域面板
    else if (selection.IsInDomain && isCtrl && !isShift && event.logicalKey == LogicalKeyboardKey.keyM) {
      globalState.State = GlobalState.creatingDomain;
      return true;
    }
    // 4. Ctrl + Z：撤回
    else if (isCtrl && !isShift && event.logicalKey == LogicalKeyboardKey.keyZ) {
      CommandManager manager;
      
      // 这里的逻辑直接仿照 MFloatingButton
      if(editingState.State == EditingState.selectingMovingNode || 
         editingState.State == EditingState.waitingMovingTarget || 
         editingState.State == EditingState.squeezingNode){
        manager = commandManager.moveNodeInstance;
      } else {
        manager = commandManager.editInstance;
      }

      if (commandManager.HasCommand(manager)) {
        commandManager.Undo(manager);
        return true;
      }
    }
    // 5. Ctrl + Y 或 Ctrl + Shift + Z：重做
    else if ((isCtrl && event.logicalKey == LogicalKeyboardKey.keyY) || 
             (isCtrl && isShift && event.logicalKey == LogicalKeyboardKey.keyZ)) {
      CommandManager manager;
      if(editingState.State == EditingState.selectingMovingNode || 
         editingState.State == EditingState.waitingMovingTarget || 
         editingState.State == EditingState.squeezingNode){
        manager = commandManager.moveNodeInstance;
      } else {
        manager = commandManager.editInstance;
      }

      if (commandManager.HasPoppedCommand(manager)) {
        commandManager.Redo(manager);
        return true;
      }
    }
    // 6. Ctrl + S：保存
    else if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyS) {
      SaveLogic.performSave(context);
      return true;
    }

    return false;
  }
  
  bool editingStateModelToCommand(EditingState state){
     return state == EditingState.selectingMovingNode ||
          state == EditingState.waitingMovingTarget ||
          state == EditingState.squeezingNode;
  }

  @override
  Widget build(BuildContext context) {
    //获取必要显示数据。
    final ConceptTree2NodeDrawingDataDic nodeDrawingDataDic = context.watch<ConceptTree2NodeDrawingDataDic>();
    final ConceptTree2DomainDrawingDataDic domainDrawingDataDic = context.watch<ConceptTree2DomainDrawingDataDic>();
    final ConceptTree2NodeViewDataDic viewDataDic = context.watch<ConceptTree2NodeViewDataDic>();
    final SelectionViewData selection = context.watch<SelectionViewData>();
    final ConceptTreeModel treeModel = context.watch<ConceptTreeModel>();
    final GlobalStateModel globalStateModel = context.watch<GlobalStateModel>();
    final EditingStateModel editingStateModel = context.watch<EditingStateModel>();
    final CommandManagerForProvider commandManager = context.read<CommandManagerForProvider>();

    //节点位置助手
    NodePositionHelper nodePositionHelper = NodePositionHelper(treeModel: treeModel, domainDrawingDataDic: domainDrawingDataDic, nodeDrawingDataDic: nodeDrawingDataDic, viewDrawingDataDic: viewDataDic);
    nodePositionHelper.InitData(selection.IsInDomain, selection.currentDomain, selection.CurrentDomainNodeKey);
    print("初始化NodePositiongHelper ,selection :isInDomain:${selection.IsInDomain},currentDomainNodeKey:${selection.CurrentDomainNodeKey}");
    //获取视口数据
    final NodeViewData? nodeViewData = viewDataDic.GetNodeViewData(selection.CurrentDomainNodeKey);
    if(nodeViewData == null) return ErrorWidget("exception,节点绘制主界面没找到nodeviewData，检查参数配置");

    ConceptNodeTree? nodeTree = nodePositionHelper.nodeTree;
    DomainTree? domainTree = nodePositionHelper.domainTree;

    double scale = nodeViewData.scale;

    //
    // DomainDrawingData? domainDrawingData;
    // NodeDrawingData? nodeDrawingData;
    //
    // nodeTree = treeModel.GetConceptNodeByDic(selection.CurrentDomainNodeKey);
    //
    // if(selection.IsInDomain){
    //   domainDrawingData = domainDrawingDataDic.GetDomainDrawingData(domainNameKey);
    //   if(domainDrawingData == null) return ErrorWidget("exception，未找到当前domainDrawingData");
    //   domainTree = treeModel.GetDomainTree(selection.currentDomain);
    //   if(domainTree == null) return ErrorWidget("exception,getDomainTreeError");
    // }
    // else{
    //   nodeDrawingData = nodeDrawingDataDic.GetNodeDrawingData(domainNameKey);
    //   if(nodeDrawingData == null) return ErrorWidget("exception，未找到当前nodeDrawingData");
    //   if(nodeTree == null) return ErrorWidget("exception,getNodeTreeError");
    // }
    //
    //
    //
    //

    //
    // //如果在域内，且节点和域都不为空，需要计算域到节点的偏移。
    // Offset domainOffset = Offset.zero;
    // Offset conceptOffset = Offset.zero;
    // if(selection.IsInDomain){
    //   //计算domain所占的宽度。
    //   double domainWidth = 0;
    //   if(domainTree!.children.length!= 0){
    //     final String domainNameKey = ConceptTreeModel.AppendDomainKey(selection.currentDomain, domainTree!.children[0].name);
    //     final NodeDrawingData? drawingData = domainDrawingDataDic.GetDomainDrawingData(domainNameKey);
    //     if(drawingData == null) return ErrorWidget("exception，找不到第一个子域的渲染数据");
    //     Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
    //     int usefulCount = domainTree!.children.length > domainDrawingData!.domainMaxX ? domainDrawingData!.domainMaxX:domainTree!.children.length;
    //
    //     domainWidth = usefulCount * nodeSize.width;
    //   }
    //
    //   //计算concept所占宽度。
    //   double conceptWidth = 0;
    //   if(domainTree!.conceptNodeTree.length!= 0){
    //     final String domainNameKey = ConceptTreeModel.GenerateDomainNodeKey(selection.currentDomain, domainTree.conceptNodeTree[0].name, domainTree.conceptNodeTree[0].alias);
    //     final NodeDrawingData? drawingData = nodeDrawingDataDic.GetNodeDrawingData(domainNameKey);
    //     if(drawingData == null) return ErrorWidget("exception,根据子树找不到绘制子节点的渲染物体,键:${domainNameKey}");
    //
    //     Size nodeSize = drawingData.nodeAppearance.nodeSize * drawingData.nodeAppearance.emptySize;
    //     int usefulCount = domainTree!.conceptNodeTree.length > domainDrawingData!.maxX ? domainDrawingData!.maxX:domainTree!.conceptNodeTree.length;
    //
    //     conceptWidth = usefulCount * nodeSize.width;
    //   }
    //   //计算中轴线位置。
    //
    //   //计算offset偏移。
    //   double maxWidth = domainWidth > conceptWidth?domainWidth: conceptWidth;
    //   Offset allOffset = Offset( maxWidth *1.1,0);//加上基础偏移值。
    //   double t = domainWidth/(domainWidth+conceptWidth);
    //   domainOffset = - allOffset * t;
    //   conceptOffset = allOffset * (1-t);
    //
    // }

    print("MainNodePanel重新绘制stackModel,节点树"+treeModel.PrintTree() + "\r\n概念树字典${treeModel.PrintDic()}"+"\r\n节点名到概念渲染物"+nodeDrawingDataDic.toString()+"\r\n域渲染物${domainDrawingDataDic.toString()}"+"\r\n当前域绘制物${nodePositionHelper.domainDrawingData?.childrenNodePos}");
    final Widget editorPanel = GestureDetector(
      onTap: (){
        print("onTapEditor");
      },
        child: EditorPanel()
    );
    final Widget bgContainer = GestureDetector(//手势识别会进行冲突判断，且一次仅有一个手势可以被执行。
        onTap: (){
          print("onTap");
          if(editingStateModel.State == EditingState.waitingMovingTarget || editingStateModel.State == EditingState.selectingMovingNode){
            //globalStateModel.State = GlobalState.normal;
            return;
          }

          if (_isManualPop) {
            setState(() {
              _isManualPop = false;
            });
          }

          if(selection.IsSelecting) {
            globalStateModel.State = GlobalState.normal;
            selection.CancelSelection();
          }
          globalStateModel.State = GlobalState.normal;

        },
        child: Container(color: Theme.of(context).colorScheme.surface),
    );
    //当处于节点移动模式时，周围有虚化模糊的颜色。
    final Widget hintPanel =
    IgnorePointer(

      child: Stack(

        children:[
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Align(
              alignment: AlignmentGeometry.topCenter,
              child: Text(
                editingStateModel.State == EditingState.waitingMovingTarget? "选择目标节点交换(临时)" :"选择你想移动的节点",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 40
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                width: 10,
              )
            ),
          ),

        ],
      ),
    );

    // 节点状态提示背景板
    final Widget nodeStatusHintPanel = IgnorePointer(
      child: Stack(
        children: [
          if (!selection.IsInDomain && editingStateModel.State == EditingState.none)
            Builder(
              builder: (context) {
                // 通过 CurrentDomainNodeKey 获取当前所在的父概念节点
                final ConceptNodeTree? currentConcept = selection.currentConceptTree;
                if (currentConcept == null) return const SizedBox.shrink();

                final status = currentConcept.getStatus(treeModel);
                if (status == ConceptStatus.normal) return const SizedBox.shrink();

                final colors = Theme.of(context).extension<NodeColorsExtension>();

                String text = "";
                Color color = Colors.transparent;
                switch (status) {
                  case ConceptStatus.template:
                    text = "当前节点为：模板";
                    color = colors?.templateColor ?? Colors.purple;
                    break;
                  case ConceptStatus.templateReference:
                    text = "当前节点为：模板引用";
                    color = colors?.referenceColor ?? Colors.blue;
                    break;
                  case ConceptStatus.instance:
                    text = "当前节点为：实例";
                    color = colors?.instanceColor ?? Colors.orange;
                    break;
                  default: break;
                }

                return Stack(
                  children: [
                    Positioned(
                      top: 50,
                      left: 15,
                      right: 0,
                      child: Align(
                        alignment: AlignmentGeometry.topLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withOpacity(0.5), width: 2),
                          ),
                          child: Text(
                            text,
                            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: color.withOpacity(0.2),
                          width: 15,
                        )
                      ),
                    ),
                  ],
                );
              }
            ),
        ],
      ),
    );

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints){
      bool isPop = (globalStateModel.State != GlobalState.normal) || _isManualPop;
      // 获取屏幕方向
      bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

      // --- 修改为按屏幕比例排布 ---
      double landscapeContractWidth = constraints.maxWidth * 0.12;
      double landscapePopWidth = constraints.maxWidth * 0.35;
      double portraitContractHeight = constraints.maxHeight * 0.12;
      double portraitPopHeight = constraints.maxHeight * 0.45;

      double centerLeft = 100;
      double centerTop = 100;

      if(isLandscape){
        print("MainMenuConstraints${constraints}");
        centerLeft = isPop? (constraints.maxWidth - landscapePopWidth)  * 0.5 : (constraints.maxWidth - landscapeContractWidth) * 0.5;
        centerTop = constraints.maxHeight * 0.5;
      }
      else{
        centerLeft = constraints.maxWidth * 0.5;
        centerTop = isPop? (constraints.maxHeight - portraitPopHeight) * 0.5 : (constraints.maxHeight - portraitContractHeight) * 0.5;
      }
      final Widget selectorBox = SelectorBox(offset: Offset(centerLeft, centerTop),);

      Widget MainNodePanel = Stack(
        //clipBehavior: Clip.antiAlias,
        children: [
          if (selection.IsInDomain)
            Stack(
              //clipBehavior: Clip.antiAlias,
              children: [
                //绘制域。
                ...domainTree!.children.asMap().entries.map((nodeTreeMap){

                  Offset position = nodePositionHelper.GetNodePositionByIndex(true, nodeTreeMap.key);
                  //DomainDrawingData drawingData= nodePositionHelper.childDomainDrawingData!;
                  //Size nodeSize = nodePositionHelper.nodeSize! * scale;

                  return AnimatedPositioned(
                    key: Key(nodeTreeMap.value.hashCode.toString()),
                    left : position.dx *scale + centerLeft,
                    top :  position.dy *scale + centerTop,
                    duration: isScaling? Duration(milliseconds: 0): Duration(milliseconds: 200),
                    curve: Curves.easeOut,

                    child:Transform.translate(
                      offset: Offset( nodeViewData.viewPosX * scale,  nodeViewData.viewPosY * scale),
                      child: LevelDomain(
                        scale: scale,
                        parentConceptDrawingData: null,
                        parentDomainDrawingData: nodePositionHelper.domainDrawingData,

                        drawingData: nodePositionHelper.childDomainDrawingData!,
                        domainTree: nodeTreeMap.value!,
                        parentNodeTree: domainTree,
                      ),
                    ),


                  );

                })

                //绘制节点
                ,...domainTree!.conceptNodeTree.asMap().entries.map((nodeTreeMap){

                  Offset position = nodePositionHelper.GetNodePositionByIndex(false, nodeTreeMap.key);
                  print("Index2Position${position}");
                  NodeDrawingData drawingData= nodePositionHelper.childNodeDrawingData!;
                  Size nodeSize = nodePositionHelper.nodeSize! * scale;
                  //print("AnimatedPos!!!!!!!!!!!!!!${ position.dx * scale +nodeViewData.viewPosX * scale}");

                  return AnimatedPositioned(
                    key: Key(nodeTreeMap.value.hashCode.toString()),//不考虑性能。直接来罢！为了能成功交换节点而制作的。
                    left : position.dx * scale  + centerLeft,
                    top : position.dy * scale  + centerTop,
                    duration: isScaling? Duration(milliseconds: 0): Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Transform.translate(
                      offset: Offset( nodeViewData.viewPosX * scale,  nodeViewData.viewPosY * scale),
                      child: LevelNode(
                        scale: scale,
                        parentConceptDrawingData: null,
                        parentDomainDrawingData: nodePositionHelper.domainDrawingData,
                        drawingData: nodePositionHelper.childNodeDrawingData!,
                        nodeTree: nodeTreeMap.value!,
                        parentNodeTree: domainTree,
                      ),
                    ),
                  );
                })

              ],
            )

          else
            ...nodeTree!.children.asMap().entries.map((nodeTreeMap){

              Offset position = nodePositionHelper.GetNodePositionByIndex(false, nodeTreeMap.key);

              return AnimatedPositioned(
                key: Key(nodeTreeMap.value.hashCode.toString()),
                left : position.dx * scale + centerLeft,
                top : position.dy * scale + centerTop,
                duration: isScaling? Duration(milliseconds: 0): Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Transform.translate(
                  offset: Offset( nodeViewData.viewPosX * scale,  nodeViewData.viewPosY * scale),
                  child: LevelNode(
                    scale: scale,
                    parentConceptDrawingData: nodePositionHelper.nodeDrawingData,
                    parentDomainDrawingData: null,
                    drawingData: nodePositionHelper.childNodeDrawingData!,
                    nodeTree: nodeTreeMap.value!,
                    parentNodeTree: nodeTree,
                  ),
                ),

              );

            }),
        ],
      );
      Widget MainNodePanelWithGesture = CustomScaleGestureDetector(

        onStart: (startDetails){
          if (_isManualPop) {
            setState(() {
              _isManualPop = false;
            });
          }
          nodeViewData.SaveCurData();
          viewDataDic.repaint();


          print("onScaleStart");
        },
        onUpdate: (details){
          if(details.pointerCount == 1){
            nodeViewData.MoveScaleView(details.focalPointDelta * nodeViewData.scale,details.scale);

          }
          else if(details.pointerCount > 1){
            nodeViewData.MoveScaleView(Offset.zero,details.scale);
          }
          print("onScaleUpdate ${nodeViewData.scale} detail ${details.scale} pos ${nodeViewData.CurViewPos()} focal point ${details.focalPoint} point count ${details.pointerCount} "  );
          viewDataDic.repaint();
          if(isScaling == false){
            setState(() {
              isScaling = true;
            });
          }

        },
        onEnd: (endDetails){
          nodeViewData.UploadDataCommand(commandManager,viewDataDic);
          viewDataDic.repaint();
          setState(() {
            isScaling = false;
          });
          print("onScaleEnd");
        },

        child: Listener(
          //onPointerDown: (_){print("ONPointerDown");},//还需要额外处理双指缩放。//键鼠滚轮输入等。//需要使用自定义的手势识别器。

          onPointerPanZoomStart: (PointerPanZoomStartEvent details)//专门处理触摸板用的。
          {
            if (_isManualPop) {
              setState(() {
                _isManualPop = false;
              });
            }
            nodeViewData.SaveCurData();
            viewDataDic.repaint();
            print("**********************************************Scale Start");
          },
          onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent details)
          {
            if(details.pointer == 1){
              nodeViewData.MoveScaleView(details.panDelta * nodeViewData.scale,details.scale);

            }
            else if(details.pointer > 1){
              nodeViewData.MoveScaleView(Offset.zero,details.scale);

            }
            //nodeGroupModel.MoveScale();
            print("scale ${nodeViewData.scale} detail ${details.scale} pos ${nodeViewData.CurViewPos()} focal point ${details.pan} point count ${details.pointer} "  );
            viewDataDic.repaint();
          },
          onPointerPanZoomEnd: (details)
          {
            nodeViewData.UploadDataCommand(commandManager,viewDataDic);
            viewDataDic.repaint();
          },

          child: MainNodePanel,
        ),
      );
      Widget PopingEditPanel = PopInspector(
        isPop: isPop,
        landscapePopWidth: landscapePopWidth,
        portraitPopHeight: portraitPopHeight,
        portraitContractHeight: portraitContractHeight,
        landscapeContractWidth: landscapeContractWidth,
        landscapeHeight:constraints.maxHeight,
        portraitWidth: constraints.maxWidth,
        onExpandRequest: () {
          if (!_isManualPop) {
            setState(() {
              _isManualPop = true;
            });
          }
        },
        onCollapseRequest: () {
          if (globalStateModel.State != GlobalState.normal) {
            globalStateModel.State = GlobalState.normal;
            selection.CancelSelection();
          }
          setState(() {
            _isManualPop = false;
          });
        },
        child: editorPanel,
      );

      return Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent && HardwareKeyboard.instance.isControlPressed) {
            final viewDataDic = context.read<ConceptTree2NodeViewDataDic>();
            final commandManager = context.read<CommandManagerForProvider>();

            if (!_isScrollingWheel) {
              _isScrollingWheel = true;
              nodeViewData.SaveCurData();
            }

            setState(() {
              isScaling = true;
              double oldScale = nodeViewData.scale;
              double zoomFactor = pointerSignal.scrollDelta.dy < 0 ? 1.1 : 0.9;
              double newScale = oldScale * zoomFactor;

              final Offset mousePos = pointerSignal.localPosition;
              final Offset focalPoint = Offset(mousePos.dx - centerLeft, mousePos.dy - centerTop);

              nodeViewData.viewPosX += focalPoint.dx * (1/newScale - 1/oldScale);
              nodeViewData.viewPosY += focalPoint.dy * (1/newScale - 1/oldScale);
              nodeViewData.scale = newScale;
              
              viewDataDic.repaint();
            });

            _scrollWheelTimer?.cancel();
            _scrollWheelTimer = Timer(const Duration(milliseconds: 500), () {
              if (mounted) {
                nodeViewData.UploadDataCommand(commandManager, viewDataDic);
                setState(() {
                  _isScrollingWheel = false;
                  isScaling = false;
                });
              }
            });
          }
        },
        child: Stack(
          children: [
            bgContainer,
            AddressBar(maxWidth: constraints.maxWidth,),

            MainNodePanelWithGesture,
            //绘制选择框光标。
            if(selection.IsSelecting)
              selectorBox,
            if(editingStateModel.State == EditingState.waitingMovingTarget || editingStateModel.State == EditingState.selectingMovingNode)
              hintPanel,
            
            nodeStatusHintPanel, // 概念节点状态提示

            PopingEditPanel,

          ],
        ),
      );
    });
  }
}
