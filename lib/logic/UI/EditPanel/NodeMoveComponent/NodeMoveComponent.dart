//修改节点位置就是，修改drawingData里面的pos[]/domainPos[]排序，
// 以及对应树的children/DomainChildren排序。

//交换模式。将正在移动的节点，与节点位置原本的节点进行节点的位置交换。
//挤兑模式。整体大小不变的情况下， 节点完成移动的同时，后方的节点依次向空位移动。

//动画效果。当节点的Pos改变时，能否使用AnimatedPosition来省事移动呢？？？？！！！
//把拖拽控制的数值放在外部，当发生拖拽时，不执行AnimatedPosition的动画效果。


//外形设计。{模式}{模式}（激活摇杆）
import 'package:concept_navigator/MTools/MMath.dart';
import 'package:concept_navigator/logic/CommandMode/ProjCommand.dart';
import 'package:concept_navigator/logic/Data/ConceptTree.dart';
import 'package:concept_navigator/logic/Data/ConceptTreeToDrawingData.dart';
import 'package:concept_navigator/logic/Data/GlobalState.dart';
import 'package:concept_navigator/logic/Data/LevelNodeGroupModel.dart';
import 'package:concept_navigator/logic/Data/NodeSwapModel.dart';
import 'package:concept_navigator/logic/Data/SelectionViewData.dart';
import 'package:concept_navigator/logic/Data/StatefulComponentManagerModel.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeMoveComponent/NodeMoveJoystick/MJoystick.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeMoveComponent/NodeMoveJoystick/MJoystickBase.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeMoveComponent/NodeMoveJoystick/MJoystickEnum.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeMoveComponent/NodeMoveJoystick/MJoystickListener.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/DoubleActionButton.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/ScroallablePositionedList/ScrollablePositionedListItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:provider/provider.dart';

class ConceptMoveComponent extends StatefulWidget {
  const ConceptMoveComponent({super.key,});
  //final bool needInit;

  @override
  State<ConceptMoveComponent> createState() => _ConceptMoveComponentState();
}

class _ConceptMoveComponentState extends State<ConceptMoveComponent> {

  //直接用数值代替状态枚举，没必要弄枚举折磨自己。
  //0 默认，1展开，。。。。。。
  double state = 0;
  //1 交换模式，2挤兑模式。
  double mode = 0;
  //0 默认    左，交换状态，右，挤兑状态。
  //1 编辑（展开）状态
  //1.2 挤兑模式： 左确定，右，取消
  //1.3 交换模式： 左取消，右，确定
  //编辑状态下，聚焦节点，创建节点的FAB收缩。
  StlessScrollablePositionedListItem? inheritedItem;
  MJoystickListenerHelper? listenerHelper;
  bool leftEnter = false,rightEnter = false,topEnter = false,bottomEnter = false,centerEnter = true;
  final double DeadZone = 0.45;

  late CommandManagerForProvider commandManagerProvider;
  late CommandManager commandManager;

  late SelectionViewData selection;
  //late ConceptTreeModel treeModel;
  //ConceptNodeTree? nodeTree;
  //DomainTree? domainTree;
  //NodeDrawingData? nodeDrawingData;
  //DomainDrawingData? domainDrawingData;

  late NodeSwapModel swapModel;
  late EditingStateModel stateModel;
  late StatefulComponentManagerModelForProvider statefulComponentManagerModelForProvider;



  void _focusToCenter(BuildContext context){
    inheritedItem ??= context.dependOnInheritedWidgetOfExactType<StlessScrollablePositionedListItem>();

    if(inheritedItem == null){
      throw Exception("NodeMoveComponent找不到StlessScrollablePositionedListItem");
    }
    inheritedItem!.controller.scrollTo(index: inheritedItem!.index,alignment: 0.1, duration: Duration(milliseconds: 150));
  }
  void _announceScroll(bool stop){
    inheritedItem ??= context.dependOnInheritedWidgetOfExactType<StlessScrollablePositionedListItem>();
    if(inheritedItem == null){
      throw Exception("NodeMoveComponent找不到StlessScrollablePositionedListItem");
    }
    if(inheritedItem!.needStopScroll == null){
      return;
    }
    inheritedItem!.needStopScroll!(stop);
    //设置一下state（没什么卵用）
    if(stop){
      statefulComponentManagerModelForProvider.setComponentState(statefulComponentManagerModelForProvider.editingConceptPanel, inheritedItem!.index, 2);
    }
    else{
      statefulComponentManagerModelForProvider.setComponentState(statefulComponentManagerModelForProvider.editingConceptPanel, inheritedItem!.index, 0);
    }

  }
  void _onDirectionFirstEnter(EJoystickDirection direction){
    print("directionFirstEnter!");
    switch(direction){
      case EJoystickDirection.left:
        setState(() {
          leftEnter = true;
          centerEnter = false;
          //leftEnter = false;
          rightEnter = false;
          topEnter = false;
          bottomEnter = false;
        });
        break;
      case EJoystickDirection.right:
        setState(() {
          rightEnter = true;
          centerEnter = false;
          leftEnter = false;
          //rightEnter = false;
          topEnter = false;
          bottomEnter = false;
        });
        break;
      case EJoystickDirection.top:
        setState(() {
          topEnter = true;
          centerEnter = false;
          leftEnter = false;
          rightEnter = false;
          //topEnter = false;
          bottomEnter = false;
        });
        //break;
      case EJoystickDirection.bottom:
        setState(() {
          bottomEnter = true;
          centerEnter = false;
          leftEnter = false;
          rightEnter = false;
          topEnter = false;
          //bottomEnter = false;
        });
        break;
      default:
        setState((){
          centerEnter = true;
          leftEnter = false;
          rightEnter = false;
          topEnter = false;
          bottomEnter = false;
        });
        break;//dart里面默认会break Switch case。爱写不写。
    }
    if(direction == EJoystickDirection.center){
      return;
    }
    if(selection.IsSelectedDomain){
      // if(mode == 1){
      //   moveSwapDomain(direction);
      // }
      // else
        if(mode == 2){
        moveSqueezeDomain(direction);
      }
    }
    else if(selection.IsSelectedConceptNode){
      // if(mode == 1){
      //   moveSwapConcept(direction);
      // }
      // else
        if(mode == 2){
        moveSqueezeConcept(direction);
      }
    }

  }
  void _onDirectionRepeat(EJoystickDirection direction){
    _onDirectionFirstEnter(direction);
    print("Repeat!!!!!${direction}");
  }

  void initMoveData(){
    commandManager.init();
    swapModel.initMoveData(selection);
  }
  void confirmMoveData(){
    //TODO:对节点完成编辑后，重新构建节点树。非常重要。
  }
/*
  void moveSwapDomain(EJoystickDirection direction){
    switch(direction){
      case EJoystickDirection.left:
        break;
      case EJoystickDirection.right:
        break;
      case EJoystickDirection.top:
        break;

      case EJoystickDirection.bottom:
        break;

      default:
        break;
    }
  }

  void moveSwapConcept(EJoystickDirection direction){
    switch(direction){
      case EJoystickDirection.left:
        break;
      case EJoystickDirection.right:



        break;
      case EJoystickDirection.top:
        break;

      case EJoystickDirection.bottom:
        break;

      default:
        break;
    }
  }

 */
  void moveSqueezeDomain(EJoystickDirection direction){
    switch(direction){
      case EJoystickDirection.left:
        break;
      case EJoystickDirection.right:
        break;
      case EJoystickDirection.top:
        break;

      case EJoystickDirection.bottom:
        break;

      default:
        break;
    }
  }
  void moveSqueezeConcept(EJoystickDirection direction){
    //将当前位置与目标位置进行交换。
    swapModel.reCalculateCurIndex(selection);
    //int originIndex = swapModel.originIndex;
    int curIndex = swapModel.curIndex;
    int newIndex = curIndex;
    newIndex = newIndex + swapModel.getDeltaIndex(selection, direction);

    if(newIndex > swapModel.allLength - 1 || newIndex < 0){
      //TODO:做一个节点向特定方向移动但被卡住的效果。但是会很耗。
      print("在最边缘怎么移动？${newIndex}");
      return;
    }
    swapModel.nodeSwap(curIndex, newIndex, true,false);
    swapModel.rebuildNodeTreeDic();
    print("移动节点，序号curIndex${curIndex},newIndex${newIndex}");
    commandManagerProvider.PushCommand(commandManager,Command(function: (){
      swapModel.nodeSwap(curIndex, newIndex, true,false);
      swapModel.rebuildNodeTreeDic();
    },undoFunction: (){
      swapModel.nodeSwap(curIndex, newIndex,true, false);
      swapModel.rebuildNodeTreeDic();
    }));
  }

  @override
  void initState() {
    listenerHelper = MJoystickListenerHelper(
      //repeatDelay: Duration(milliseconds: 500),
      onDirectionFirstEnter: _onDirectionFirstEnter,
      deadZone: DeadZone,
      onDirectionRepeat: _onDirectionRepeat,
    );
    //获取移动所必须的数据。
    selection = context.read<SelectionViewData>();

    commandManagerProvider = context.read<CommandManagerForProvider>();
    commandManager = commandManagerProvider.moveNodeInstance;

    swapModel = context.read<NodeSwapModel>();
    print("initStateNodeMoveComponent");
    stateModel = context.read<EditingStateModel>();

    statefulComponentManagerModelForProvider = context.read<StatefulComponentManagerModelForProvider>();

    super.initState();
  }
  @override
  void dispose() {
    print("disposeNodeMoveComponent");
    listenerHelper?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // if(stateModel.State == EditingState.waitingMovingTarget || stateModel.State == EditingState.selectingMovingNode){
    //   if(state == 0){
    //     state = 1;
    //     mode = 1;
    //     _announceScroll(true);
    //     _focusToCenter(context);
    //   }
    // }
    // 为了方便演示，先硬编码 size，你可以根据需要提取为常量
    final double joystickSize = 190;          // 摇杆完全展开时的尺寸
    final double buttonBigWidth = 250;        // 双按钮形态0时的宽度
    final double buttonBigHeight = 56;        // 双按钮形态0时的高度
    final double buttonSmallWidth = 150;      // 双按钮形态1时的宽度
    final double buttonSmallHeight = 56;      // 双按钮形态1时的高度


    // 形态1时双按钮靠右偏移，在左边按钮的右20像素。
    final double rightX = joystickSize +10;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: double.infinity,
      height: state == 1 ?(mode == 2? joystickSize:2*buttonBigHeight):buttonBigHeight,

      child: Stack(
        children: [
          AnimatedPositioned(
            left: state == 1 && mode == 2 ? 0 : -joystickSize, // 移出屏幕左侧
            top: state == 0 ? 0:0,
            //width: state == 1 ? joystickSize : 0,
            //height: state == 1 ? joystickSize : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Joystick(
              //key: _joystickKey,

              listener: listenerHelper!.listener,
              period: Duration(milliseconds: 50),
              // base: JoystickSquareBase(
              //   mode: JoystickMode.horizontalAndVertical,
              //   size: 100*value + 100,
              //   decoration: JoystickBaseDecoration(
              //     drawOuterCircle: false,
              //     drawArrows: false,
              //   ),
              // ),
              base: MJoystickSquireBase.all(
                animationDuration: Duration(milliseconds: 100),
                size: joystickSize,
                trapezoidHeightInput: joystickSize * (1 - DeadZone) * 0.5,
                highlighted: {
                  EJoystickDirection.left:leftEnter,
                  EJoystickDirection.right:rightEnter,
                  EJoystickDirection.top:topEnter,
                  EJoystickDirection.bottom:bottomEnter,
                  EJoystickDirection.center:centerEnter,
                },
                centerBaseColor: Theme.of(context).colorScheme.surfaceContainer,
                centerHighlightColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                highlightColor: Theme.of(context).colorScheme.tertiary,
                borderColor: Theme.of(context).colorScheme.outline,
                borderWidth: 2,
                borderRadius: BorderRadius.circular(20),
                outerBorderColor: Theme.of(context).colorScheme.outline,
                outerBorderWidth: 4,

              ),
              mode: JoystickMode.all,
              stick: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(128),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
              includeInitialAnimation: false,
            ),
          ),
          AnimatedPositioned(
            left: state == 1 && mode == 2 ? rightX : 0,
            top: state == 1 && mode == 2 ? 20 : 0,
            bottom: state == 1 && mode == 2 ? null:0,
            right: state == 1 && mode == 2 ? null: 0,


            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,

            child: Align(
              alignment: AlignmentGeometry.topCenter,
              child: DoubleActionButton(
                width: state == 1 && mode == 2 ?  buttonSmallWidth : buttonBigWidth,
                height: state == 1 && mode == 2 ? buttonSmallHeight : buttonBigHeight,
                onLeftPressed:mode == 1? null: (){
                  //print("PressLeft");
                  if(selection.IsSelecting){
                    stateModel.State = EditingState.waitingMovingTarget;
                  }
                  else{
                    stateModel.State = EditingState.selectingMovingNode;
                  }
                  initMoveData();
                  if(state == 0){
                    //进入交换移动模式。
                    _announceScroll(true);
                    WidgetsBinding.instance.addPostFrameCallback((_){
                      Future.delayed(Duration.zero,(){
                        _focusToCenter(context);
                      });
                    });
                    _focusToCenter(context);
                    setState(() {
                      state = 1;
                      mode = 1;
                    });
                  }
                  else{
                    setState(() {
                      mode = 1;
                    });
                  }
                },
                onRightPressed:mode == 2?null: (){
                  stateModel.State = EditingState.squeezingNode;
                  initMoveData();
                  if(state == 0){
                    //进入挤兑移动模式。
                    _announceScroll(true);

                    WidgetsBinding.instance.addPostFrameCallback((_){
                      Future.delayed(Duration.zero,(){
                        _focusToCenter(context);
                      });
                    });
                    setState(() {
                      state = 1;
                      mode = 2;
                    });
                  }
                  else{
                    setState(() {
                      mode = 2;
                    });
                  }
                },
                borderWidth: 2,
                lChild: SizedBox.expand(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),

                    alignment: AlignmentGeometry.center,
                    color: mode == 1? Theme.of(context).colorScheme.tertiary: Colors.transparent,
                    child: Text("交换模式",style: TextStyle(color: mode == 1?Theme.of(context).colorScheme.onTertiary:null),),

                  ),
                ),
                rChild: SizedBox.expand(
                  child: AnimatedContainer(
                    //color: Colors.greenAccent,
                    duration: Duration(milliseconds: 200),
                    alignment: AlignmentGeometry.center,
                    decoration: BoxDecoration(
                      color: mode == 2? Theme.of(context).colorScheme.tertiary: Colors.transparent,

                    ),

                    child: Text("挤兑模式",style: TextStyle(color: mode == 2?Theme.of(context).colorScheme.onTertiary:null),),
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            left: state == 1 && mode == 2 ? rightX : 0,
            top: state == 0 ? 0 :(mode == 2? 22+buttonSmallHeight : buttonBigHeight),
            bottom: state == 1 && mode == 2 ? null:0,
            right: state == 1 && mode == 2 ? null: 0,


            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,

            child: Align(
              alignment: AlignmentGeometry.topCenter,
              child: DoubleActionButton(
                width: state == 1 ? (mode == 2? buttonSmallWidth : buttonBigWidth) : 0,
                height: state == 1  ?(mode == 2 ?buttonSmallHeight : buttonBigHeight)  : 0,
                onLeftPressed: (){
                  //print("PressLeft");确定按钮
                  if(state == 0){
                    return;
                  }
                  stateModel.State = EditingState.none;
                  _announceScroll(false);
                  setState(() {
                    state = 0;
                    mode = 0;
                  });

                },
                onRightPressed: (){
                  if(state == 0){
                    return;
                  }
                  // 取消编辑。
                  commandManager.undoAll();
                  stateModel.State = EditingState.none;
                  _announceScroll(false);
                  setState(() {
                    state = 0;
                    mode = 0;
                  });
                },
                borderWidth: 2,
                lChild: SizedBox.expand(
                  child: Container(
                    alignment: AlignmentGeometry.center,
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Text("确定"),
                  ),
                ),
                rChild: SizedBox.expand(
                  child: Container(
                    //color: Colors.greenAccent,
                    alignment: AlignmentGeometry.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,

                    ),
                    child: Text("取消"),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }
}
