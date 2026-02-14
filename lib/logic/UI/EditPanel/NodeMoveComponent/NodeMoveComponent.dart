//修改节点位置就是，修改drawingData里面的pos[]/domainPos[]排序，
// 以及对应树的children/DomainChildren排序。

//交换模式。将正在移动的节点，与节点位置原本的节点进行节点的位置交换。
//挤兑模式。整体大小不变的情况下， 节点完成移动的同时，后方的节点依次向空位移动。

//动画效果。当节点的Pos改变时，能否使用AnimatedPosition来省事移动呢？？？？！！！
//把拖拽控制的数值放在外部，当发生拖拽时，不执行AnimatedPosition的动画效果。


//外形设计。{模式}{模式}（激活摇杆）
import 'package:concept_navigator/logic/UI/EditPanel/NodeMoveComponent/NodeMoveJoystick/MJoystick.dart';
import 'package:concept_navigator/logic/UI/EditPanel/NodeMoveComponent/NodeMoveJoystick/MJoystickBase.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/DoubleActionButton.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/ScroallablePositionedList/ScrollablePositionedListItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

class ConceptMoveComponent extends StatefulWidget {
  ConceptMoveComponent({super.key});

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

  }


  @override
  Widget build(BuildContext context) {
    //state = 0;
    // 为了方便演示，先硬编码 size，你可以根据需要提取为常量
    final double joystickSize = 190;          // 摇杆完全展开时的尺寸
    final double buttonBigWidth = 250;        // 双按钮形态0时的宽度
    final double buttonBigHeight = 56;        // 双按钮形态0时的高度
    final double buttonSmallWidth = 150;      // 双按钮形态1时的宽度
    final double buttonSmallHeight = 56;      // 双按钮形态1时的高度
    //TODO:删掉他们，就两个widget，直接从左算到右就行。
    // 获取屏幕/父容器尺寸（假设Stack填满父布局）
    // final Size screenSize = MediaQuery.of(context).size;
    // final double centerX = screenSize.width / 2;
    // final double centerY = screenSize.height / 5;

    // 形态1时双按钮靠右偏移，在左边按钮的右20像素。
    final double rightX = joystickSize +10;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: state == 1?joystickSize:buttonBigHeight,
      child: Stack(
        children: [
          AnimatedPositioned(
            left: state == 1 ? 0 : -joystickSize, // 移出屏幕左侧
            top: state == 0 ? 0:0,
            //width: state == 1 ? joystickSize : 0,
            //height: state == 1 ? joystickSize : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Joystick(
              //key: _joystickKey,

              listener: (drageDetail){

              },
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
                trapezoidHeightInput: 45,
                highlighted: {
                  Direction.left:true,
                  Direction.right:false,
                  Direction.top:false,
                  Direction.bottom:false,
                  Direction.center:false,
                },
                centerBaseColor: Theme.of(context).colorScheme.surfaceContainer,
                centerHighlightColor: Theme.of(context).colorScheme.surfaceContainer,
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
            left: state == 0 ? 0 : rightX,
            top: state == 0 ? 0 : 20,
            bottom: state == 0? 0:null,
            right: state == 0? 0: null,


            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,

            child: Align(
              alignment: AlignmentGeometry.topCenter,
              child: DoubleActionButton(
                width: state == 0 ? buttonBigWidth : buttonSmallWidth,
                height: state == 0 ? buttonBigHeight : buttonSmallHeight,
                onLeftPressed:mode == 1? null: (){
                  //print("PressLeft");
                  if(state == 0){
                    //进入交换移动模式。
                    _focusToCenter(context);
                    _announceScroll(true);
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
                  if(state == 0){
                    //进入挤兑移动模式。
                    _focusToCenter(context);
                    _announceScroll(true);
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
            left: state == 0 ? 0 : rightX,
            top: state == 0 ? 0 : 22+buttonSmallHeight,
            bottom: state == 0? 0:null,
            right: state == 0? 0: null,


            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,

            child: Align(
              alignment: AlignmentGeometry.topCenter,
              child: DoubleActionButton(
                width: state == 0 ? 0 : buttonSmallWidth,
                height: state == 0 ? 0 : buttonSmallHeight,
                onLeftPressed: (){
                  //print("PressLeft");确定按钮
                  if(state == 0){
                    return;
                  }
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
