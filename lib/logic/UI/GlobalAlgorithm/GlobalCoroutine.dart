import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/scheduler/ticker.dart';

class CustomTickerProvider implements TickerProvider{
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }

}
class GlobalCoroutine{
  static GlobalCoroutine? _instance;
  GlobalCoroutine._private():controller = AnimationController( vsync: CustomTickerProvider());
  factory GlobalCoroutine(){
    _instance ??= GlobalCoroutine._private();
    return _instance!;
  }
  AnimationController controller;



}
