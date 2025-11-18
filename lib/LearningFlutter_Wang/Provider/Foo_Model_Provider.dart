import 'package:concept_navigator/LearningFlutter_Wang/Provider/Foo_Model.dart';
import 'package:flutter/material.dart';

class FooModelProvider extends InheritedWidget{
  FooModel model;

  FooModelProvider({super.key, required this.model,required super.child});

  static FooModelProvider of(BuildContext context){
    return context.dependOnInheritedWidgetOfExactType<FooModelProvider>()!;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    // TODO: implement updateShouldNotify
    return true;
  }

}