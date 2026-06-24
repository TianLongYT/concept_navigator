import 'package:concept_navigator/logic/UI/GlobalAlgorithm/CustomGapBorderContainer/CustomGapBorderContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

//暂定几个状态，主要是为了好看
//inViewState. focusState.
class StatefulComponent extends StatefulWidget {
  const StatefulComponent({
    super.key,
    required this.child,
    this.paddingOutSide = const EdgeInsetsGeometry.all(10),
    this.paddingInside = const EdgeInsetsGeometry.all(10),
    this.componentTitle ="test",
    this.componentHint = "test2",
    this.componentState = "test3",
    this.borderColor,

  });
  final Widget child;
  final EdgeInsetsGeometry paddingOutSide;
  final EdgeInsetsGeometry paddingInside;
  final String? componentTitle;
  final String? componentHint;
  final String? componentState;
  final Color? borderColor;

  @override
  State<StatefulComponent> createState() => _StatefulComponentState();
}

class _StatefulComponentState extends State<StatefulComponent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Color defaultBorderColor;
  late Color darkenBorderColor;
  late Color brightenBroderColor;
  late Color curBorderColor;
  @override
  void initState() {
    _controller = AnimationController(vsync: this,duration: Duration(milliseconds: 200),);
    //_controller.repeat();
    //_controller.addListener((){print("controllerRunning${_controller.value}");});
    super.initState();
    _controller.forward(from: 0);
    //curBorderColor = ColorTween(begin: )

  }
  void changeBorderColor(){
    curBorderColor = ColorTween(begin: defaultBorderColor,end: brightenBroderColor).animate(_controller).value!;
  }

  @override
  Widget build(BuildContext context) {
    defaultBorderColor = widget.borderColor == null? Theme.of(context).colorScheme.outline:widget.borderColor!;
    darkenBorderColor = ColorUtils.darken(defaultBorderColor,0.2);
    brightenBroderColor = ColorUtils.lighten(defaultBorderColor,0.2);

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Padding(
          padding: widget.paddingOutSide,
          child: Column(
            children: [
              SizedBox(
                height: 20,
                child: ElevatedButton(onPressed: (){_controller.reverse(from: 1);}, child: null,),
              ),
              GapBorderContainer(
                decoration: GapBorderDecoration(
                  label: widget.componentTitle,
                  labelStyle: TextStyle(
                    fontSize: (14.0+2.0*_controller.value),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  borderSide: BorderSide(
                    width: 2,
                    color: ColorTween(begin: brightenBroderColor,end: darkenBorderColor).animate(_controller).value!

                  )
                ),
                //ignoreBorderWidth: false,
                contentPadding: widget.paddingInside,

                child: child,
              ),
            ],
          ),
        );

      },
      child:widget.child,
    );
  }
}
enum EStatefulComponentState{
  normal,//通常状态 ,请用数值代替，好算 -1
  visualCenter,//视觉中心， 用数值代替 0
  focus,//组件被启用。被激活状态。 用数值代替 1
}
class AnimatedStatefulComponent extends StatelessWidget{

  const AnimatedStatefulComponent({
    super.key,
    required this.state,
    this.curve = Curves.linear,
    required this.duration,
    required this.child,
    this.paddingOutSide = const EdgeInsetsGeometry.all(10),
    this.paddingInside = const EdgeInsetsGeometry.all(16),
    this.componentTitle ="test",
    this.componentHint = "test2",
    this.componentState = "test3",

    this.darkenBorderColor,
    this.defaultBorderColor,
    this.lightenBorderColor,


  });
  final double state;
  final Curve curve;
  final Duration duration;
  final Widget child;
  final EdgeInsetsGeometry paddingOutSide;
  final EdgeInsetsGeometry paddingInside;
  final String? componentTitle;
  final String? componentHint;
  final String? componentState;

  final Color? darkenBorderColor;
  final Color? defaultBorderColor;
  final Color? lightenBorderColor;

  @override
  Widget build(BuildContext context) {

    Color defaultBorderColor =  this.defaultBorderColor == null? Theme.of(context).colorScheme.outline : this.defaultBorderColor!;
    Color darkenBorderColor = this.darkenBorderColor == null? ColorUtils.darken(defaultBorderColor,0.2) : this.darkenBorderColor!;
    Color lightenBorderColor = this.lightenBorderColor == null? ColorUtils.lighten(defaultBorderColor,0.2) : this.lightenBorderColor!;

    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    return TweenAnimationBuilder(
      tween: Tween(end: state),
      curve: curve,
      duration: duration,
      builder:(context,value,child){
        print("customAnimationRebuild${value}");
// 根据主题亮度决定：正值应变深还是变浅
        Color borderColor;
        if (isLight) {
          // 浅色主题：正值变深（明显），负值变浅（不明显）
          borderColor = value > 0
              ? Color.lerp(defaultBorderColor, darkenBorderColor, value)!
              : Color.lerp(defaultBorderColor, lightenBorderColor, -value)!;
        } else {
          // 深色主题：正值变浅/亮（明显），负值变深/暗（不明显）
          borderColor = value > 0
              ? Color.lerp(defaultBorderColor, lightenBorderColor, value)!
              : Color.lerp(defaultBorderColor, darkenBorderColor, -value)!;
        }
        return Padding(
          padding: paddingOutSide,
          child: Column(
            children: [
              SizedBox(
                height: 20,
                //child: ElevatedButton(onPressed: (){}, child: null,),
              ),
              GapBorderContainer(
                decoration: GapBorderDecoration(
                    label: componentTitle,
                    labelStyle: TextStyle(
                      fontSize: (14.0+2.0*value),
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    borderSide: BorderSide(
                        width: 2,
                        color: borderColor,//value<0?Color.lerp(defaultBorderColor, darkenBorderColor, -value)!:Color.lerp(defaultBorderColor, lightenBorderColor, value)!,

                    )
                ),
                //ignoreBorderWidth: false,
                contentPadding: paddingInside,

                child: child,
              ),
            ],
          ),
        );
      },
      child: child,

    );
  }


}