//修改节点位置就是，修改drawingData里面的pos[]/domainPos[]排序，
// 以及对应树的children/DomainChildren排序。

//交换模式。将正在移动的节点，与节点位置原本的节点进行节点的位置交换。
//挤兑模式。整体大小不变的情况下， 节点完成移动的同时，后方的节点依次向空位移动。

//动画效果。当节点的Pos改变时，能否使用AnimatedPosition来省事移动呢？？？？！！！
//把拖拽控制的数值放在外部，当发生拖拽时，不执行AnimatedPosition的动画效果。


//外形设计。{模式}{模式}（激活摇杆）
import 'package:concept_navigator/logic/UI/EditPanel/NodeMoveComponent/NodeMoveJoystick/MJoystick.dart';
import 'package:concept_navigator/logic/UI/GlobalAlgorithm/DoubleActionButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

class ConceptMoveComponent extends StatelessWidget {
  ConceptMoveComponent({super.key});
  final GlobalKey _joystickKey = GlobalKey();

  // 3. 按钮按下时，将 Joystick 滚动到 ListView 正中央
  void _focusJoystickToCenter() async {
    // 确保 Widget 已经布局完成
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = _joystickKey.currentContext;
      if (context == null) return;

      await Scrollable.ensureVisible(
        context,
        alignment: 0.5,          // ✅ 精确：目标中心与视口中心对齐
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Joystick(
          key: _joystickKey,

          listener: (drageDetail){

          },
          base: JoystickSquareBase(
            mode: JoystickMode.horizontalAndVertical,
            size: 200,
            decoration: JoystickBaseDecoration(
              drawOuterCircle: false,
              drawArrows: false,
            ),
          ),
          mode: JoystickMode.horizontalAndVertical,
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

        DoubleActionButton(
          onLeftPressed: (){
            print("PressLeft");
            _focusJoystickToCenter();
            },
          lChild: Container(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Text("交换模式"),
          ),
        ),
      ],
    );

  }
}
