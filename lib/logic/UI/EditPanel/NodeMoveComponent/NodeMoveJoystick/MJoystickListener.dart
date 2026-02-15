import 'package:concept_navigator/logic/UI/EditPanel/NodeMoveComponent/NodeMoveJoystick/MJoystickEnum.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_joystick/flutter_joystick.dart';
//by deepseek
class DirectionalJoystick extends StatefulWidget {
  /// 首次进入方向时的回调
  final Function(String direction) onDirectionFirstEnter;

  /// 重复触发方向时的回调
  final Function(String direction) onDirectionRepeat;

  /// 长按开始重复前的延迟
  final Duration repeatDelay;

  /// 重复触发的间隔
  final Duration repeatInterval;

  const DirectionalJoystick({
    Key? key,
    required this.onDirectionFirstEnter,
    required this.onDirectionRepeat,
    this.repeatDelay = const Duration(milliseconds: 500),
    this.repeatInterval = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<DirectionalJoystick> createState() => _DirectionalJoystickState();
}

class _DirectionalJoystickState extends State<DirectionalJoystick> {
  String? _currentDirection;
  Timer? _repeatTimer;
  bool _repeatActive = false;

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  String? _getDirection(double x, double y) {
    const double deadZone = 0.2;
    if (x.abs() < deadZone && y.abs() < deadZone) return null;

    if (x.abs() > y.abs()) {
      return x > 0 ? 'right' : 'left';
    } else {
      // 根据实际坐标系调整符号：常见摇杆向上推时 y 为负
      return y < 0 ? 'up' : 'down';
    }
  }

  void _handleStickUpdate(StickDragDetails details) {
    final newDirection = _getDirection(details.x, details.y);

    // 方向变化时
    if (newDirection != _currentDirection) {
      _repeatTimer?.cancel();
      _repeatActive = false;
      _currentDirection = newDirection;

      if (_currentDirection != null) {
        // 首次进入，立即触发回调
        widget.onDirectionFirstEnter(_currentDirection!);

        // 延迟后开始重复触发
        _repeatTimer = Timer(widget.repeatDelay, () {
          _repeatActive = true;
          _startRepeating();
        });
      }
    }
    // 如果方向未变且已经处于重复阶段，周期定时器会自动处理，无需额外操作
  }

  void _startRepeating() {
    // 确保当前方向有效且重复标志为 true
    if (_currentDirection == null || !_repeatActive) return;

    // 立即触发一次重复（延迟后的首次）
    widget.onDirectionRepeat(_currentDirection!);

    // 启动周期定时器
    _repeatTimer = Timer.periodic(widget.repeatInterval, (timer) {
      if (_currentDirection == null || !_repeatActive) {
        timer.cancel();
        return;
      }
      widget.onDirectionRepeat(_currentDirection!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}

class MJoystickListenerHelper{
  late StickDragCallback listener;
  /// 首次进入方向时的回调
  final Function(EJoystickDirection direction) onDirectionFirstEnter;
  /// 重复触发方向时的回调
  final Function(EJoystickDirection direction)? onDirectionRepeat;
  /// 长按开始重复前的延迟
  final Duration repeatDelay;
  /// 重复触发的间隔
  final Duration repeatInterval;
  final double deadZone;
  MJoystickListenerHelper({
    required this.onDirectionFirstEnter,
    this.onDirectionRepeat,
    this.repeatDelay = const Duration(milliseconds: 500),
    this.repeatInterval = const Duration(milliseconds: 200),
    this.deadZone = 0.2,
  }){
    listener = Callback;
  }

  EJoystickDirection? _currentDirection;
  Timer? _repeatTimer;
  bool _repeatActive = false;

  void dispose() {
    _repeatTimer?.cancel();
  }

  EJoystickDirection? _getDirection(double x, double y) {
    if (x.abs() < deadZone && y.abs() < deadZone) return null;

    if (x.abs() > y.abs()) {
      return x > 0 ? EJoystickDirection.right : EJoystickDirection.left;
    } else {
      // 根据实际坐标系调整符号：常见摇杆向上推时 y 为负
      return y < 0 ? EJoystickDirection.top : EJoystickDirection.bottom;
    }
  }
  void Callback(StickDragDetails details){
    final newDirection = _getDirection(details.x, details.y);
    print("stickPosX::${details.x}Y::${details.y},dir${newDirection}");
    // 方向变化时
    if (newDirection != _currentDirection) {
      _repeatTimer?.cancel();
      _repeatActive = false;
      _currentDirection = newDirection;

      if (_currentDirection != null) {
        // 首次进入，立即触发回调
        onDirectionFirstEnter(_currentDirection!);
        print("enterDir${_currentDirection}");

        // 延迟后开始重复触发
        _repeatTimer = Timer(repeatDelay, () {
          _repeatActive = true;
          _startRepeating();
        });
      }
      else{
        onDirectionFirstEnter(EJoystickDirection.center);
      }
    }
    // 如果方向未变且已经处于重复阶段，周期定时器会自动处理，无需额外操作

  }
  // 如果方向未变且已经处于重复阶段，周期定时器会自动处理，无需额外操作
  void _startRepeating() {
    // 确保当前方向有效且重复标志为 true
    if (onDirectionRepeat == null || _currentDirection == null || !_repeatActive) return;

    // 立即触发一次重复（延迟后的首次）
    onDirectionRepeat!(_currentDirection!);

    // 启动周期定时器
    _repeatTimer = Timer.periodic(repeatInterval, (timer) {
      if (_currentDirection == null || !_repeatActive) {
        timer.cancel();
        return;
      }
      onDirectionRepeat!(_currentDirection!);
    });
  }


}

